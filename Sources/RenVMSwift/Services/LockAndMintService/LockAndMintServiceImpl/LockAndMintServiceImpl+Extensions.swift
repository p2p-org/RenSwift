import Foundation
import LoggerSwift

extension LockAndMintServiceImpl {
    // update current processing transactions
    func updateProcessingTransactions() async {
        processingTxsSubject.send(await persistentStore.processingTransactions)
    }
    
    /// Resume the current session
    func _resume() async {
        // loading
        stateSubject.send(.loading)
        
        do {
            // get account
            let account = try await destinationChainProvider.getAccount()
            
            // load chain
            chain = try await destinationChainProvider.load()
            
            // load lock and mint
            lockAndMint = try LockAndMint(
                rpcClient: rpcClient,
                chain: chain!,
                mintTokenSymbol: mintToken.symbol,
                version: version,
                destinationAddress: account.publicKey,
                session: await persistentStore.session
            )
            
            // get response and estimated fee
            let (gatewayAddressResponse, estimatedFee) = await(
                try lockAndMint!.generateGatewayAddress(),
                try rpcClient.estimateTransactionFee(log: showLog)
            )
            
            let address = try chain!.dataToAddress(data: gatewayAddressResponse.gatewayAddress)
            await persistentStore.save(gatewayAddress: address)
            
            // notify
            stateSubject.send(.loaded(response: gatewayAddressResponse, estimatedTransactionFee: estimatedFee))
            
            // continue previous works in a separated task
            let previousTask = Task<Void, Never>.detached { [weak self] in
                await self?.submitIfNeededAndMintAllTransactionsInQueue()
            }
            tasks.append(previousTask)
            
            // observe incomming transactions in a seprated task
            let observingTask = Task.detached { [weak self] in
                guard let self = self else {return}
                repeat {
                    if Task.isCancelled {
                        return
                    }
                    await self.getIncommingTransactionsAndMint()
                    try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(self.refreshingRate)) // 5 seconds
                } while true
            }
            tasks.append(observingTask)
            
        } catch {
            // indicate error
            stateSubject.send(.error(error))
        }
    }
    
    /// Get incomming transactions and mint
    private func getIncommingTransactionsAndMint() async {
        guard let address = await persistentStore.gatewayAddress
        else { return }
        
        // get incomming transaction
        guard let incommingTransactions = try? await self.sourceChainExplorerAPIClient.getIncommingTransactions(for: address)
        else {
            return
        }
        
        // save to persistentStore unsaved transaction
        for transaction in incommingTransactions {
            // get marker date
            var date = Date()
            if let blocktime = transaction.blockTime {
                date = Date(timeIntervalSince1970: TimeInterval(blocktime))
            }
            
            // receive new transaction
            if !transaction.isConfirmed {
                // transaction is not confirmed
                await persistentStore.markAsReceived(transaction, at: date)
                await updateProcessingTransactions()
            }
            
            // update unconfirmed transaction
            else {
                // if saved transaction is confirmed
                if let savedTransaction = await persistentStore.processingTransactions.first(where: {$0.tx.id == transaction.id}),
                   savedTransaction.state >= .confirmed
                {
                    // do nothing, transaction has been added to queue
                    return
                }
                
                // add to queue and mint if confirmed in separated task
                Task.detached { [weak self] in
                    await self?.addToQueueAndMint(transaction)
                }
            }
        }
    }
    
    /// Add new received transaction
    private func addToQueueAndMint(_ transaction: ExplorerAPIIncomingTransaction) async {
        let confirmationsStream = sourceChainExplorerAPIClient
            .observeConfirmations(id: transaction.id)
        for await confirmations in confirmationsStream {
            Task.detached { [weak self] in
                await self?.updateConfirmationsStatus(transaction: transaction, confirmations: confirmations)
            }
        }
        await persistentStore.markAsConfirmed(transaction, at: Date())
        await updateProcessingTransactions()
        await submitIfNeededAndMintAllTransactionsInQueue()
    }
    
    /// Update confirmations status
    private func updateConfirmationsStatus(transaction: ExplorerAPIIncomingTransaction, confirmations: UInt) async {
        var transaction = transaction
        transaction.confirmations = confirmations
        await persistentStore.markAsReceived(transaction, at: Date())
        await updateProcessingTransactions()
    }
    
    /// Submit if needed and mint array of tx
    func submitIfNeededAndMintAllTransactionsInQueue() async {
        // get all transactions that are valid and are not being processed
        let groupedTransactions = await persistentStore.processingTransactions.grouped()
        let confirmedAndSubmitedTransactions = groupedTransactions.confirmed + groupedTransactions.submited
        let transactionsToBeProcessed = confirmedAndSubmitedTransactions.filter {
            $0.isProcessing == false
        }
        
        // process transactions simutaneously
        await withTaskGroup(of: Void.self) { [weak self] group in
            for tx in transactionsToBeProcessed {
                group.addTask { [weak self] in
                    guard let self = self else {return}
                    do {
                        try await self.submitIfNeededAndMint(tx)
                    } catch {
                        if self.showLog {
                            print("submitIfNeededAndMint error: ", error)
                        }
                        
                    }
                }
            }
            
            for await _ in group {}
        }
    }
    
    /// Submit if needed and mint tx
    func submitIfNeededAndMint(_ tx: LockAndMint.ProcessingTx) async throws {
        // guard for tx that was confirmed or submited only
        guard tx.state.isConfirmed || tx.state.isSubmited else {
            return
        }
        
        // mark as processing
        await persistentStore.markAsProcessing(tx)
        await updateProcessingTransactions()
        
        // get infos
        let account = try await destinationChainProvider.getAccount()
        
        guard let response = stateSubject.value.response,
              let lockAndMint = lockAndMint,
              let chain = chain
        else { throw RenVMError.unknown }

        // get state
        let state = try lockAndMint.getDepositState(
            transactionHash: tx.tx.id,
            txIndex: String(tx.tx.vout),
            amount: String(tx.tx.value),
            sendTo: response.sendTo,
            gHash: response.gHash,
            gPubkey: response.gPubkey
        )
        
        // submit
        if !tx.state.isSubmited {
            do {
                try Task.checkCancellation()
                let hash = try await lockAndMint.submitMintTransaction(state: state)
                print("submited transaction with hash: \(hash)")
                await persistentStore.markAsSubmited(tx.tx, at: Date())
                await updateProcessingTransactions()
            } catch {
                debugPrint(error)
                // try to mint anyway, ignore error
            }
        }
        
        // mint
        try Task.checkCancellation()
        Task.retrying(
            where: { _ in true },
            maxRetryCount: .max,
            retryDelay: refreshingRate
        ) { [weak self] in
            guard let self = self else { return }
            try Task.checkCancellation()
            do {
                _ = try await lockAndMint.mint(state: state, signer: account.secret)
                await self.persistentStore.markAsMinted(tx.tx, at: Date())
                await self.updateProcessingTransactions()
            }
            
            // insufficient fund error
            catch let error as RenVMError where error.isInsufficientFundError {
                await self.persistentStore.markAsInvalid(txid: tx.tx.id, error: error.processingError, at: Date())
                if self.showLog {
                    Logger.log(event: .error, message: "Could not mint transaction with id \(tx.tx.id), error: \(error)")
                }
            }
            
            // already mint error
            catch let error where chain.isAlreadyMintedError(error) {
                // already minted
                await self.persistentStore.markAsMinted(tx.tx, at: Date())
                await self.updateProcessingTransactions()
            }
            
            // other error
            catch {
                if self.showLog {
                    Logger.log(event: .error, message: "Could not mint transaction with id \(tx.tx.id), error: \(error)")
                    Logger.log(event: .info, message: "Retrying...")
                }
                throw error
            }
        }
    }
}

private extension RenVMError {
    var isInsufficientFundError: Bool {
        message.starts(with: "insufficient amount after fees")
    }
    
    var processingError: LockAndMint.ProcessingError {
        let array = message
            .replacingOccurrences(of: "insufficient amount after fees: expected at least ", with: "")
            .replacingOccurrences(of: ", got ", with: " ")
            .components(separatedBy: " ")
        
        // mark as ignored
        if array.count == 2,
           let expected = UInt64(array[0]),
           let got = UInt64(array[1])
        {
            return .insufficientFund(expected: expected, got: got)
        } else {
            return .other(message)
        }
    }
}

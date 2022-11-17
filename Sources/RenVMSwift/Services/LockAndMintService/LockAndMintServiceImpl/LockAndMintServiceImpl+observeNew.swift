import Foundation

extension LockAndMintServiceImpl {
    /// Observe and mint if there is any new transaction
    func observeNewIncommingTransactionsAndMint() async {
        repeat {
            if Task.isCancelled {
                return
            }
            await getIncommingTransactionsAndMint()
            try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(self.refreshingRate)) // 5 seconds
        } while true
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
                await notifyChanges()
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
                    try await self?.addToQueueAndMint(transaction)
                }
            }
        }
    }
    
    /// Add new received transaction
    private func addToQueueAndMint(_ transaction: ExplorerAPIIncomingTransaction) async throws {
        let confirmationsStream = sourceChainExplorerAPIClient
            .observeConfirmations(id: transaction.id)
        for await confirmations in confirmationsStream {
            Task.detached { [weak self] in
                await self?.updateConfirmationsStatus(transaction: transaction, confirmations: confirmations)
            }
        }
        try await markAsConfirmedAndMint(transaction: transaction)
    }
    
    /// Update confirmations status
    private func updateConfirmationsStatus(transaction: ExplorerAPIIncomingTransaction, confirmations: UInt) async {
        var transaction = transaction
        transaction.confirmations = confirmations
        await persistentStore.markAsReceived(transaction, at: Date())
        await notifyChanges()
    }
    
    /// Mark transaction as confirmed and mint
    private func markAsConfirmedAndMint(transaction: ExplorerAPIIncomingTransaction) async throws {
        await persistentStore.markAsConfirmed(transaction, at: Date())
        await notifyChanges()
        
        if let transaction = await persistentStore.processingTransactions
            .first(where: {$0.tx.id == transaction.id})
        {
            try await submitIfNeededAndMint(transaction)
        }
    }
}

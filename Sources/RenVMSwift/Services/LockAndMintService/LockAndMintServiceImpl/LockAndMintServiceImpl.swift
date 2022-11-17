import Foundation
import LoggerSwift
import Combine

/// `LockAndMintService` implementation
public class LockAndMintServiceImpl: LockAndMintService {
    // MARK: - Dependencies
    
    /// PersistentStore for storing current work
    private let persistentStore: LockAndMintServicePersistentStore
    
    /// Destination chain provider
    private let destinationChainProvider: ChainProvider
    
    /// Source chain's Explorer APIClient
    private let sourceChainExplorerAPIClient: ExplorerAPIClient
    
    /// API Client for RenVM
    private let rpcClient: RenVMRpcClientType
    
    // MARK: - Properties
    
    /// Mint token
    private let mintToken: MintToken
    
    /// Version of renVM
    private let version: String
    
    /// Refreshing rate
    private let refreshingRate: TimeInterval
    
    /// Minting rate
    private let mintingRate: TimeInterval
    
    /// Flag to indicate of whether log should be shown or not
    private let showLog: Bool
    
    /// Loaded lockAndMint
    private var lockAndMint: LockAndMint?
    
    /// Chain
    private var chain: RenVMChainType?
    
    /// Tasks for cancellation
    private var tasks = [Task<Void, Never>]()
    
    /// State
    private let stateSubject = CurrentValueSubject<LockAndMintServiceState, Never>(.initializing)
    public var statePublisher: AnyPublisher<LockAndMintServiceState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    /// ProcessingTxs
    private let processingTxsSubject = CurrentValueSubject<[LockAndMint.ProcessingTx], Never>([])
    public var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> {
        processingTxsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initializers
    
    public init(
        persistentStore: LockAndMintServicePersistentStore,
        destinationChainProvider: ChainProvider,
        sourceChainExplorerAPIClient: ExplorerAPIClient,
        rpcClient: RenVMRpcClientType,
        mintToken: MintToken,
        version: String = "1",
        refreshingRate: TimeInterval = 5,
        mintingRate: TimeInterval = 60,
        showLog: Bool
    ) {
        self.persistentStore = persistentStore
        self.destinationChainProvider = destinationChainProvider
        self.sourceChainExplorerAPIClient = sourceChainExplorerAPIClient
        self.rpcClient = rpcClient
        self.mintToken = mintToken
        self.version = version
        self.refreshingRate = refreshingRate
        self.mintingRate = mintingRate
        self.showLog = showLog
    }
    
    deinit {}
    
    /// Start the service
    public func resume() async {
        // clean
        await clean()
        
        // resume current session if any
        guard let session = await persistentStore.session,
              session.isValid
        else {
            return
        }
        
        // resume
        await _resume()
    }
    
    /// Create new session
    public func createSession(endAt: Date?) async throws {
        // clean
        await clean()
        
        // create session
        let session = try LockAndMint.Session(createdAt: Date(), endAt: endAt)
        
        // save session
        await persistentStore.save(session: session)
        
        // resume
        await _resume()
    }
    
    /// Expire current session
    public func expireCurrentSession() async {
        // clean
        await clean()
        
        // clear
        await persistentStore.clearAll()
    }
    
    /// Get current gateway address
    public func getCurrentGatewayAddress() throws -> String? {
        guard let chain = chain, let data = stateSubject.value.response?.gatewayAddress else {return nil}
        return try chain.dataToAddress(data: data)
    }
    
    // MARK: - Private
    
    /// Clean all current set up
    private func clean() async {
        // cancel all current tasks
        tasks.forEach {$0.cancel()}
        
        // mark all transaction as not processing
        await persistentStore.markAllTransactionsAsNotProcessing()
        
        // notify
        stateSubject.send(.initializing)
        await updateProcessingTransactions()
    }
    
    /// Resume the current session
    private func _resume() async {
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
            }
            
            // update unconfirmed transaction
            else {
                // if saved transaction is confirmed
                if let savedTransaction = await persistentStore.processingTransactions.first(where: {$0.tx.id == transaction.id}),
                   savedTransaction.state >= .confirmed
                {
                    // do nothing, transaction has been marked
                }
                // transaction is confirmed, update or add new
                else {
                    await persistentStore.markAsConfirmed(transaction, at: date)
                }
            }
        }
        
        // update new data
        await updateProcessingTransactions()
        
        // submit if needed and mint
        await submitIfNeededAndMintAllTransactionsInQueue()
    }
    
    /// Submit if needed and mint array of tx
    func submitIfNeededAndMintAllTransactionsInQueue() async {
        // get all transactions that are valid and are not being processed
        let groupedTransactions = await persistentStore.processingTransactions.grouped()
        let confirmedAndSubmitedTransactions = groupedTransactions.confirmed + groupedTransactions.submited
        let transactionsToBeProcessed = confirmedAndSubmitedTransactions.filter {
            $0.isProcessing == false
        }
        
        // mark as processing
        for tx in transactionsToBeProcessed {
            await persistentStore.markAsProcessing(tx)
            await updateProcessingTransactions()
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
    
    // update current processing transactions
    private func updateProcessingTransactions() async {
        processingTxsSubject.send(await persistentStore.processingTransactions)
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

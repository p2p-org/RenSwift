import Foundation
import LoggerSwift

/// `LockAndMintService` implementation
public class LockAndMintServiceImpl: LockAndMintService {
    // MARK: - Dependencies
    
    /// PersistentStore for storing current work
    private let persistentStore: LockAndMintServicePersistentStore
    
    private let chainProvider: ChainProvider
    
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
    
    /// Response from gateway address
    private var gatewayAddressResponse: LockAndMint.GatewayAddressResponse?
    
    /// Loaded lockAndMint
    private var lockAndMint: LockAndMint?
    
    /// Chain
    private var chain: RenVMChainType?
    
    /// Tasks for cancellation
    private var tasks = [Task<Void, Never>]()
    
    /// Delegate
    public var delegate: LockAndMintServiceDelegate?
    
    /// Indicator isLoading
    public private(set) var isLoading: Bool = false
    
    // MARK: - Initializers
    
    public init(
        persistentStore: LockAndMintServicePersistentStore,
        chainProvider: ChainProvider,
        rpcClient: RenVMRpcClientType,
        mintToken: MintToken,
        version: String = "1",
        refreshingRate: TimeInterval = 5,
        mintingRate: TimeInterval = 60,
        showLog: Bool
    ) {
        self.persistentStore = persistentStore
        self.chainProvider = chainProvider
        self.rpcClient = rpcClient
        self.mintToken = mintToken
        self.version = version
        self.refreshingRate = refreshingRate
        self.mintingRate = mintingRate
        self.showLog = showLog
    }
    
    deinit {}
    
    /// Start the service
    public func resume() async throws {
        // clean
        await clean()
        
        // resume current session if any
        guard let session = await persistentStore.session,
              session.isValid
        else {
            return
        }
        
        // resume
        try await _resume()
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
        try await _resume()
    }
    
    public func expireCurrentSession() async throws {
        // clean
        await clean()
        
        // clear
        await persistentStore.clearAll()
    }
    
    // MARK: - Private
    
    /// Clean all current set up
    private func clean() async {
        await persistentStore.markAllTransactionsAsNotProcessing()
        await delegate?.lockAndMintService(self, didUpdateTransactions: await persistentStore.processingTransactions)
        tasks.forEach {$0.cancel()}
    }
    
    /// Resume the current session
    private func _resume() async throws {
        // loading
        await delegate?.lockAndMintServiceWillStartLoading(self)
        isLoading = true
        
        do {
            // get account
            let account = try await chainProvider.getAccount()
            
            // load chain
            chain = try await chainProvider.load()
            
            // load lock and mint
            lockAndMint = try LockAndMint(
                rpcClient: rpcClient,
                chain: chain!,
                mintTokenSymbol: mintToken.symbol,
                version: version,
                destinationAddress: account.publicKey,
                session: await persistentStore.session
            )
            
            // save address
            gatewayAddressResponse = try await lockAndMint!.generateGatewayAddress()
            let address = try chain!.dataToAddress(data: gatewayAddressResponse!.gatewayAddress)
            await persistentStore.save(gatewayAddress: address)
            
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
                    try? await self.getIncommingTransactionsAndMint()
                    try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(self.refreshingRate)) // 5 seconds
                } while true
            }
            tasks.append(observingTask)
            
            // loaded
            await delegate?.lockAndMintService(self, didLoadWithGatewayAddress: address)
            isLoading = false
            
        } catch {
            // indicate error
            await delegate?.lockAndMintService(self, didFailToLoadWithError: error)
            isLoading = false
        }
    }
    
    /// Get incomming transactions and mint
    private func getIncommingTransactionsAndMint() async throws {
        guard let address = await persistentStore.gatewayAddress
        else { return }
        
        // get incomming transaction
        guard let incommingTransactions = try? await self.rpcClient.getIncomingTransactions(address: address)
        else {
            return
        }
        
        // detect action for each incomming transactions, save status for future use
        var confirmedTxIds = [String]()
        for transaction in incommingTransactions {
            // get marker date
            var date = Date()
            if let blocktime = transaction.status.blockTime {
                date = Date(timeIntervalSince1970: TimeInterval(blocktime))
            }

            // for confirmed transaction, do submit
            if transaction.status.confirmed {
                // check if transaction is invalid
                if let tx = await persistentStore.processingTransactions.first(where: {$0.tx.txid == transaction.txid}),
                   tx.validationStatus != .valid
                {
                    if showLog {
                        Logger.log(event: .info, message: "Transaction \(transaction.txid) is being ignored because it is \(tx.validationStatus)")
                    }
                } else {
                    // mark as confirmed
                    await persistentStore.markAsConfirmed(transaction, at: date)
                    await delegate?.lockAndMintService(self, didUpdateTransactions: await persistentStore.processingTransactions)
                }
                
                // save to submit
                confirmedTxIds.append(transaction.txid)
            }
            
            // for inconfirming transaction, mark as received and wait
            else {
                // mark as received
                await persistentStore.markAsReceived(transaction, at: date)
                await delegate?.lockAndMintService(self, didUpdateTransactions: await persistentStore.processingTransactions)
            }
        }
        
        // submit if needed and mint
        await submitIfNeededAndMintAllTransactionsInQueue()
    }
    
    /// Submit if needed and mint array of tx
    func submitIfNeededAndMintAllTransactionsInQueue() async {
        // get all transactions that are valid and are not being processed
        let groupedTransactions = await persistentStore.processingTransactions.grouped()
        let confirmedAndSubmitedTransactions = groupedTransactions.confirmed + groupedTransactions.submited
        let transactionsToBeProcessed = confirmedAndSubmitedTransactions.filter {
            $0.isProcessing == false && $0.validationStatus == .valid
        }
        
        // mark as processing
        for tx in transactionsToBeProcessed {
            await persistentStore.markAsProcessing(tx)
            await delegate?.lockAndMintService(self, didUpdateTransactions: await persistentStore.processingTransactions)
        }
        
        // process transactions simutaneously
        await withTaskGroup(of: Void.self) { [weak self] group in
            for tx in transactionsToBeProcessed {
                group.addTask { [weak self] in
                    guard let self = self else {return}
                    do {
                        try await self.submitIfNeededAndMint(tx)
                    } catch let error as RenVMError {
                        if error.message.starts(with: "insufficient amount after fees") {
                            await self.persistentStore.markAsInvalid(txid: tx.tx.txid, reason: error.message)
                            await self.delegate?.lockAndMintService(self, didUpdateTransactions: await self.persistentStore.processingTransactions)
                        }
                    } catch {
                        if self.showLog {
                            Logger.log(event: .error, message: "Could not mint transaction with id \(tx.tx.txid), error: \(error)")
                        }
                    }
                }
            }
            
            for await _ in group {}
        }
    }
    
    /// Submit if needed and mint tx
    func submitIfNeededAndMint(_ tx: LockAndMint.ProcessingTx) async throws {
        let account = try await chainProvider.getAccount()
        
        guard let response = gatewayAddressResponse,
              let lockAndMint = lockAndMint,
              let chain = chain
        else { throw RenVMError.unknown }

        // get state
        let state = try lockAndMint.getDepositState(
            transactionHash: tx.tx.txid,
            txIndex: String(tx.tx.vout),
            amount: String(tx.tx.value),
            sendTo: response.sendTo,
            gHash: response.gHash,
            gPubkey: response.gPubkey
        )
        
        // submit
        if tx.submitedAt == nil {
            do {
                try Task.checkCancellation()
                let hash = try await lockAndMint.submitMintTransaction(state: state)
                print("submited transaction with hash: \(hash)")
                await persistentStore.markAsSubmited(tx.tx, at: Date())
                await delegate?.lockAndMintService(self, didUpdateTransactions: await persistentStore.processingTransactions)
            } catch {
                debugPrint(error)
                // try to mint event if error
            }
        }
        
        // mint
        try Task.checkCancellation()
        try await Task.retrying(
            where: { error in
                (error as? RenVMError) == .paramsMissing
            },
            maxRetryCount: .max,
            retryDelay: 5
        ) { [weak self] in
            guard let self = self else {throw CancellationError()}
            try Task.checkCancellation()
            do {
                _ = try await lockAndMint.mint(
                    state: state,
                    payerPubkey: try self.chainProvider.convertPublicKeyDataToString(account.publicKey),
                    payerSecretKey: account.secret
                )
            } catch {
                // other error
                if !chain.isAlreadyMintedError(error) {
                    throw error
                }
                
                // already minted
            }
        }.value
        
        
        await persistentStore.markAsMinted(tx.tx, at: Date())
        await delegate?.lockAndMintService(self, didUpdateTransactions: await persistentStore.processingTransactions)
    }
}

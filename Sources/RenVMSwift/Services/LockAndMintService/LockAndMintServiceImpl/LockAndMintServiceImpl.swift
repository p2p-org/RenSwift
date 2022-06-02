import Foundation

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
    
    /// Timer for observing incomming transaction
    private var timer: Timer?
    
    /// Response from gateway address
    private var gatewayAddressResponse: LockAndMint.GatewayAddressResponse?
    
    // MARK: - Initializers
    
    init(
        persistentStore: LockAndMintServicePersistentStore,
        chainProvider: ChainProvider,
        rpcClient: RenVMRpcClientType,
        mintToken: MintToken,
        version: String,
        refreshingRate: TimeInterval = 3,
        mintingRate: TimeInterval = 60
    ) {
        self.persistentStore = persistentStore
        self.chainProvider = chainProvider
        self.rpcClient = rpcClient
        self.mintToken = mintToken
        self.version = version
        self.refreshingRate = refreshingRate
        self.mintingRate = mintingRate
    }
    
    /// Start the service
    public func start() async throws {
        // clean
        clean()
        
        // resume current session if any
        guard let session = await persistentStore.session,
              session.isValid
        else {
            return
        }
        
        // resume
        try await resume()
    }
    
    /// Create new session
    public func createSession() async throws {
        // clean
        clean()
        
        // create session
        let session = try LockAndMint.Session(createdAt: Date())
        
        // save session
        try await persistentStore.save(session: session)
        
        // resume
        try await resume()
    }
    
    // MARK: - Private
    
    /// Clean all current set up
    private func clean() {
        timer?.invalidate()
    }
    
    /// Resume the current session
    private func resume() async throws {
        // get account
        let account = try await chainProvider.getAccount()
        
        // load chain
        let chain = try await chainProvider.load()
        
        // load lock and mint
        let lockAndMint = try LockAndMint(
            rpcClient: rpcClient,
            chain: chain,
            mintTokenSymbol: mintToken.symbol,
            version: version,
            destinationAddress: account.publicKey,
            session: await persistentStore.session
        )
        
        // save address
        let response = try await lockAndMint.generateGatewayAddress()
        gatewayAddressResponse = response
        let address = try chain.dataToAddress(data: response.gatewayAddress)
        try await persistentStore.save(gatewayAddress: address)
        
        // observe incomming transactions
        observeIncommingTransactions()
    }
    
    /// Observe for new transactions
    private func observeIncommingTransactions() {
        timer = .scheduledTimer(withTimeInterval: refreshingRate, repeats: true) { [weak self] timer in
            Task { [weak self] in
                try await self?.getIncommingTransactionsAndMint()
            }
            
        }
    }
    
    /// Get incomming transactions and mint
    private func getIncommingTransactionsAndMint() async throws {
        guard let address = await persistentStore.gatewayAddress,
              let response = gatewayAddressResponse
        else { return }
        
        // get incomming transaction
        guard let incommingTransactions = try? await self.rpcClient.getIncomingTransactions(address: address)
        else {
            return
        }
        
        // detect action for each incomming transactions, save status for future use
        for transaction in incommingTransactions {
            // get marker date
            var date = Date()
            if let blocktime = transaction.status.blockTime {
                date = Date(timeIntervalSince1970: TimeInterval(blocktime))
            }

            // for confirmed transaction, do submit
            if transaction.status.confirmed {
                // mark as confirmed
                self.sessionStorage.processingTx(tx: tx, didConfirmAt: date)
                
                // submit
                
                // mint
            }
            
            // for inconfirming transaction, mark as received and wait
            else {
                // mark as received
                self.sessionStorage.processingTx(tx: tx, didReceiveAt: date)
            }
        }
        
    }
    
    
    /// Submit and mint
    
}

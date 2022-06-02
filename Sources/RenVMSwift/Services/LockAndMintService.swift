import Foundation

/// Service that is responsible for LockAndMint action
public protocol LockAndMintService: AnyObject {
    /// Start the service
    func start() async throws
    
    /// Create new session
    func createSession() async throws
}

/// PersistentStore to persist session
public protocol LockAndMintServicePersistentStore {
    /// Current working Session
    var session: LockAndMint.Session? { get async }
    
    /// CurrentGatewayAddress
    var gatewayAddress: String? {get async}
    
    /// Save session
    func save(session: LockAndMint.Session) async throws
    
    /// Save gateway address
    func save(gatewayAddress: String) async throws
}

/// `LockAndMintService` implementation
public class LockAndMintServiceImpl: LockAndMintService {
    // MARK: - Nested type
    public struct MintToken {
        let name: String
        let symbol: String
        
        public var bitcoin: MintToken {
            .init(name: "Bitcoin", symbol: "BTC")
        }
    }
    
    // MARK: - Dependencies
    
    /// PersistentStore for storing current work
    private let persistentStore: LockAndMintServicePersistentStore
    
    private let chainProvider: ChainProvider
    
    /// API Client for RenVM
    private let rpcClient: RenVMRpcClientType
    
    /// Mint token
    private let mintToken: MintToken
    
    /// Version of renVM
    private let version: String
    
    /// Refreshing rate
    private let refreshingRate: TimeInterval
    
    // MARK: - Properties
    private var timer: Timer?
    
    
    // MARK: - Initializers
    init(
        persistentStore: LockAndMintServicePersistentStore,
        chainProvider: ChainProvider,
        rpcClient: RenVMRpcClientType,
        mintToken: MintToken,
        version: String,
        refreshingRate: TimeInterval = 3
    ) {
        self.persistentStore = persistentStore
        self.chainProvider = chainProvider
        self.rpcClient = rpcClient
        self.mintToken = mintToken
        self.version = version
        self.refreshingRate = refreshingRate
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
        let address = try chain.dataToAddress(data: response.gatewayAddress)
        try await persistentStore.save(gatewayAddress: address)
        
        // observe incomming transactions
        observeIncommingTransactions()
    }
    
    /// Observe for new transactions
    private func observeIncommingTransactions() {
        timer = .scheduledTimer(withTimeInterval: refreshingRate, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
        }
    }
}

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
    let persistentStore: LockAndMintServicePersistentStore
    
    let chainProvider: ChainProvider
    
    /// API Client for RenVM
    let rpcClient: RenVMRpcClientType
    
    /// Mint token
    let mintToken: MintToken
    
    /// Version of renVM
    let version: String
    
    // MARK: - Properties
    
    
    // MARK: - Initializers
    init(
        persistentStore: LockAndMintServicePersistentStore,
        chainProvider: ChainProvider,
        rpcClient: RenVMRpcClientType,
        mintToken: MintToken,
        version: String
    ) {
        self.persistentStore = persistentStore
        self.chainProvider = chainProvider
        self.rpcClient = rpcClient
        self.mintToken = mintToken
        self.version = version
    }
    
    /// Start the service
    public func start() async throws {
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
        // create session
        let session = try LockAndMint.Session(createdAt: Date())
        
        // save session
        try await persistentStore.save(session: session)
        
        // resume
        try await resume()
    }
    
    // MARK: - Private
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
    }
}

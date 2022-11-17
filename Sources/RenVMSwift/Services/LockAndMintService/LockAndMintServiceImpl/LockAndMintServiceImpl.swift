import Foundation
import LoggerSwift
import Combine

/// `LockAndMintService` implementation
public class LockAndMintServiceImpl: LockAndMintService {
    // MARK: - Dependencies
    
    /// PersistentStore for storing current work
    let persistentStore: LockAndMintServicePersistentStore
    
    /// Destination chain provider
    let destinationChainProvider: ChainProvider
    
    /// Source chain's Explorer APIClient
    let sourceChainExplorerAPIClient: ExplorerAPIClient
    
    /// API Client for RenVM
    let rpcClient: RenVMRpcClientType
    
    // MARK: - Properties
    
    /// Mint token
    let mintToken: MintToken
    
    /// Version of renVM
    let version: String
    
    /// Refreshing rate
    let refreshingRate: TimeInterval
    
    /// Flag to indicate of whether log should be shown or not
    let showLog: Bool
    
    /// Loaded lockAndMint
    var lockAndMint: LockAndMint?
    
    /// Chain
    var chain: RenVMChainType?
    
    /// Tasks for cancellation
    var tasks = [Task<Void, Never>]()
    
    /// State
    let stateSubject = CurrentValueSubject<LockAndMintServiceState, Never>(.initializing)
    
    /// ProcessingTxs
    let processingTxsSubject = CurrentValueSubject<[LockAndMint.ProcessingTx], Never>([])
    
    // MARK: - Initializers
    
    public init(
        persistentStore: LockAndMintServicePersistentStore,
        destinationChainProvider: ChainProvider,
        sourceChainExplorerAPIClient: ExplorerAPIClient,
        rpcClient: RenVMRpcClientType,
        mintToken: MintToken,
        version: String = "1",
        refreshingRate: TimeInterval = 5,
        showLog: Bool
    ) {
        self.persistentStore = persistentStore
        self.destinationChainProvider = destinationChainProvider
        self.sourceChainExplorerAPIClient = sourceChainExplorerAPIClient
        self.rpcClient = rpcClient
        self.mintToken = mintToken
        self.version = version
        self.refreshingRate = refreshingRate
        self.showLog = showLog
    }
    
    deinit {}
    
    /// State
    public var statePublisher: AnyPublisher<LockAndMintServiceState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    /// processing tx
    public var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> {
        processingTxsSubject.eraseToAnyPublisher()
    }
    
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
}

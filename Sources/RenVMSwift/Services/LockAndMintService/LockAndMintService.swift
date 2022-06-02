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

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
    // MARK: - Session
    /// Current working Session
    var session: LockAndMint.Session? { get async }
    
    /// Save session
    func save(session: LockAndMint.Session) async throws
    
    // MARK: - GatewayAddress
    /// CurrentGatewayAddress
    var gatewayAddress: String? { get async }
    
    /// Save gateway address
    func save(gatewayAddress: String) async throws
    
    // MARK: - ProcessingTransaction
    
    /// Transaction which are being processed
    var processingTransactions: LockAndMint.ProcessingTx { get async }
    
    /// Mark as received
    func markAsReceived(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
    
    /// Mark as confimed
    func markAsConfirmed(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
    
    /// Mark as submited
    func markAsSubmited(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
    
    /// Mark as minted
    func markAsMinted(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
}

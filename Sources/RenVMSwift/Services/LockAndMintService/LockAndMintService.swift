import Foundation
import Combine

/// Service that is responsible for LockAndMint action
public protocol LockAndMintService: AnyObject {
    /// State
    var statePublisher: AnyPublisher<LockAndMintServiceState, Never> { get }
    
    /// processing tx
    var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> { get }
    
    /// Resume the service
    func resume() async
    
    /// Create new session
    func createSession(endAt: Date?) async throws
    
    /// expire session
    func expireCurrentSession() async
    
    /// get gateway address
    func getCurrentGatewayAddress() throws -> String?
}

extension LockAndMintService {
    
    /// Handy method for create session, endAt default
    public func createSession() async throws {
        try await createSession(endAt: nil)
    }
}

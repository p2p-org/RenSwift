import Foundation
import Combine

/// Service that is responsible for LockAndMint action
public protocol LockAndMintService: AnyObject {
    /// State
    var statePublisher: AnyPublisher<LockAndMintServiceState, Never> { get }
    
    /// processing tx
    var processingTxsPublisher: AnyPublisher<[LockAndMint.ProcessingTx], Never> { get }
    
    /// Resume the service
    func resume() async throws
    
    /// Create new session
    func createSession(endAt: Date?) async throws
    
    /// expire session
    func expireCurrentSession() async throws
    
    /// get gateway address
    func getGatewayAddress() async throws -> String?
}

extension LockAndMintService {
    
    /// Handy method for create session, endAt default
    public func createSession() async throws {
        try await createSession(endAt: nil)
    }
}

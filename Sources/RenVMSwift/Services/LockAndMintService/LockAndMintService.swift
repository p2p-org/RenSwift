import Foundation

/// Service that is responsible for LockAndMint action
public protocol LockAndMintService: AnyObject {
    
    /// Is loading
    var isLoading: Bool { get }
    
    /// Delegate
    var delegate: LockAndMintServiceDelegate? { get set }
    
    /// Resume the service
    func resume() async throws
    
    /// Create new session
    func createSession(endAt: Date?) async throws
}

extension LockAndMintService {
    
    /// Handy method for create session, endAt default
    public func createSession() async throws {
        try await createSession(endAt: nil)
    }
}

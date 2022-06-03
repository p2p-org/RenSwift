import Foundation

/// Service that is responsible for LockAndMint action
public protocol LockAndMintService: AnyObject {
    /// Resume the service
    func resume() async throws
    
    /// Create new session
    func createSession(endAt: Date?) async throws
}

extension LockAndMintService {
    public func createSession() async throws {
        try await createSession(endAt: nil)
    }
}

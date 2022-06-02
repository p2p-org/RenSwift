import Foundation

/// Service that is responsible for LockAndMint action
public protocol LockAndMintService: AnyObject {
    /// Start the service
    func start() async throws
    
    /// Create new session
    func createSession() async throws
}

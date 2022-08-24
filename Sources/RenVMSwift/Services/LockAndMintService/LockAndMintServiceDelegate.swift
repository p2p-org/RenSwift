import Foundation

/// Delegate for lock and mint service
public protocol LockAndMintServiceDelegate: AnyObject {
    
    // MARK: - Loading
    /// Start loading
    @MainActor func lockAndMintServiceWillStartLoading(_ lockAndMintService: LockAndMintService)
    
    /// Loaded
    @MainActor func lockAndMintService(_ lockAndMintService: LockAndMintService, didLoadWithGatewayAddress gatewayAddress: String)
    
    /// Stop loading with error
    @MainActor func lockAndMintService(_ lockAndMintService: LockAndMintService, didFailToLoadWithError error: Error)
    
    // MARK: - Transaction events
    
    /// Transactions updated
    @MainActor func lockAndMintService(_ lockAndMintService: LockAndMintService, didUpdateTransactions transactions: [LockAndMint.ProcessingTx])
}

import Foundation

/// Delegate for lock and mint service
public protocol LockAndMintServiceDelegate: AnyObject {
    
    // MARK: - Loading
    /// Start loading
    func lockAndMintServiceWillStartLoading(_ lockAndMintService: LockAndMintService)
    
    /// Loaded
    func lockAndMintService(_ lockAndMintService: LockAndMintService, didLoadWithGatewayAddress gatewayAddress: String)
    
    /// Stop loading with error
    func lockAndMintService(_ lockAndMintService: LockAndMintService, didFailToLoadWithError error: Error)
    
    // MARK: - Transaction events
    
    /// Transactions updated
    func lockAndMintService(_ lockAndMintService: LockAndMintService, didUpdateTransactions transactions: [LockAndMint.ProcessingTx])
}

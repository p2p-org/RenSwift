import Foundation
import LoggerSwift

/// Default protocol for explorer api
public protocol ExplorerAPIClient {
    /// Get incomming transaction for LockAndMint process
    /// - Parameter address: gateway address
    /// - Returns: list of incomming transaction
    func getIncommingTransactions(for address: String) async throws -> [ExplorerAPIIncomingTransaction]
    
    /// Get transaction info that involves in LockAndMint process
    /// - Parameter transaction: transaction
    /// - Returns: info of the transaction
    func getTransactionInfo(_ transaction: String) async throws -> ExplorerAPITransaction
}

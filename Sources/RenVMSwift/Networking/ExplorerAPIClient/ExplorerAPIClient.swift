import Foundation
import LoggerSwift

/// Default protocol for explorer api
public protocol ExplorerAPIClient {
    /// Get incomming transaction for LockAndMint process
    /// - Parameter address: gateway address
    /// - Returns: list of incomming transaction
    func getIncommingTransactions(for address: String) async throws -> [ExplorerAPIIncomingTransaction]
    
    /// Observe confirmation of a transaction
    /// - Parameter id: transaction's id
    /// - Returns: data stream of confirmations
    func observeConfirmations(id: String) -> AsyncStream<UInt>
}

import Foundation
import LoggerSwift

/// BTC explorer api
public class BTCExplorerAPIClient: ExplorerAPIClient {
    // MARK: - Properties
    
    /// RenVM network
    private let network: Network
    
    // MARK: - Initializer
    
    /// Initializer
    /// - Parameter network: renvm network
    public init(network: Network) {
        self.network = network
    }
    
    /// Get incomming transaction for LockAndMint process
    /// - Parameter address: gateway address
    /// - Returns: list of incomming transaction
    public func getIncommingTransactions(for address: String) async throws -> [ExplorerAPIIncomingTransaction] {
        let urlString = "https://blockstream.info\(network.isTestnet ? "/testnet": "")/api/address/\(address)/utxo"
        guard let url = URL(string: urlString)
        else {
            throw RenVMError.invalidEndpoint
        }
        Logger.log(event: .request, message: urlString)
        let (data, _) = try await URLSession.shared.data(for: url)
        Logger.log(event: .response, message: String(data: data, encoding: .utf8) ?? "")
        return try JSONDecoder().decode([BlockstreamIncomingTransaction].self, from: data)
            .map {$0.mapToExplorerAPIIncomingTransaction()}
    }
    
    public func getTransactionInfo(_ transaction: String) async throws -> ExplorerAPITransaction {
        fatalError()
    }
}

// MARK: - Models
struct BlockstreamIncomingTransaction: Codable, Equatable, Hashable {
    let txid: String
    var vout: UInt
    var status: BlockstreamInfoStatus
    let value: UInt64
    
    func mapToExplorerAPIIncomingTransaction() -> ExplorerAPIIncomingTransaction {
        ExplorerAPIIncomingTransaction(
            id: txid,
            confirmations: vout,
            vout: vout,
            value: value,
            isConfirmed: status.confirmed,
            blockTime: status.blockTime
        )
    }
}

struct BlockstreamInfoStatus: Codable, Equatable, Hashable {
    var confirmed: Bool
    var blockHeight: UInt64?
    var blockHash: String?
    var blockTime: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case confirmed
        case blockHeight = "block_height"
        case blockHash = "block_hash"
        case blockTime = "block_time"
    }
}

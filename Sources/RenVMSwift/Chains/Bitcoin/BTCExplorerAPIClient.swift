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
    
    /// Get transaction info that involves in LockAndMint process
    /// - Parameter id: transaction's id
    /// - Returns: info of the transaction
    public func getTransactionInfo(with id: String) async throws -> ExplorerAPITransaction {
        let urlString = "https://blockstream.info\(network.isTestnet ? "/testnet": "")/api/tx/\(id)"
        guard let url = URL(string: urlString)
        else {
            throw RenVMError.invalidEndpoint
        }
        Logger.log(event: .request, message: urlString)
        let (data, _) = try await URLSession.shared.data(for: url)
        Logger.log(event: .response, message: String(data: data, encoding: .utf8) ?? "")
        return try JSONDecoder().decode(BlockstreamTransaction.self, from: data)
            .mapToExplorerAPITransaction()
    }
}

// MARK: - BlockstreamIncomingTransaction

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

// MARK: - BlockstreamTransaction

struct BlockstreamTransaction: Codable {
    let txid: String
    let version, locktime: Int
    let vin: [BlockstreamTransactionVin]
    let vout: [BlockstreamTransactionVout]
    let size, weight, fee: Int
    let status: BlockstreamInfoStatus
    
    func mapToExplorerAPITransaction() -> ExplorerAPITransaction {
        ExplorerAPITransaction(id: txid)
    }
}

struct BlockstreamTransactionVin: Codable {
    let txid: String
    let vout: Int
    let prevout: BlockstreamTransactionVout
    let scriptsig, scriptsigASM: String
    let witness: [String]
    let isCoinbase: Bool
    let sequence: Int

    enum CodingKeys: String, CodingKey {
        case txid, vout, prevout, scriptsig
        case scriptsigASM = "scriptsig_asm"
        case witness
        case isCoinbase = "is_coinbase"
        case sequence
    }
}

struct BlockstreamTransactionVout: Codable {
    let scriptpubkey, scriptpubkeyASM, scriptpubkeyType, scriptpubkeyAddress: String
    let value: Int

    enum CodingKeys: String, CodingKey {
        case scriptpubkey
        case scriptpubkeyASM = "scriptpubkey_asm"
        case scriptpubkeyType = "scriptpubkey_type"
        case scriptpubkeyAddress = "scriptpubkey_address"
        case value
    }
}


import Foundation
import LoggerSwift
import Task_retrying

/// BTC explorer api
public class BTCExplorerAPIClient: ExplorerAPIClient {
    // MARK: - Constants
    
    /// Max confirmation for BTC network
    private let maxConfirmations: UInt = 6
    
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
        return try await get(urlString: urlString, decodedTo: [BlockstreamIncomingTransaction].self)
            .map {$0.mapToExplorerAPIIncomingTransaction()}
    }
    
    /// Observe confirmation of a transaction
    /// - Parameter id: transaction's id
    /// - Returns: data stream of confirmations
    public func observeConfirmations(id: String) -> AsyncStream<UInt> {
        if network.isTestnet {
            // TODO: - Fix for testnet
            return .init { continuation in
                continuation.finish()
            }
        }
        
        // For mainnet, use btc.com
        return .init { continuation in
            Task.retrying(
                where: { error in
                    if let error = error as? TaskRetryingError, error == .timedOut {
                        continuation.finish()
                        return false
                    }
                    return true
                },
                maxRetryCount: .max,
                retryDelay: 10, // seconds
                timeoutInSeconds: 60 * 60 // 1h
            ) { [weak self] in
                guard let self = self else {
                    continuation.finish()
                    return
                }
                try Task.checkCancellation()
                
                let confirmations = try await self.get(
                    urlString: "https://chain.api.btc.com/v3/tx/\(id)",
                    decodedTo: BTCCOMTransaction.self
                )
                    .data.confirmations
                
                continuation.yield(confirmations)
                
                if confirmations < self.maxConfirmations {
                    throw BTCExplorerAPIClientError.notYetConfirmed
                }
                
                continuation.finish()
            }
        }
    }
    
    private func `get`<T: Decodable>(urlString: String, decodedTo: T.Type) async throws -> T {
        guard let url = URL(string: urlString)
        else {
            throw RenVMError.invalidEndpoint
        }
        Logger.log(event: .request, message: urlString)
        let (data, _) = try await URLSession.shared.data(for: url)
        Logger.log(event: .response, message: String(data: data, encoding: .utf8) ?? "")
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - BTCExplorerAPIClientError

private enum BTCExplorerAPIClientError: Error {
    case notYetConfirmed
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

// MARK: - BTCComTransaction
private struct BTCCOMTransaction: Codable {
    let data: BTCCOMTransactionData
}

// MARK: - DataClass
struct BTCCOMTransactionData: Codable {
    let confirmations: UInt
}

import Foundation

public struct IncomingTransaction: Decodable, Equatable {
    public let txid: String
    public var vout: UInt64
    public var status: BlockstreamInfoStatus
    public let value: UInt64
    
    public init(txid: String, vout: UInt64, status: BlockstreamInfoStatus, value: UInt64) {
        self.txid = txid
        self.vout = vout
        self.status = status
        self.value = value
    }
}

public struct BlockstreamInfoStatus: Decodable, Equatable {
    public var confirmed: Bool
    public var blockHeight: UInt64?
    public var blockHash: String?
    public var blockTime: UInt64?
    
    enum CodingKeys: String, CodingKey {
        case confirmed
        case blockHeight = "block_height"
        case blockHash = "block_hash"
        case blockTime = "block_time"
    }
    
    public init(confirmed: Bool, blockHeight: UInt64? = nil, blockHash: String? = nil, blockTime: UInt64? = nil) {
        self.confirmed = confirmed
        self.blockHeight = blockHeight
        self.blockHash = blockHash
        self.blockTime = blockTime
    }
}

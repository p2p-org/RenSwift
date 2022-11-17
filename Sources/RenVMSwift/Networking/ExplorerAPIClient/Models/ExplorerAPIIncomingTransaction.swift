import Foundation

public struct ExplorerAPIIncomingTransaction: Codable, Equatable, Hashable {
    public let id: String
    public var confirmations: UInt?
    public let vout: UInt
    public let value: UInt64
    public let isConfirmed: Bool
    public let blockTime: UInt64?
}


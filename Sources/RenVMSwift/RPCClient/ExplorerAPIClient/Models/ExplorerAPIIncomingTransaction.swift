import Foundation

public struct ExplorerAPIIncomingTransaction: Codable, Equatable, Hashable {
    public let id: String
    public let confirmations: UInt
    public let value: UInt64
    public let isConfirmed: Bool
    public let blockTime: UInt64?
}


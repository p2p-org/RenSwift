import Foundation

extension LockAndMintServiceImpl {
    public struct MintToken {
        let name: String
        let symbol: String
        
        public var bitcoin: MintToken {
            .init(name: "Bitcoin", symbol: "BTC")
        }
    }
    
    public struct ProcessingTx: Codable, Hashable {
        public static let maxVote: UInt64 = 3
        public var tx: IncomingTransaction
        public var receivedAt: Date?
        public var oneVoteAt: Date?
        public var twoVoteAt: Date?
        public var threeVoteAt: Date?
        public var confirmedAt: Date?
        public var submittedAt: Date?
        public var mintedAt: Date?

        public var value: Double {
            tx.value.convertToBalance(decimals: 8)
        }
    }
}

import Foundation

public struct LockAndMintProcessingTx: Codable, Hashable {
    public static let maxVote: UInt64 = 3
    public var tx: IncomingTransaction
    public var receivedAt: Date?
    public var oneVoteAt: Date?
    public var twoVoteAt: Date?
    public var threeVoteAt: Date?
    public var confirmedAt: Date?
    public var submitedAt: Date?
    public var mintedAt: Date?

    public var value: Double {
        tx.value.convertToBalance(decimals: 8)
    }
}

extension Array where Element == LockAndMintProcessingTx {
    func grouped() -> (minted: [Element], submited: [Element], confirmed: [Element], received: [Element]) {
        var minted = [Element]()
        var submited = [Element]()
        var confirmed = [Element]()
        var received = [Element]()
        for tx in self {
            if tx.mintedAt != nil {
                minted.append(tx)
            } else if tx.submitedAt != nil {
                submited.append(tx)
            } else if tx.confirmedAt != nil {
                confirmed.append(tx)
            } else if tx.receivedAt != nil {
                received.append(tx)
            }
        }
        return (minted: minted, submited: submited, confirmed: confirmed, received: received)
    }
}

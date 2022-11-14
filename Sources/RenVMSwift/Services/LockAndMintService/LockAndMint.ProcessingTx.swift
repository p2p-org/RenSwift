import Foundation

extension LockAndMint {
    public enum ProcessingError: Codable, Hashable {
        case insufficientFund(expected: UInt64, got: UInt64)
        case other(String)
    }
    
    public struct ProcessingTx: Codable, Hashable {
        public static var maxVote: UInt = 3
        public var tx: LockAndMint.IncomingTransaction
        public var state: State
        public var isProcessing: Bool = false
        public var timestamp: Timestamp = .init()
        
        public enum State: Codable, Hashable {
            case confirming
            case confirmed
            case submited
            case minted
            case ignored(error: LockAndMint.ProcessingError)
            
            public var isConfirmed: Bool {
                switch self {
                case .confirmed:
                    return true
                default:
                    return false
                }
            }
            
            public var isSubmited: Bool {
                switch self {
                case .submited:
                    return true
                default:
                    return false
                }
            }
            
            public var isMinted: Bool {
                switch self {
                case .minted:
                    return true
                default:
                    return false
                }
            }
            
            public var isIgnored: Bool {
                switch self {
                case .ignored:
                    return true
                default:
                    return false
                }
            }
            
            public var ingoredError: LockAndMint.ProcessingError? {
                switch self {
                case let .ignored(error):
                    return error
                default:
                    return nil
                }
            }
        }
        
        public struct Timestamp: Codable, Hashable {
            public var voteAt: [UInt: Date] = [:]
            public var confirmedAt: Date?
            public var submitedAt: Date?
            public var mintedAt: Date?
            public var ignoredAt: Date?
            
            public var lastVoteAt: Date? {
                voteAt.keys.max() != nil ? voteAt[voteAt.keys.max()!]: nil
            }
            
            public var firstReceivedAt: Date? {
                voteAt.keys.min() != nil ? voteAt[voteAt.keys.min()!]: nil
            }
        }
    }
}

extension Array where Element == LockAndMint.ProcessingTx {
    func grouped() -> (minted: [Element], submited: [Element], confirmed: [Element], received: [Element], ignored: [Element]) {
        var minted = [Element]()
        var submited = [Element]()
        var confirmed = [Element]()
        var received = [Element]()
        var ignored = [Element]()
        for tx in self {
            switch tx.state {
            case .minted:
                minted.append(tx)
            case .submited:
                submited.append(tx)
            case .confirmed:
                confirmed.append(tx)
            case .confirming:
                received.append(tx)
            case .ignored:
                ignored.append(tx)
            }
        }
        return (minted: minted, submited: submited, confirmed: confirmed, received: received, ignored: ignored)
    }
}

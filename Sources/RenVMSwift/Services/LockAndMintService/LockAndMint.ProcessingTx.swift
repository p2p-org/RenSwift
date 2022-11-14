import Foundation

extension LockAndMint {
    public enum ProcessingError: Codable, Hashable {
        case insufficientFund(expected: UInt64, got: UInt64)
        case other(String)
    }
    
    public struct ProcessingTx: Codable, Hashable {
        public enum State: Codable, Hashable {
            case received(at: Date)
            case voted(numberOfVotes: UInt, at: Date)
            case confirmed(at: Date)
            case submited(at: Date)
            case minted(at: Date)
            case ignored(at: Date, error: LockAndMint.ProcessingError)
            
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
                case let .ignored(_, error):
                    return error
                default:
                    return nil
                }
            }
        }
        
        public static var maxVote: UInt = 3
        public var tx: LockAndMint.IncomingTransaction
        public var state: State
        public var isProcessing: Bool = false
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
            case .received:
                received.append(tx)
            case .ignored:
                ignored.append(tx)
            default:
                break
            }
        }
        return (minted: minted, submited: submited, confirmed: confirmed, received: received, ignored: ignored)
    }
}

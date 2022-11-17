import Foundation

extension LockAndMint {
    public enum ProcessingError: Codable, Hashable {
        case insufficientFund(expected: UInt64, got: UInt64)
        case other(String)
    }
    
    public struct ProcessingTx: Codable, Hashable {
        public var tx: ExplorerAPIIncomingTransaction
        public var state: State
        public var isProcessing: Bool = false
        public var timestamp: Timestamp = .init()
        
        public enum State: Codable, Hashable, Comparable, Equatable {
            case confirming
            case confirmed
            case submited
            case minted
            case ignored(error: LockAndMint.ProcessingError)
            
            private var _numRepresentable: Int {
                switch self {
                case .confirming:
                    return 0
                case .confirmed:
                    return 1
                case .submited:
                    return 2
                case .minted:
                    return 3
                case .ignored:
                    return 4
                }
            }
            
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
            
            public static func < (lhs: LockAndMint.ProcessingTx.State, rhs: LockAndMint.ProcessingTx.State) -> Bool {
                lhs._numRepresentable < rhs._numRepresentable
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

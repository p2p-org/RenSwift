import Foundation

extension LockAndMintServiceImpl {
    public struct MintToken {
        let name: String
        let symbol: String
        
        public var bitcoin: MintToken {
            .init(name: "Bitcoin", symbol: "BTC")
        }
    }
}

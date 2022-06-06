import Foundation

public struct ResponseQueryConfig: Decodable {
    let confirmations: Confirmations
    let maxConfirmations: Confirmations
    let network: String
    let registries: Registries
    let whitelist: [String]?
    
    struct Confirmations: Decodable {
        let Bitcoin: String
        let Ethereum: String
    }
    
    struct Registries: Decodable {
        let Ethereum: String
    }
}

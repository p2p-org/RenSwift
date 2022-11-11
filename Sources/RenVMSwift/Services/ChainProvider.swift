import Foundation

/// Chain provider
public protocol ChainProvider {
    /// Get authorized account from chain
    func getAccount() async throws -> (publicKey: Data, secret: Data?)
    /// Load chain
    func load() async throws -> RenVMChainType
    /// Converter
    func convertPublicKeyDataToString(_ publicKey: Data) throws -> String
}

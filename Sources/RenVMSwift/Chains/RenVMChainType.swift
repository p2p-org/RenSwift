import Foundation

public protocol RenVMChainType {
    var chainName: String {get}
    func getAssociatedTokenAddress(
        address: Data,
        mintTokenSymbol: String
    ) throws -> Data // represent as data, because there might be different encoding methods for various of chains
    func dataToAddress(
        data: Data
    ) throws -> String
    
    func signatureToData(
        signature: String
    ) throws -> Data
    
    func submitMint(
        address: Data,
        mintTokenSymbol: String,
        signer: Data,
        responceQueryMint: ResponseQueryTxMint
    ) async throws -> String
    
    func submitBurn(
        mintTokenSymbol: String,
        account: Data,
        amount: String,
        recipient: String,
        signer: Data
    ) async throws -> BurnAndRelease.BurnDetails
}

extension RenVMChainType {
    func selector(mintTokenSymbol: String, direction: Selector.Direction) -> Selector {
        .init(mintTokenSymbol: mintTokenSymbol, chainName: chainName, direction: direction)
    }
}

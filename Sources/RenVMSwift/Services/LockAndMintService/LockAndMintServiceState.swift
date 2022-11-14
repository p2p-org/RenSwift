import Foundation

public enum LockAndMintServiceState {
    case initializing
    case loading
    case loaded(response: LockAndMint.GatewayAddressResponse, estimatedTransactionFee: UInt64)
    case error(_ error: Error)
    
    var response: LockAndMint.GatewayAddressResponse? {
        switch self {
        case .loaded(let response, _):
            return response
        default:
            return nil
        }
    }
    
    public func gatewayAddress(chain: RenVMChainType) throws -> String? {
        switch self {
        case .loaded(let response, _):
            return try chain.dataToAddress(data: response.gatewayAddress)
        default:
            return nil
        }
    }
    
    public var estimatedTransctionFee: UInt64? {
        switch self {
        case .loaded(_, let fee):
            return fee
        default:
            return nil
        }
    }
}

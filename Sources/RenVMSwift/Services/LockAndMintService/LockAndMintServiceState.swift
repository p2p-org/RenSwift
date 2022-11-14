import Foundation

public enum LockAndMintServiceState {
    case initializing
    case loading
    case loaded(gatewayAddress: String)
    case error(_ error: Error)
}

import Foundation
import LoggerSwift

public protocol RenVMRpcClientType {
    var network: Network {get}
    func call<T: Decodable>(endpoint: String, method: String, params: Encodable, log: Bool) async throws -> T
    func selectPublicKey(mintTokenSymbol: String) async throws -> Data?
    func getIncomingTransactions(address: String) async throws -> [LockAndMint.IncomingTransaction]
}

public extension RenVMRpcClientType {
    private var emptyParams: [String: String] {[:]}
    func queryMint(txHash: String) async throws -> ResponseQueryTxMint {
        try await call(endpoint: network.lightNode, method: "ren_queryTx", params: ["txHash": txHash], log: true)
    }
    
    func queryBlockState(log: Bool = false) async throws -> ResponseQueryBlockState {
        try await call(endpoint: network.lightNode, method: "ren_queryBlockState", params: emptyParams, log: log)
    }

    func queryConfig() async throws -> ResponseQueryConfig {
        try await call(endpoint: network.lightNode, method: "ren_queryConfig", params: emptyParams, log: true)
    }

    internal func submitTx(
        hash: String,
        selector: Selector,
        version: String,
        input: MintTransactionInput
    ) async throws -> ResponseSubmitTxMint {
        try await call(
            endpoint: network.lightNode,
            method: "ren_submitTx",
            params: ["tx": ParamsSubmitMint(
                hash: hash,
                selector: selector.toString(),
                version: version,
                in: .init(
                    t: .init(),
                    v: input
                )
            )],
            log: true
        )
    }
    
    func selectPublicKey(mintTokenSymbol: String) async throws -> Data? {
        let blockState = try await queryBlockState()
        return Data(base64urlEncoded: blockState.publicKey(mintTokenSymbol: mintTokenSymbol) ?? "")
    }
    
    func getTransactionFee(mintTokenSymbol: String) async throws -> UInt64 {
        // TODO: - Remove later: Support other tokens
        if mintTokenSymbol != "BTC" {
            throw RenVMError("Unsupported token")
        }
        
        let blockState = try await queryBlockState(log: true)
        
        guard let gasLimit = UInt64(blockState.state.v.btc.gasLimit),
              let gasCap = UInt64(blockState.state.v.btc.gasCap)
        else {throw RenVMError("Could not calculate transaction fee")}
        return gasLimit * gasCap
    }
}

public struct RpcClient: RenVMRpcClientType {
    public init(network: Network) {
        self.network = network
    }
    
    public let network: Network
    
    public func call<T>(endpoint: String, method: String, params: Encodable, log: Bool) async throws -> T where T : Decodable {
        guard let endpoint = URL(string: endpoint) else {
            throw RenVMError.invalidEndpoint
        }
        
        // prepare params
        let params = EncodableWrapper.init(wrapped:params)
        
        // Log
        if log {
            Logger.log(event: .request, message: "renBTC event \(method) \(params.jsonString ?? "")")
        }
        
        // prepare urlRequest
        let body = Body(method: method, params: params)
        
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpBody = try JSONEncoder().encode(body)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // request
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        let isValidStatusCode = (200..<300).contains(statusCode)
        
        if log {
            Logger.log(event: .response, message: String(data: data, encoding: .utf8) ?? "")
        }
        
        let res = try JSONDecoder().decode(Response<T>.self, from: data)
        
        if isValidStatusCode, let result = res.result {
            return result
        }
        
        throw res.error ?? .unknown
    }
    
    public func getIncomingTransactions(address: String) async throws -> [LockAndMint.IncomingTransaction] {
        guard let url = URL(string: "https://blockstream.info/testnet/api/address/\(address)/utxo")
        else {
            throw RenVMError.invalidEndpoint
        }
        Logger.log(event: .request, message: "https://blockstream.info/testnet/api/address/\(address)/utxo")
        let (data, _) = try await URLSession.shared.data(for: url)
        Logger.log(event: .response, message: String(data: data, encoding: .utf8) ?? "")
        return try JSONDecoder().decode([LockAndMint.IncomingTransaction].self, from: data)
    }
    
    struct Body: Encodable {
        let id = 1
        let jsonrpc = "2.0"
        let method: String
        let params: EncodableWrapper
    }
    
    struct EncodableWrapper: Encodable {
        let wrapped: Encodable
        
        public func encode(to encoder: Encoder) throws {
            try self.wrapped.encode(to: encoder)
        }
    }
    
    struct Response<T: Decodable>: Decodable {
        public let jsonrpc: String
        public let id: Int?
        public let result: T?
        public let error: RenVMError?
        public let method: String?
    }
}

extension Encodable {
    var jsonString: String? {
        guard let data = try? JSONEncoder().encode(self) else {return nil}
        return String(data: data, encoding: .utf8)
    }
}

@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
@available(macOS, deprecated: 12.0, message: "Use the built-in API instead")
extension URLSession {
    func data(for url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
    
    func data(for urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }

}

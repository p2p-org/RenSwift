import Foundation
import XCTest
import RenVMSwift

class RPCClientTests: XCTestCase {
    func testQueryBlockState() async throws {
        let rpcClient = RpcClient(network: .testnet)
        let blockState = try await rpcClient.queryBlockState()
        XCTAssertNotNil(blockState)
    }
    
    func testQueryConfig() async throws {
        let rpcClient = RpcClient(network: .testnet)
        let queryConfig = try await rpcClient.queryConfig()
        XCTAssertNotNil(queryConfig)
    }
    
    func testEstimateTransactionFee() async throws {
        let rpcClient = RpcClient(network: .mainnet)
        let result = try await rpcClient.estimateTransactionFee(log: true)
        print(result)
    }
}

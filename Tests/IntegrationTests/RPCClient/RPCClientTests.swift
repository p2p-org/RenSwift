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
    
    func testGetBlockStreamInfo() async throws {
        let rpcClient = RpcClient(network: .testnet)
        let result = try await rpcClient.getIncomingTransactions(address: "2N5crcCGWhn1LUkPpV2ttDKupUncAcXJ4yM")
        print(result)
    }
    
    func testEstimateTransactionFee() async throws {
        let rpcClient = RpcClient(network: .mainnet)
        let result = try await rpcClient.estimateTransactionFee(log: true)
        print(result)
    }
}

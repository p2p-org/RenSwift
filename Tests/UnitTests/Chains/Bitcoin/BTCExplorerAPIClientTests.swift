import Foundation
import XCTest
@testable import RenVMSwift

final class BTCExplorerAPIClientTests: XCTestCase {
    let apiClient = BTCExplorerAPIClient(network: .testnet)
    
    func testDecodingUnconfirmedIncommingTransactions() async throws {
        let string = #"[{"txid":"54a0696c91d2704f2d1d5075178bd9530d290c70ab6cd8df7bc1088c94f711b9","vout":0,"status":{"confirmed":false},"value":395008}]"#
        let blockstreamResponse = try JSONDecoder().decode([BlockstreamIncomingTransaction].self, from: string.data(using: .utf8)!)
        let incommingTransaction = blockstreamResponse[0].mapToExplorerAPIIncomingTransaction()
        XCTAssertEqual(incommingTransaction.id, "54a0696c91d2704f2d1d5075178bd9530d290c70ab6cd8df7bc1088c94f711b9")
        XCTAssertEqual(incommingTransaction.vout, 0)
        XCTAssertEqual(incommingTransaction.confirmations, 0)
        XCTAssertEqual(incommingTransaction.isConfirmed, false)
        XCTAssertEqual(incommingTransaction.value, 395008)
        XCTAssertEqual(incommingTransaction.blockTime, nil)
    }
    
    func testDecodingConfirmedIncommingTransactions() async throws {
        let string = #"[{"txid":"54a0696c91d2704f2d1d5075178bd9530d290c70ab6cd8df7bc1088c94f711b9","vout":0,"status":{"confirmed":true,"block_height":2406492,"block_hash":"000000000000a00c78c242852a4f3f94e2c2047f36e4e1ad200e11d8ebe1108d","block_time":1668574336},"value":395008}]"#
        let blockstreamResponse = try JSONDecoder().decode([BlockstreamIncomingTransaction].self, from: string.data(using: .utf8)!)
        let incommingTransaction = blockstreamResponse[0].mapToExplorerAPIIncomingTransaction()
        XCTAssertEqual(incommingTransaction.id, "54a0696c91d2704f2d1d5075178bd9530d290c70ab6cd8df7bc1088c94f711b9")
        XCTAssertEqual(incommingTransaction.vout, 0)
        XCTAssertEqual(incommingTransaction.confirmations, 0)
        XCTAssertEqual(incommingTransaction.isConfirmed, true)
        XCTAssertEqual(incommingTransaction.value, 395008)
        XCTAssertEqual(incommingTransaction.blockTime, 1668574336)
    }
}

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
    
    func testDecodingTransactionInfo() async throws {
        let string = #"{"txid":"efb6659d27c1f8cd4c0964e8abbf7921b53570b7680453226a981b443fd539b4","version":1,"locktime":0,"vin":[{"txid":"74c817f4cebc3cc1dcc87c2163f437a48f83b140600a3e77fbacf0fc1ae58fee","vout":1,"prevout":{"scriptpubkey":"00144abcb1b8346829f0e86e4197eee5a19b4161b086","scriptpubkey_asm":"OP_0 OP_PUSHBYTES_20 4abcb1b8346829f0e86e4197eee5a19b4161b086","scriptpubkey_type":"v0_p2wpkh","scriptpubkey_address":"bc1qf27trwp5dq5lp6rwgxt7aedpndqkrvyx7rtfz5","value":52454},"scriptsig":"","scriptsig_asm":"","witness":["3044022050cd734aa61cd90fb138fd7be0e44cb8b4f54e461bb985244ca0aab02d3b862202204afd25dd3a238cabed4c8743d6d626b8d022c0553bc04475c4df2963be19532101","03d26eb49971ed89cbf0a6da840675f8c26cfb863a8cbdbd0734cee278831c45b7"],"is_coinbase":false,"sequence":0}],"vout":[{"scriptpubkey":"a9149663e156848462a4e1c9a254a1cf6940bbe5faba87","scriptpubkey_asm":"OP_HASH160 OP_PUSHBYTES_20 9663e156848462a4e1c9a254a1cf6940bbe5faba OP_EQUAL","scriptpubkey_type":"p2sh","scriptpubkey_address":"3FQCw7oaNiterPwM5wheiTaKVaDWPbHgKw","value":31000},{"scriptpubkey":"00144abcb1b8346829f0e86e4197eee5a19b4161b086","scriptpubkey_asm":"OP_0 OP_PUSHBYTES_20 4abcb1b8346829f0e86e4197eee5a19b4161b086","scriptpubkey_type":"v0_p2wpkh","scriptpubkey_address":"bc1qf27trwp5dq5lp6rwgxt7aedpndqkrvyx7rtfz5","value":18188}],"size":223,"weight":565,"fee":3266,"status":{"confirmed":true,"block_height":763239,"block_hash":"00000000000000000004588499880a60c842fe47dbd9e433bec9629c3c97ced5","block_time":1668494519}}"#
        let blockstreamTransaction = try JSONDecoder().decode(BlockstreamTransaction.self, from: string.data(using: .utf8)!)
        let transaction = blockstreamTransaction.mapToExplorerAPITransaction()
    }
}

import Foundation
import XCTest
@testable import RenVMSwift

class RPCClientTests: XCTestCase {
    func testEncodeBody() throws {
        let input = MintTransactionInput(
            txid: "YtU3AP9wspScgOI6kgDr1gp49AbS52Mio7Q8JltutDJhgGSz3qkM20Csti1PRGpsJUwYHuqeWBNY_ySoUo_CCw",
            txindex: "0",
            ghash: "Bde-qbf54lElW4RIPc6GkbBkZ0muCAiIL1CEe5rB1Y8",
            gpubkey: "",
            nhash: "Y_dfWQXxRLYMBs8T0S7SVjeh4hdTPzIDpxXUfBJRK2k",
            nonce: "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABU",
            payload: "",
            phash: "xdJGAYb3IzySfn2y3McDwOUAtlPKgic7e_rYBF2FpHA",
            to: "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt",
            amount: "10000"
        )
        
        let hash = "nrRusEWs3bn619zTGc1937EakvCGvjbt5gYr4L2PL_M"
        let selector = Selector(mintTokenSymbol: "BTC", chainName: "Solana", direction: .from)
        let version = "1"
        
        let tx = ParamsSubmitMint(
            hash: hash,
            selector: selector.toString(),
            version: version,
            in: .init(
                t: .init(),
                v: input
            )
        )
        
        let body = RpcClient.Body(
            method: "ren_submitTx",
            params: .init(wrapped: ["tx": tx])
        )
        
        XCTAssertEqual(body.jsonString, #"{"id":1,"jsonrpc":"2.0","method":"ren_submitTx","params":{"tx":{"hash":"nrRusEWs3bn619zTGc1937EakvCGvjbt5gYr4L2PL_M","selector":"BTC\/fromSolana","in":{"t":{"struct":[{"txid":"bytes"},{"txindex":"u32"},{"amount":"u256"},{"payload":"bytes"},{"phash":"bytes32"},{"to":"string"},{"nonce":"bytes32"},{"nhash":"bytes32"},{"gpubkey":"bytes"},{"ghash":"bytes32"}]},"v":{"txindex":"0","txid":"YtU3AP9wspScgOI6kgDr1gp49AbS52Mio7Q8JltutDJhgGSz3qkM20Csti1PRGpsJUwYHuqeWBNY_ySoUo_CCw","ghash":"Bde-qbf54lElW4RIPc6GkbBkZ0muCAiIL1CEe5rB1Y8","amount":"10000","nhash":"Y_dfWQXxRLYMBs8T0S7SVjeh4hdTPzIDpxXUfBJRK2k","payload":"","phash":"xdJGAYb3IzySfn2y3McDwOUAtlPKgic7e_rYBF2FpHA","to":"tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt","gpubkey":"","nonce":"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABU"}},"version":"1"}}}"#)
    }
    
    func testRenQueryTx() throws {
        let responseString = #"{"tx":{"hash":"JYdgD8f3kqMhX2akoAaZxp-mdYpRCGAh1xe5jxsKqFg","version":"1","selector":"BTC/toSolana","in":{"t":{"struct":[{"txid":"bytes"},{"txindex":"u32"},{"amount":"u256"},{"payload":"bytes"},{"phash":"bytes32"},{"to":"string"},{"nonce":"bytes32"},{"nhash":"bytes32"},{"gpubkey":"bytes"},{"ghash":"bytes32"}]},"v":{"amount":"20000","ghash":"N4cfn-dfnf_VV154XSTG7UYZK13lgQsCSqQ00LUx24A","gpubkey":"Aw3WX32ykguyKZEuP0IT3RUOX5csm3PpvnFNhEVhrDVc","nhash":"LrJ-fivBAZJ9gt5XA4N0sxS_bnCPxxHg9VrdYk8lEmE","nonce":"ICAgICAgICAgICAgICAgICAgICAgICAgICAgIDQ5Yzc","payload":"","phash":"xdJGAYb3IzySfn2y3McDwOUAtlPKgic7e_rYBF2FpHA","to":"61WYW2uZezPuxJAFgw7vvhXUEMNq8SZJEjYWJpTc37bP","txid":"wyxScxVDO1L4mlVZbEhwqS-nILTI0qOT_pjOEmjr0OY","txindex":"0"}},"out":{"t":{"struct":[]},"v":{}}},"txStatus":"confirming"}"#
        
        XCTAssertNoThrow(try JSONDecoder().decode(ResponseQueryTxMint.self, from: responseString.data(using: .utf8)!))
        
    }
    
    func testGetBlockStreamInfos() throws {
        let data = #"[{"txid":"ff6239a413bc01b810d4e09d0d71ae5f8b13f9f3425e463ae09407553c9b2bc8","vout":0,"status":{"confirmed":true,"block_height":2226413,"block_hash":"00000000000000301d4282a8622c3227cf4a4cc128c74ac64a534142f705a9a9","block_time":1653022019},"value":72000},{"txid":"e79be10753ab29efad52459b0ae9bff8344bfa26f301b67822e6af0d70154686","vout":1,"status":{"confirmed":false},"value":70000}]"#
            .data(using: .utf8)!
        let streamInfos = try JSONDecoder().decode([LockAndMint.IncomingTransaction].self, from: data)
        XCTAssertEqual(streamInfos.count, 2)
        XCTAssertEqual(streamInfos[0], .init(
            txid: "ff6239a413bc01b810d4e09d0d71ae5f8b13f9f3425e463ae09407553c9b2bc8",
            vout: 0,
            status: .init(
                confirmed: true,
                blockHeight: 2226413,
                blockHash: "00000000000000301d4282a8622c3227cf4a4cc128c74ac64a534142f705a9a9",
                blockTime: 1653022019
            ),
            value: 72000
        ))
        XCTAssertEqual(streamInfos[1], .init(
            txid: "e79be10753ab29efad52459b0ae9bff8344bfa26f301b67822e6af0d70154686",
            vout: 1,
            status: .init(
                confirmed: false
            ),
            value: 70000
        ))
    }
}

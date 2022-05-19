import Foundation
import XCTest

class BurnAndReleaseTests: XCTestCase {
    //    override var endpoint: APIEndPoint {
    //        .init(address: "https://api.devnet.solana.com", network: .devnet)
    //    }
    //
    //    override var overridingAccount: String? {
    //        "matter outer client aspect pear cigar caution robust easily merge dwarf wide short sail unusual indicate roast giraffe clay meat crowd exile curious vibrant"
    //    }
    
    
    func testBurnAndRelease() async throws {
        let rpcClient = RpcClient(network: .testnet)

        let solanaChain = try await SolanaChain.load(client: rpcClient, solanaClient: solanaSDK)

        let recipient = "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt"

        let amount = "1000"

        let burnAndRelease = BurnAndRelease(
            rpcClient: rpcClient,
            chain: solanaChain,
            mintTokenSymbol: "BTC",
            version: "1",
            burnTo: "Bitcoin"
        )

//        let detail = try burnAndRelease.submitBurnTransaction(
//            account: account.publicKey.data,
//            amount: amount,
//            recipient: recipient,
//            signer: account.secretKey
//        ).toBlocking().first()!

        let detail: BurnAndRelease.BurnDetails = .init(
            confirmedSignature: "5Dmpba9yiJSyGUejRveSz1aS463Qj1s3oeV1JT4VKmrPgQsKFyikArLuFSihBGsG9yYybEKkawFFAnx7pajLtE1K",
            nonce: 56,
            recipient: recipient,
            amount: amount
        )
//
        let burnState = try burnAndRelease.getBurnState(burnDetails: detail)

        let tx = try burnAndRelease.release(state: burnState, details: detail).toBlocking().first()

    }
}

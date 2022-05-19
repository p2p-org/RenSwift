import Foundation
import XCTest
import RenVMSwift
import SolanaSwift

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
        let solanaAPIClient = JSONRPCAPIClient(
            endpoint: .init(
                address: "https://api.mainnet-beta.solana.com",
                network: .mainnetBeta
            )
        )

        let solanaChain = try await SolanaChain.load(
            client: rpcClient,
            apiClient: solanaAPIClient,
            blockchainClient: BlockchainClient(apiClient: solanaAPIClient)
        )

        let account = try await Account(phrase: "matter outer client aspect pear cigar caution robust easily merge dwarf wide short sail unusual indicate roast giraffe clay meat crowd exile curious vibrant".components(separatedBy: " "), network: .testnet)
        let recipient = "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt"
        let amount = "1000"

        let burnAndRelease = BurnAndRelease(
            rpcClient: rpcClient,
            chain: solanaChain,
            mintTokenSymbol: "BTC",
            version: "1",
            burnTo: "Bitcoin"
        )

        let detail = try await burnAndRelease.submitBurnTransaction(
            account: account.publicKey.data,
            amount: amount,
            recipient: recipient,
            signer: account.secretKey
        )
        
        try await solanaAPIClient.waitForConfirmation(signature: detail.confirmedSignature, ignoreStatus: true)
        
        let burnState = try burnAndRelease.getBurnState(burnDetails: detail)

        let tx = try await burnAndRelease.release(state: burnState, details: detail)
        
        print(tx)
    }
}

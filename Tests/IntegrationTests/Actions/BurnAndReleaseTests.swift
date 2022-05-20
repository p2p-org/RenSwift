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
        let renNetwork: RenVMSwift.Network = .devnet
        let solanaNetwork: SolanaSwift.Network = .testnet
        let solanaURL = "https://api.testnet.solana.com"
        
        let endpoint = APIEndPoint(
            address: solanaURL,
            network: solanaNetwork
        )
        
        let rpcClient = RpcClient(network: renNetwork)
        let solanaAPIClient = JSONRPCAPIClient(endpoint: endpoint)
        let solanaBlockchainClient = BlockchainClient(apiClient: solanaAPIClient)

        let solanaChain = try await SolanaChain.load(
            client: rpcClient,
            apiClient: solanaAPIClient,
            blockchainClient: solanaBlockchainClient
        )

        let account = try await Account(
            phrase: "matter outer client aspect pear cigar caution robust easily merge dwarf wide short sail unusual indicate roast giraffe clay meat crowd exile curious vibrant".components(separatedBy: " "),
            network: solanaNetwork
        )
        let recipient = "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt"
        let amount = 0.0001.toLamport(decimals: 6) // 0.0001 renBTC

        let burnAndRelease = BurnAndRelease(
            rpcClient: rpcClient,
            chain: solanaChain,
            mintTokenSymbol: "BTC",
            version: "1",
            burnTo: "Bitcoin"
        )

        let detail = try await burnAndRelease.submitBurnTransaction(
            account: account.publicKey.data,
            amount: String(amount),
            recipient: recipient,
            signer: account.secretKey
        )
        
        try await solanaAPIClient.waitForConfirmation(signature: detail.confirmedSignature, ignoreStatus: true)
        
        let burnState = try burnAndRelease.getBurnState(burnDetails: detail)

        let tx = try await burnAndRelease.release(state: burnState, details: detail)
        
        print(tx)
    }
}

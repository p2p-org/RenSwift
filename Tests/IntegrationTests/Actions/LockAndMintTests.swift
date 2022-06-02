import Foundation
import XCTest
import SolanaSwift
import RenVMSwift
import Task_retrying

class LockAndMintTests: XCTestCase {
    let solanaNetwork: SolanaSwift.Network = .devnet
    let renNetwork: RenVMSwift.Network = .testnet
    let solanaURL = "https://api.devnet.solana.com"
    
    var account: Account!
    var renRPCClient: RpcClient!
    var solanaRPCClient: JSONRPCAPIClient!
    var solanaBlockchainClient: BlockchainClient!
    
    override func setUp() async throws {
        account = try await Account(
            phrase: "matter outer client aspect pear cigar caution robust easily merge dwarf wide short sail unusual indicate roast giraffe clay meat crowd exile curious vibrant".components(separatedBy: " "),
            network: solanaNetwork
        )
        renRPCClient = .init(network: renNetwork)
        solanaRPCClient = .init(endpoint: .init(address: solanaURL, network: solanaNetwork))
        solanaBlockchainClient = .init(apiClient: solanaRPCClient)
    }
    
    override func tearDown() async throws {
        account = nil
        renRPCClient = nil
        solanaRPCClient = nil
        solanaBlockchainClient = nil
    }
    
    func testLockAndMint() async throws {
        let createdAt = Date(timeIntervalSinceReferenceDate: 674714392.613203)
        let calendar = Calendar.current
        let endAt = calendar.date(byAdding: .year, value: 3, to: createdAt)
        
        // Create session
        let session = try Session(createdAt: createdAt, endAt: endAt)
        
        // Initialize service
        let lockAndMint = try LockAndMint(
            rpcClient: RpcClient(network: renNetwork),
            chain: try await SolanaChain.load(
                client: renRPCClient,
                apiClient: solanaRPCClient,
                blockchainClient: solanaBlockchainClient
            ),
            mintTokenSymbol: "BTC",
            version: "1",
            destinationAddress: account.publicKey.data,
            session: session
        )
        
        // Get gateway address
        let response = try await lockAndMint.generateGatewayAddress()
        let address = Base58.encode(response.gatewayAddress.bytes)
        XCTAssertEqual(address, "2N5crcCGWhn1LUkPpV2ttDKupUncAcXJ4yM")
        
        // Get stream infos, retry until a tx is confirmed
        let streamInfos = try await Task<[IncomingTransaction], Error>.retrying(
            where: { error in
                (error as? TestError) == .noStreamInfo
            },
            maxRetryCount: .max,
            retryDelay: 5
        ) {
            let streamInfos = try? await self.renRPCClient.getIncomingTransactions(address: address)
            
            guard let streamInfos = streamInfos,
                  !streamInfos.isEmpty,
                  streamInfos.contains(where: {$0.status.confirmed})
            else {
                throw TestError.noStreamInfo
            }
            return streamInfos
        }.value
        
        // Get confirmed one
        let tx = streamInfos.first(where: {$0.status.confirmed})!
        
        let state = try lockAndMint.getDepositState(
            transactionHash: tx.txid,
            txIndex: String(tx.vout),
            amount: String(tx.value),
            sendTo: response.sendTo,
            gHash: response.gHash,
            gPubkey: response.gPubkey
        )
        
        // Submit mint transaction
        let tx = try await lockAndMint.submitMintTransaction(state: state)
        
        print("submitted tx: \(tx)")
        
        let result = try await Task<(amountOut: String?, signature: String), Error>.retrying(
            where: { error in
                (error as? RenVMError) == .paramsMissing
            },
            maxRetryCount: .max,
            retryDelay: 5
        ) {
            try await lockAndMint.mint(state: state, signer: self.account.secretKey)
        }.value

        print(result)
    }
}

private enum TestError: String, Error, Equatable {
    case noStreamInfo
}

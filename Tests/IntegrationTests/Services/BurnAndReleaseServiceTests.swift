//
//  BurnAndReleaseServiceTests.swift
//  
//
//  Created by Chung Tran on 01/06/2022.
//

import XCTest
import SolanaSwift
import RenVMSwift

class BurnAndReleaseServiceTests: XCTestCase {
    var service: BurnAndReleaseService!
    
    override func setUp() async throws {
        service = BurnAndReleaseServiceImpl(
            rpcClient: renRPCClient,
            chainProvider: SolanaChainProvider(),
            destinationChain: .bitcoin,
            persistentStore: PersistentStore(),
            version: "1"
        )
    }
    
    override func tearDown() async throws {
        service = nil
    }
    
    func testBurnAndReleaseService() async throws {
        service.resume()
        
        let tx = try await service.burnAndRelease(recipient: "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt", amount: 0.0001.toLamport(decimals: 8)) // 0.0001 renBTC
        print(tx)
    }
    
}

fileprivate let renNetwork: RenVMSwift.Network = .testnet
fileprivate let solanaNetwork: SolanaSwift.Network = .devnet
fileprivate let solanaURL = "https://api.devnet.solana.com"
fileprivate let renRPCClient = RpcClient(network: renNetwork)
fileprivate let endpoint = APIEndPoint(
    address: solanaURL,
    network: solanaNetwork
)
fileprivate let solanaAPIClient = JSONRPCAPIClient(endpoint: endpoint)

class SolanaChainProvider: ChainProvider {
    func getAccount() async throws -> (publicKey: Data, secret: Data?) {
        let account = try await Account(
            phrase: "matter outer client aspect pear cigar caution robust easily merge dwarf wide short sail unusual indicate roast giraffe clay meat crowd exile curious vibrant".components(separatedBy: " "),
            network: solanaNetwork
        )
        return (publicKey: account.publicKey.data, secret: account.secretKey)
    }
    
    func load() async throws -> RenVMChainType {
        try await SolanaChain.load(
            client: renRPCClient,
            apiClient: solanaAPIClient,
            blockchainClient: BlockchainClient(apiClient: solanaAPIClient)
        )
    }
    
    func convertPublicKeyDataToString(_ publicKey: Data) throws -> String {
        try PublicKey(data: publicKey).base58EncodedString
    }
}

class PersistentStore: BurnAndReleasePersistentStore {
    private var txs = [BurnAndRelease.BurnDetails]()
    
    func getNonReleasedTransactions() -> [BurnAndRelease.BurnDetails] {
        txs
    }
    
    func persistNonReleasedTransactions(_ transaction: BurnAndRelease.BurnDetails) {
        txs.append(transaction)
    }
    
    func markAsReleased(_ transaction: BurnAndRelease.BurnDetails) {
        txs.removeAll(where: {$0.confirmedSignature == transaction.confirmedSignature})
    }
}

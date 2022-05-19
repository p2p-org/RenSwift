//
//  RenVMBurnAndReleaseTests.swift
//  SolanaSwift_Tests
//
//  Created by Chung Tran on 14/09/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
@testable import SolanaSwift
@testable import RenVMSwift

class RenVMBurnAndReleaseTests: XCTestCase {
//    override var endpoint: APIEndPoint {
//        .init(address: "https://api.devnet.solana.com", network: .devnet)
//    }
//
//    override var overridingAccount: String? {
//        "matter outer client aspect pear cigar caution robust easily merge dwarf wide short sail unusual indicate roast giraffe clay meat crowd exile curious vibrant"
//    }
    
    func testBurnState() async throws {
        let burnAndRelease = BurnAndRelease(
            rpcClient: Mock.rpcClient,
            chain: try await Mock.solanaChain(),
            mintTokenSymbol: "BTC",
            version: "1",
            burnTo: "Bitcoin"
        )
        
        let burnDetails = BurnAndRelease.BurnDetails(
            confirmedSignature: "2kNe8duPRcE9xxKLLVP92e9TBH5WvmVVWQJ18gEjqhgxsrKtBEBVfeXNFz5Un3yEEQJZkxY2ysQR4dGQaytnDM1i",
            nonce: 35,
            recipient: "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt",
            amount: "1000"
        )
        
        let burnState = try burnAndRelease.getBurnState(burnDetails: burnDetails)
        
        XCTAssertEqual(burnState.txHash, "I_HJMksqVC5_-0G9FE_z8AORRDMoxl1vZbSGEc2VfJ4")
    }
    
//    func testBurnAndRelease() throws {
//        let rpcClient = RpcClient(network: .testnet)
//        
//        let solanaChain = try SolanaChain.load(client: rpcClient, solanaClient: solanaSDK).toBlocking().first()!
//        
//        let recipient = "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt"
//        
//        let amount = "1000"
//        
//        let burnAndRelease = BurnAndRelease(
//            rpcClient: rpcClient,
//            chain: solanaChain,
//            mintTokenSymbol: "BTC",
//            version: "1",
//            burnTo: "Bitcoin"
//        )
//        
////        let detail = try burnAndRelease.submitBurnTransaction(
////            account: account.publicKey.data,
////            amount: amount,
////            recipient: recipient,
////            signer: account.secretKey
////        ).toBlocking().first()!
//        
//        let detail: BurnAndRelease.BurnDetails = .init(
//            confirmedSignature: "5Dmpba9yiJSyGUejRveSz1aS463Qj1s3oeV1JT4VKmrPgQsKFyikArLuFSihBGsG9yYybEKkawFFAnx7pajLtE1K",
//            nonce: 56,
//            recipient: recipient,
//            amount: amount
//        )
////
//        let burnState = try burnAndRelease.getBurnState(burnDetails: detail)
//
//        let tx = try burnAndRelease.release(state: burnState, details: detail).toBlocking().first()
//        
//    }
}

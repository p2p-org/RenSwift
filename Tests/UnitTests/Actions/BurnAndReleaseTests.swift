import Foundation
import XCTest
@testable import SolanaSwift
@testable import RenVMSwift

class BurnAndReleaseTests: XCTestCase {
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
}

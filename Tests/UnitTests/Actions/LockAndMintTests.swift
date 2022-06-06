import XCTest
@testable import SolanaSwift
@testable import RenVMSwift

class LockAndMintTests: XCTestCase {
    let destinationAddress: PublicKey = "3h1zGmCwsRJnVk5BuRNMLsPaQu1y2aqXqXDWYCgrp5UG"
    
    func testSession() throws {
        let session = try createSession(sessionDays: 18870)
        XCTAssertEqual(Calendar.current.date(byAdding: .hour, value: 36, to: session.createdAt), session.endAt)
        XCTAssertEqual(session.nonce, "2020202020202020202020202020202020202020202020202020202034396236")
    }
    
    func testGenerateGatewayAddress() async throws {
        let session = try createSession(sessionDays: 18870)
        
        let lockAndMint = try LockAndMint(
            rpcClient: Mock.rpcClient,
            chain: try await Mock.solanaChain(),
            mintTokenSymbol: "BTC",
            version: "1",
            destinationAddress: destinationAddress.data,
            session: session
        )
        let response = try await lockAndMint.generateGatewayAddress()
        XCTAssertEqual(Base58.encode(response.gatewayAddress.bytes), "2NC451uvR7AD5hvWNLQiYoqwQQfvQy2XB6U")
    }
    
    func testGetDepositState() async throws {
        let session = try createSession(sessionDays: 18874)
        
        let lockAndMint = try LockAndMint(
            rpcClient: Mock.rpcClient,
            chain: try await Mock.solanaChain(),
            mintTokenSymbol: "BTC",
            version: "1",
            destinationAddress: destinationAddress.data,
            session: session
        )
        let response = try await lockAndMint.generateGatewayAddress()
        XCTAssertEqual(Base58.encode(response.gatewayAddress.bytes), "2MyJ7zQxBCnwKuRNoE3UYD2cb9MDjdkacaF")
        let txHash = try lockAndMint.getDepositState(
            transactionHash: "01d32c22d721d7bf0cd944fc6e089b01f998e1e77db817373f2ee65e40e9462a",
            txIndex: "0",
            amount: "10000",
            sendTo: response.sendTo,
            gHash: response.gHash,
            gPubkey: response.gPubkey
        )
            .txHash
        XCTAssertEqual(txHash, "LLg3jxVXS4NEixjaBOUXocRqaK_Y0wk5HPshI1H3e6c")
    }
    
    private func createSession(sessionDays: Long) throws -> LockAndMint.Session {
        let interval = TimeInterval(sessionDays * 24 * 60 * 60)
        let createdAt = Date(timeIntervalSince1970: interval)
        return try LockAndMint.Session(createdAt: createdAt)
    }
}

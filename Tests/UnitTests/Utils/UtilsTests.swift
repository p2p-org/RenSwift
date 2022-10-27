import XCTest
@testable import SolanaSwift
@testable import RenVMSwift

class UtilsTests: XCTestCase {

    func testFixSignatureSimple() throws {
        let string = "fypvW39VUS6tB8basjmi3YsSn_GR7uLTw_lGcJhQYFcRVemsA1LkF8FQKH_1XJR-bQGP6AXsPbnmB1H8AvKBWgA"
        let data = try Data(base64urlEncoded: string)?.fixSignatureSimple()
        XCTAssertEqual("CDsK2CsmBnLqupzsv9EeDHwc5ZYQxXt9LKzpkmusasc5z2LdDiKHqnCXpiCZTEXDYZtP7JgY4Ur9fkAU5RWSwxrnn", Base58.encode(data!.bytes))
    }
    
    func testBTCAddressToBytes() throws {
        let bytes = try BurnAndRelease.addressToBytes(address: "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt")
        XCTAssertEqual("0x" + bytes.hexString, "0x00ff9da567e62f30ea8654fa1d5fbd47bef8e3be13")
    }
    
    func testLegacyBTCAddressToBytes() throws {
        let bytes = try BurnAndRelease.addressToBytes(address: "3NFurmHWtPr2YAkpRLkk33mrKjv4ofbmEn")
        XCTAssertEqual("0x" + bytes.hexString, "0x05e19b2df1e35c6dbabe144f0ef53ffa97ac4db025ce0f72ff")
    }
}

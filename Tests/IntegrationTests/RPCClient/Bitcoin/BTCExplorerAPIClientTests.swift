import Foundation
import XCTest
import RenVMSwift

final class BTCExplorerAPIClientTests: XCTestCase {
    let apiClient = BTCExplorerAPIClient(network: .testnet)
    
    func testGetIncommingTransactions() async throws {
        let response = try await apiClient.getIncommingTransactions(for: "2N5crcCGWhn1LUkPpV2ttDKupUncAcXJ4yM")
        XCTAssertNotNil(response)
    }
}

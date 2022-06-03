import XCTest
import SolanaSwift
import RenVMSwift

class LockAndMintServiceTests: XCTestCase {
    let persistentStore = UserDefaultLockAndMintServicePersistentStore(
        userDefaultKeyForSession: "userDefaultKeyForSession",
        userDefaultKeyForGatewayAddress: "userDefaultKeyForGatewayAddress",
        userDefaultKeyForProcessingTransactions: "userDefaultKeyForProcessingTransactions",
        showLog: true
    )
    var service: LockAndMintService!
    
    override func setUp() async throws {
        service = LockAndMintServiceImpl(
            persistentStore: persistentStore,
            chainProvider: SolanaChainProvider(),
            rpcClient: renRPCClient,
            mintToken: .bitcoin,
            version: "1",
            showLog: true
        )
    }
    
    override func tearDown() async throws {
        service = nil
    }
    
    func testLockAndMintService() async throws {
        if let session = await persistentStore.session,
           session.isValid
        {
            try await service.resume()
        } else {
            try await service.createSession(endAt: Date().addingTimeInterval(60*60*24*365*3)) // 3 years
        }
        
        let expectation = XCTestExpectation(description: "Your expectation")
        wait(for: [expectation], timeout: 9999999999999)
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

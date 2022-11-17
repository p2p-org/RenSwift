import XCTest
import SolanaSwift
import RenVMSwift
import Combine

class LockAndMintServiceTests: XCTestCase {
    let persistentStore = UserDefaultLockAndMintServicePersistentStore(
        userDefaultKeyForSession: "userDefaultKeyForSession",
        userDefaultKeyForGatewayAddress: "userDefaultKeyForGatewayAddress",
        userDefaultKeyForProcessingTransactions: "userDefaultKeyForProcessingTransactions",
        showLog: true
    )
    var service: LockAndMintService!
    var subscriptions = [AnyCancellable]()
    
    override func setUp() async throws {
        service = LockAndMintServiceImpl(
            persistentStore: persistentStore,
            destinationChainProvider: SolanaChainProvider(),
            sourceChainExplorerAPIClient: BTCExplorerAPIClient(network: renNetwork),
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
        // Observe state
        service.statePublisher
            .receive(on: RunLoop.main)
            .sink { state in
                print("service state: ", state)
            }
            .store(in: &subscriptions)
        
        // Resume session
        if let session = await persistentStore.session,
           session.isValid
        {
            try await service.resume()
        } else {
            try await service.createSession(endAt: Date().addingTimeInterval(60*60*24*365*3)) // 3 years
        }
        
        // check if operation block the main queue
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                print("Ping the ui thread")
            }
        }
        
        // wait for forever
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

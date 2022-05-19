//
//  DevnetRestAPITests.swift
//  p2p_walletTests
//
//  Created by Chung Tran on 10/28/20.
//

import XCTest
import SolanaSwift

class RestAPITests: XCTestCase {
    var endpoint: APIEndPoint {
        .init(
            address: "https://api.mainnet-beta.solana.com",
            network: .mainnetBeta
        )
    }
    var solanaSDK: SolanaSDK!
    var account: Account {solanaSDK.accountStorage.account!}
    
    var overridingAccount: String? {
        nil
    }

    override func setUpWithError() throws {
        let accountStorage = InMemoryAccountStorage()
        solanaSDK = SolanaSDK(endpoint: endpoint, accountStorage: accountStorage)
        let account = try Account(phrase: (overridingAccount ?? endpoint.network.testAccount).components(separatedBy: " "), network: endpoint.network)
        try accountStorage.save(account)
    }
}

extension Network {
    var testAccount: String {
        switch self {
        case .mainnetBeta:
            return "promote ignore inmate coast excess candy vanish erosion palm oxygen build powder"
        case .devnet:
            return "galaxy lend nose glow equip student way hockey step dismiss expect silent"
        default:
            fatalError("unsupported")
        }
    }
}

class InMemoryAccountStorage: SolanaSDKAccountStorage {
    private var _account: Account?
    func save(_ account: Account) throws {
        _account = account
    }
    var account: Account? {
        _account
    }
    func clear() {
        _account = nil
    }
}


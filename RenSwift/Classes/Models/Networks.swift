//
//  Networks.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

enum RenNetwork: String, CaseIterable {
    // MARK: - Variants
    case mainnet = "mainnet",
         testnet = "testnet",

         // Staging
         mainnetVDot3 = "mainnet-v0.3",
         testnetVDot3 = "testnet-v0.3",
         devnetVDot3 = "devnet-v0.3",
         localnet = "localnet"
    
    // MARK: - Getters
    private var lightnode: String {
        switch self {
        case .mainnet, .mainnetVDot3:
            return "https://lightnode-mainnet.herokuapp.com"
        case .localnet:
            return "http://localhost:5000"
        case .testnet, .testnetVDot3:
            return "https://lightnode-testnet.herokuapp.com"
        case .devnetVDot3:
            return "https://lightnode-devnet.herokuapp.com/"
        }
    }
    
    private var isTestNet: Bool {
        switch self {
        case .mainnet, .mainnetVDot3:
            return false
        default:
            return true
        }
    }
}



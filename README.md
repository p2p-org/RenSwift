# RenSwift

[![CI Status](https://img.shields.io/travis/p2p-org/RenSwift.svg?style=flat)](https://travis-ci.org/p2p-org/RenSwift)
[![Version](https://img.shields.io/cocoapods/v/RenSwift.svg?style=flat)](https://cocoapods.org/pods/RenSwift)
[![License](https://img.shields.io/cocoapods/l/RenSwift.svg?style=flat)](https://cocoapods.org/pods/RenSwift)
[![Platform](https://img.shields.io/cocoapods/p/RenSwift.svg?style=flat)](https://cocoapods.org/pods/RenSwift)

## How to use
### Sending
```swift
// define ChainProvider
class SolanaChainProvider: ChainProvider {
    func getAccount() async throws -> (publicKey: Data, secret: Data) {
        let account = // account in solana chain
        return (publicKey: account.publicKey.data, secret: account.secretKey)
    }
    
    func load() async throws -> RenVMChainType {
        try await SolanaChain.load(
            client: renRPCClient,
            apiClient: solanaAPIClient,
            blockchainClient: BlockchainClient(apiClient: solanaAPIClient)
        )
    }
}

// define persistentStore for re-release transaction in case of failure
class PersistentStore: BurnAndReleasePersistentStore {
    private var fileStore = SomeFileStore()
    
    func getNonReleasedTransactions() -> [BurnAndRelease.BurnDetails] {
        fileStore.getSavedTxs()
    }
    
    func persistNonReleasedTransactions(_ transaction: BurnAndRelease.BurnDetails) {
        fileStore.write(transaction)
    }
    
    func markAsReleased(_ transaction: BurnAndRelease.BurnDetails) {
        fileStore.removeAll(where: {$0.confirmedSignature == transaction.confirmedSignature})
    }
}

// create instance of service
let service = BurnAndReleaseServiceImpl(
    rpcClient: renRPCClient,
    chainProvider: SolanaChainProvider(),
    destinationChain: .bitcoin,
    persistentStore: PersistentStore(),
    version: "1"
)

// resume all failured transaction from last time
service.resume()

// burn and release
let tx = try await service.burnAndRelease(recipient: "tb1ql7w62elx9ucw4pj5lgw4l028hmuw80sndtntxt", amount: 0.0001.toLamport(decimals: 8)) // 0.0001 renBTC
print(tx)

```

## Requirements

## Installation

RenVMSwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'RenVMSwift', '~> 3.0.0'
```

## Author

Chung Tran, bigearsenal@gmail.com

## License

RenSwift is available under the MIT license. See the LICENSE file for more info.

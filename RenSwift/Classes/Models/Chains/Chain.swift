//
//  Chain.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation
import PromiseKit

protocol BurnPayloadConfig {
    var bytes: Bool? {get}
}

protocol ChainCommon: ChainStatic {
    /**
     * The name of the Chain.
     *
     * ```ts
     * bitcoin.name = "Bitcoin"
     * ```
     */
    var name: String {get}
    
    /**
     * The name of the Chain used the v0.2 RenVM nodes.
     *
     * ```ts
     * bitcoin.legacyName = "Btc"
     * ```
     */
    var legacyName: String? {get}
    
    /**
     * Should be set by `constructor` or `initialize`.
     */
    var renNetwork: RenNetwork? {get}
    
    // Class Initialization
    
    /**
     * `initialize` allows RenJS to pass in parameters after the user has
     * initialized the Chain. This allows the user to pass in network
     * parameters such as the network only once.
     *
     * If the Chain's constructor has an optional network parameter and the
     * user has explicitly initialized it, the Chain should ignore the
     * network passed in to `initialize`. This is to allow different network
     * combinations, such as working with testnet Bitcoin and a local Ethereum
     * chain - whereas the default `testnet` configuration would use testnet
     * Bitcoin and Ethereum's Kovan testnet.
     */
    static func fromRenNetwork(_ renNetwork: RenNetwork) -> Promise<Self>
    
    func withProvider<Provider>(_ provider: Provider) -> Promise<Self>
    
//    withProvider?: (...args: any[]) => SyncOrPromise<this>
    
    // Supported assets
    
    /**
     * `assetIsNative` should return true if the asset is native to the Chain.
     * Mint-chains should return `false` for assets that have been bridged to
     * it.
     *
     * ```ts
     * ethereum.assetIsNative = asset => asset === "ETH" ||
     * ```
     */
    func assetIsNative(_ asset: String) -> Promise<Bool>
    
    /**
     * `assetIsSupported` should return true if the the asset is native to the
     * chain or if the asset can be minted onto the chain.
     *
     * ```ts
     * ethereum.assetIsSupported = asset => asset === "ETH" || asset === "BTC" || ...
     * ```
     */
    func assetIsSupported(_ asset: String) -> Promise<Bool>
    
    /**
     * `assetDecimals` should return the number of decimals of the asset.
     *
     * If the asset is not supported, an error should be thrown.
     *
     * ```ts
     * bitcoin.assetDecimals = asset => {
     *     if (asset === "BTC") { return 8 }
     *     throw new Error(`Unsupported asset ${asset}.`)
     * }
     * ```
     */
    func assetDecimals(_ asset: String) -> Promise<Number>
    
    // Transaction helpers
    
    /**
     * `transactionID` should return a string that uniquely represents the
     * transaction.
     */
    func transactionID(_ transaction: Transaction) -> String
    
    /**
     * `transactionConfidence` should return a target and a current
     * confidence that the deposit is irreversible. For most chains, this will
     * be represented by the number of blocks that have passed.
     *
     * For example, a Bitcoin transaction with 2 confirmations will return
     * `{ current: 2, target: 6 }` on mainnet, where the target is currently 6
     * confirmations.
     *
     * @dev Must be compatible with the matching RenVM multichain LockChain.
     */
    func transactionConfidence(_ transaction: Transaction) -> Promise<(current: Number, target: Number)>
    
    func transactionRPCFormat(_ transaction: Transaction, v2: Bool?) -> (txid: TransactionID, txindex: String)
    
    func transactionRPCTxidFromID(transactionID: String, v2: Bool?) -> Data
    
    /**
     * `transactionIDFromRPCFormat` accepts a txid and txindex and returns the
     * transactionID as returned from `transactionID`.
     */
    func transactionIDFromRPCFormat(
        txid: TransactionID,
        txindex: String,
        reversed: Bool?
    ) -> String
    
    func transactionFromRPCFormat(
        txid: TransactionID,
        txindex: String,
        reversed: Bool?
    ) -> Promise<Transaction>
    /**
     * @deprecated Renamed to `transactionFromRPCFormat`.
     * Will be removed in 3.0.0.
     */
    func transactionFromID(
        txid: TransactionID,
        txindex: String,
        reversed: Bool?
    ) -> Promise<Transaction>
    
    func transactionRPCFormatExplorerLink(
        txid: TransactionID,
        txindex: String,
        reversed: Bool?,
        network: RenNetwork?,
        explorer: String?
    ) -> String?
}

/**
 * Chains should provide a set of static utilities.
 */
protocol ChainStatic {
    associatedtype Network
    associatedtype Transaction
    
    // Map from a RenVM network to the chain's network.
    func resolveChainNetwork(_ network: RenNetwork) -> Network
    
    /**
     * Return a boolean indicating whether the address is valid for the
     * chain's network.
     *
     * @param address
     * @param network
     */
    func addressIsValid(_ address: String, network: RenNetwork?) -> Bool
    
    /**
     * Return a boolean indicating whether the transaction is valid for the
     * chain's network.
     *
     * @param address
     * @param network
     */
    func transactionIsValid(_ transaction: Transaction, network: RenNetwork?) -> Bool
    
    /**
     * `addressExplorerLink` should return a URL that can be shown to a user
     * to access more information about an address.
     *
     * `explorer` can be provided to request a link to a different explorer.
     * It's up to the chain implementation to choose how to interpret this.
     */
    func addressExplorerLink(_ address: String, network: RenNetwork?, explorer: String?) -> String?
    
    /**
     * `transactionExplorerLink` should return a URL that can be shown to a user
     * to access more information about a transaction.
     *
     * `explorer` can be provided to request a link to a different explorer.
     * It's up to the chain implementation to choose how to interpret this.
     */
    func transactionExplorerLink(_ transaction: Transaction, network: RenNetwork?, explorer: String?) -> String?
}

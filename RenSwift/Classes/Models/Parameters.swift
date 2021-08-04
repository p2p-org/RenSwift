//
//  Parameters.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

typealias RenTokens = String

/**
 * The details required to create and/or submit a transaction to a chain.
 */
protocol ContractCall {
    /**
     * The address of the contract.
     */
    var sendTo: String {get}

    /**
     * The name of the function to be called on the contract.
     */
    var contractFn: String {get}

    /**
     * The parameters to be passed to the contract. They can only be defined
     * using Ethereum types currently.
     */
    var contractParams: EthArgs? {get}

    /**
     * Override chain-specific transaction configuration, such as gas/fees.
     */
    var txConfig: Any? {get} //?: unknown;
}

/**
 * The parameters required for both minting and burning.
 */
protocol TransferParamsCommon {
    /**
     * The asset being minted or burned - e.g. `"BTC"`.
     */
    var asset: String {get}

    /**
     * A RenVM transaction hash, which can be used to resume an existing mint
     * or burn.
     */
    var txHash: String? {get}

    /**
     * A LockAndMint's gateway address can be forced to be unique by providing a
     * 32-byte nonce.
     *
     * The nonce should be passed is as a 32-byte Buffer or a 32-byte hex
     * string, with or without a "0x" prefix.
     *
     * It defaults to 0 (32 empty bytes).
     *
     * @warning If the nonce is lost between detecting a deposit and
     * submitting it to RenVM, the deposit's funds can't be recovered.
     * A nonce should only be provided if it's guaranteed to be stored in
     * persistent storage before a deposit address is shown to the user.
     *
     * @example
     * ```
     * nonce: Buffer.from(new Array(32)),
     * ```
     *
     * @example
     * ```
     * // Use a nonce based on the number of days since epoch, in order to
     * // generate a new deposit address each day.
     * nonce: new BN(Math.floor(Date.now() / 8.64e7))
     *          .toArrayLike(Buffer, "be", 32),
     * ```
     *
     * @example
     * ```
     * // Provide a random 32-byte Buffer. It's important that this isn't lost.
     * nonce: RenJS.utils.randomNonce(),
     * ```
     */
    var nonce: Data? {get} //?: Buffer | String

    /**
     * Provide optional tags which can be used to look up transfers in the
     * lightnodes.
     */
    var tags: [String]? {get} // Currently, only one tag can be provided.

    /**
     * Details for submitting one or more transactions. The last one will be
     * used by the lockAndMint or burnAndRelease.
     * For minting, the last call's parameters will be augmented with the three
     * required parameters for minting - the amount, nHash and RenVM signature.
     * For burning, the last call must involve ren-assets being burnt.
     */
    var contractCalls: [ContractCall]? {get}
}

/**
 * The parameters for a cross-chain transfer onto Ethereum.
 */
protocol LockAndMintParams: TransferParamsCommon {
    /**
     * The chain that the asset is native to - e.g. `Bitcoin()` for bridging the
     * asset `"BTC"`.
     */
    var from: LockChainType {get}

    /**
     * The chain that the asset is being bridged to - e.g. `Ethereum(provider)`.
     */
    var to: MintChainType {get}
}

/**
 * BurnAndReleaseParams define the parameters for a cross-chain transfer away
 * from Ethereum.
 */
protocol BurnAndReleaseParams: TransferParamsCommon {
    associatedtype MintTransaction
    /**
     * The chain from which the ren-asset was burned - e.g. `Ethereum(provider)`.
     */
    var from: MintChainType {get}

    /**
     * The asset's native chain to which it's being returned - e.g. `Bitcoin()`
     * for the asset `"BTC"`.
     */
    var to: LockChainType {get}

    /**
     * The hash of the burn transaction on the MintChain.
     */
    var transaction: MintTransaction? {get}

    /**
     * The unique identifier of the burn emitted from the event on the MintChain.
     */
    var burnNonce: Nonce? {get}
}

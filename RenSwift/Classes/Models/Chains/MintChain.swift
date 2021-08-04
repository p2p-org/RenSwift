//
//  MintChain.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation
import PromiseKit

struct BurnDetails<Transaction> {
    var transaction: Transaction
    var amount: BigNumber
    var to: String
    var nonce: BigNumber
}

typealias OverwritableLockAndMintParams = TransferParamsCommon
//export type OverwritableLockAndMintParams = Omit<
//    Omit<Partial<LockAndMintParams>, "to">,
//    "from"
//>
typealias OverwritableBurnAndReleaseParams = TransferParamsCommon
//export type OverwritableBurnAndReleaseParams = Omit<
//    Omit<Partial<BurnAndReleaseParams>, "to">,
//    "from"
//>

protocol MintChain: ChainCommon {
    func resolveTokenGatewayContract(asset: String) -> Promise<String>

    /**
     * `submitMint` should take the completed mint transaction from RenVM and
     * submit its signature to the mint chain to finalize the mint.
     */
    func submitMint(
        asset: String,
        contractCalls: [ContractCall],
        mintTx: LockAndMintTransaction,
        eventEmitter: EventEmitter
    ) -> Promise<Transaction>

    /**
     * Finds a transaction by its nonce and optionally signature,
     * as used in Ethereum based chains
     */
    func findTransaction(
        asset: String,
        nHash: Data,
        sigHash: Data?
    ) -> Promise<Transaction?>

    /**
     * Finds a transaction by its details
     * as used in Solana
     */
    func findTransactionByDepositDetails(
        asset: String,
        sHash: Data,
        nHash: Data,
        pHash: Data,
        to: String,
        amount: String
    ) -> Promise<Transaction?>

    /**
     * Read a burn reference from an Ethereum transaction - or submit a
     * transaction first if the transaction details have been provided.
     */
    func findBurnTransaction(
        asset: String,

        // Once of the following should not be undefined.
        burn: (
            transaction: Transaction?,
            burnNonce: Nonce?,
            contractCalls: [ContractCall]?
        ),

        eventEmitter: EventEmitter,
        logger: Logger,
        networkDelay: Number
    ) -> Promise<BurnDetails<Transaction>>

    /**
     * Fetch the mint and burn fees for an asset.
     */
    func getFees(asset: String) -> Promise<(
        burn: Number,
        mint: Number
    )>

    /**
     * Fetch the addresses' balance of the asset's representation on the chain.
     */
    func getBalance(asset: String, address: Address) -> Promise<BigNumber>

    func getMintParams(
        asset: String
    ) -> Promise<TransferParamsCommon?>

    func getBurnParams(
        asset: String,
        burnPayload: String?
    ) -> Promise<TransferParamsCommon?>

    var burnPayloadConfig: BurnPayloadConfig? {get}
}

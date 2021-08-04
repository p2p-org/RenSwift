//
//  MintChain.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

struct BurnDetails<Transaction> {
    var transaction: Transaction
    var amount: BigNumber
    var to: String
    var nonce: BigNumber
}

export type OverwritableLockAndMintParams = Omit<
    Omit<Partial<LockAndMintParams>, "to">,
    "from"
>
export type OverwritableBurnAndReleaseParams = Omit<
    Omit<Partial<BurnAndReleaseParams>, "to">,
    "from"
>


export interface MintChain<
    Transaction = any,
    Address extends String | { address: String } = any,
    Network = any,
> extends ChainCommon<Transaction, Address, Network> {
    resolveTokenGatewayContract(asset: String) -> Promise<String>;

    /**
     * `submitMint` should take the completed mint transaction from RenVM and
     * submit its signature to the mint chain to finalize the mint.
     */
    func submitMint(
        asset: String,
        contractCalls: ContractCall[],
        mintTx: LockAndMintTransaction,
        eventEmitter: EventEmitter,
    ) -> Promise<Transaction>;

    /**
     * Finds a transaction by its nonce and optionally signature,
     * as used in Ethereum based chains
     */
    func findTransaction?(
        asset: String,
        nHash: Buffer,
        sigHash?: Buffer,
    ) -> Promise<Transaction?>;

    /**
     * Finds a transaction by its details
     * as used in Solana
     */
    func findTransactionByDepositDetails?(
        asset: String,
        sHash: Buffer,
        nHash: Buffer,
        pHash: Buffer,
        to: String,
        amount: String,
    ) -> Promise<Transaction?>;

    /**
     * Read a burn reference from an Ethereum transaction - or submit a
     * transaction first if the transaction details have been provided.
     */
    func findBurnTransaction(
        asset: String,

        // Once of the following should not be undefined.
        burn: {
            transaction?: Transaction;
            burnNonce?: Buffer | String | number;
            contractCalls?: ContractCall[];
        },

        eventEmitter: EventEmitter,
        logger: Logger,
        networkDelay?: number,
    ) -> Promise<BurnDetails<Transaction>>;

    /**
     * Fetch the mint and burn fees for an asset.
     */
    func getFees(asset: String): Promise<{
        burn: number;
        mint: number;
    }>;

    /**
     * Fetch the addresses' balance of the asset's representation on the chain.
     */
    func getBalance(asset: String, address: Address): Promise<BigNumber>;

    getMintParams?(
        asset: String,
    ) -> Promise<OverwritableLockAndMintParams?>;

    getBurnParams?(
        asset: String,
        burnPayload?: String,
    ) -> Promise<OverwritableBurnAndReleaseParams?>;

    burnPayloadConfig?: BurnPayloadConfig;
}

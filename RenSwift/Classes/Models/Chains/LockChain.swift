//
//  LockChain.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation
import PromiseKit

struct DepositCommon<Transaction> {
    var transaction: Transaction
    var amount: String
}

/**
 * LockChain is a chain with one or more native assets that can be locked in a
 * key controlled by RenVM to be moved onto a MintChain, and then released when
 * they are burnt from the MintChain.
 *
 * LockChains can extend other chain implementations using JavaScript's class
 * inheritance. For example, if a LockChain is a Bitcoin fork, it can extend the
 * Bitcoin LockChain and overwrite methods as necessary. See the ZCash and
 * BitcoinCash implementations for examples of this.
 */
protocol LockChainType {}

protocol LockChain: ChainCommon, LockChainType {
    /**
     * GetDeposits can track its progress using a `progress` value.
     */
    associatedtype GetDepositProgress
    typealias LockDeposit = DepositCommon<Transaction>
    
    // Deposits

    /**
     * `getDeposits` should return all deposits that have been made to the
     * provided address, confirmed or unconfirmed.
     * `getDeposits` will get called in a loop by LockAndMintObjects, but a
     * LockChain has the option of instead handling this itself by not
     * returning, and streaming deposits using the onDeposit method.
     */
    func getDeposits(
        asset: String,
        address: Address,
        // The chain can return back a value that represents its progress. For
        // example, Bitcoin returns back a single boolean in order to detect if
        // it's the first time deposits are being fetched, doing a more
        // extensive query for the first call.
        progress: GetDepositProgress?,
        onDeposit: (_ deposit: LockDeposit) -> Promise<Void>,
        // If a deposit is no longer valid, cancelDeposit should be called with
        // the same details. NOTE: Not implemented yet in RenJS.
        cancelDeposit: (_ deposit: LockDeposit) -> Promise<Void>,
        listenerCancelled: () -> Bool
    ) -> Promise<GetDepositProgress>

    // Encoding

    /**
     * `addressToBytes` should return the bytes representation of the address.
     *
     * @dev Must be compatible with the matching RenVM multichain LockChain's
     * `decodeAddress` method.
     */
    func addressToBytes(address: Address) -> Data

    /**
     * `bytesToAddress` should return the string representation of the address.
     *
     * @dev Must be compatible with the matching RenVM multichain LockChain's
     * `encodeAddress` method.
     */
    func bytesToAddress(bytes: Data) -> Address

    /**
     * @deprecated Renamed to addressToBytes.
     */
    func addressStringToBytes(address: String) -> Data

    func addressToString(address: Address) -> String

    // RenVM specific utils

    /**
     * `getGatewayAddress` should return the deposit address expected by RenVM
     * for the given asset and gateway hash (`gHash`). The public key is that of
     * the shard selected to handle the deposits.
     *
     * @dev Must be compatible with the matching RenVM multichain LockChain.
     */
    func getGatewayAddress(
        asset: String,
        publicKey: Data,
        gHash: Data
    ) -> Promise<Address>

    // Only chains supported by the legacy transaction format (BTC, ZEC & BCH)
    // need to support this. For now, other chains can return an empty string.
    func depositV1HashString(deposit: LockDeposit) -> String

    func burnPayload(
        burnPayloadConfig: BurnPayloadConfig?
    ) -> Promise<String?>
}

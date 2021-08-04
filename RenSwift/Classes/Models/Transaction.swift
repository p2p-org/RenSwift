//
//  Transaction.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

struct RenTransaction<Input, Output> {
    var version: Double?
    var hash: Base64String
    var txStatus: TxStatus
    var to: String
    var `in`: Input
    var out: Output?
}


// MARK: - LockAndMintTransaction
struct LockAndMintTransactionInput {
    var ref: String
    var to: String
    var amount: String
}

struct LockAndMintTransactionOutput {
    var phash: Data?
    var amount: String?
    var ghash: Data?
    var nhash: Data?
    var sighash: Data?
    var signature: Data?
    var revert: Data?
}

typealias LockAndMintTransaction = RenTransaction<LockAndMintTransactionInput, LockAndMintTransactionOutput>

// MARK: - BurnAndReleaseTransaction
struct BurnAndReleaseTransactionInput {
    var ref: String
    var to: String
    var amount: String
}
struct BurnAndReleaseTransactionOutput {
    struct Outpoint {
        var hash: Data
        var index: BigNumber
    }
    
    var amount: BigNumber
    var txid: Data?
    var outpoint: Outpoint?
    var revert: Data?
}

typealias BurnAndReleaseTransaction = RenTransaction<BurnAndReleaseTransactionInput, BurnAndReleaseTransactionOutput>

// MARK: - RenVMAssetFees

//export type RenVMAssetFees = {
//    [mintChain: string]: {
//        mint: number; // Minting fee basis points (10 = 0.1%)
//        burn: number; // Burning fee basis points (10 = 0.1%)
//    };
//} & {
//    lock: BigNumber; // Chain transaction fees for locking (in sats)
//    release: BigNumber; // Chain transaction fees for releasing (in sats)
//};
//
//export interface RenVMFees {
//    [asset: string]: RenVMAssetFees;
//}

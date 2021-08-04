//
//  OtherModels.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

typealias Base64String = String
typealias HexString = String

enum LockAndMintStatus: String {
    case Committed = "mint_committed",
         Deposited = "mint_deposited",
         Confirmed = "mint_confirmed",
         SubmittedToRenVM = "mint_submittedToRenVM",
         ReturnedFromRenVM = "mint_returnedFromRenVM",
         SubmittedToLockChain = "mint_submittedToLockChain",
         ConfirmedOnLockChain = "mint_confirmedOnLockChain",

         // Backwards compatibility
         SubmittedToEthereum = "mint_submittedToEthereum",
         ConfirmedOnEthereum = "mint_confirmedOnEthereum"
}

enum BurnAndReleaseStatus: String {
    case Committed = "burn_committed",
         SubmittedToLockChain = "burn_submittedToLockChain",
         ConfirmedOnLockChain = "burn_confirmedOnLockChain",
         SubmittedToRenVM = "burn_submittedToRenVM",
         ReturnedFromRenVM = "burn_returnedFromRenVM",
         NoBurnFound = "burn_noBurnFound",

         // Backwards compatibility
         SubmittedToEthereum = "burn_submittedToEthereum",
         ConfirmedOnEthereum = "burn_confirmedOnEthereum"
}

enum TxStatus: String {
    // TxStatusNil is used for transactions that have not been seen, or are
    // otherwise unknown.
    case `nil`,
    // TxStatusConfirming is used for transactions that are currently waiting
    // for their underlying blockchain transactions to be confirmed.
         confirming,
    // TxStatusPending is used for transactions that are waiting for consensus
    // to be reached on when the transaction should be executed.
         pending,
    // TxStatusExecuting is used for transactions that are currently being
    // executed.
         executing,
    // TxStatusReverted is used for transactions that were reverted during
    // execution.
         reverted,
    // TxStatusDone is used for transactions that have been successfully
    // executed.
         done
    
    var index: Int {
        switch self {
        case .nil:
            return 0
        case .confirming:
            return 1
        case .pending:
            return 2
        case .executing:
            return 3
        case .reverted:
            return 4
        case .done:
            return 5
        }
    }
}


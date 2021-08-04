//
//  Error.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

enum RenSwiftError: String, Error {
    case transactionNotFound = "REN_RENVM_TRANSACTION_NOT_FOUND",
         depositSpentOrNotFound = "REN_DEPOSIT_SPENT_OR_NOT_FOUND",
         amountTooSmall = "REN_AMOUNT_TOO_SMALL"
}

//
//  ABI+Models.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

enum AbiType: String {
    case function, constructor, event, fallback
}

enum StateMutabilityType: String {
    case pure, view, nonpayable, payable
}

//
//  ABI.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation

protocol AbiItem {
    var anonymous: Bool? {get}
    var constant: Bool? {get}
    var inputs: [AbiInput]? {get}
    var name: String? {get}
    var outputs: [AbiOutput]? {get}
    var payable: Bool? {get}
    var stateMutability: StateMutabilityType {get}
    var type: AbiType {get}
}

protocol AbiInput {
    var name: String {get}
    var type: EthType {get}
    var indexed: Bool? {get}
    var components: [AbiInput]? {get}
    var internalType: String? {get}
}

protocol AbiOutput {
    var name: String {get}
    var type: String {get}
    var components: [AbiOutput]? {get}
    var internalType: String? {get}
}

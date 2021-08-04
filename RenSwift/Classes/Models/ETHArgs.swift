//
//  ETHArgs.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation
import BigInt

protocol EthArg {
    var name: String {get}
    var type: EthType {get}
    var value: Any {get}
    var components: [AbiInput]? {get}

    /**
     * `notInPayload` indicates that the parameter should be used when calling
     * the smart contract but it should not be used when calculating the
     * payload hash. This is useful for values can only be known at the time
     * of calling the contract. Note that others may be able to submit the mint
     * and set their own value, unless the contract caller is restricted somehow.
     */
    var notInPayload: Bool? {get}

    /**
     * `onlyInPayload` indicates that the parameter should be used when
     * calculating the payload hash but it should not be passed in to the
     * contract call. This is useful for values that don't need to be explicitly
     * passed in to the contract, such as the contract caller.
     *
     * `notInPayload` and `onlyInPayload` can be used together to allow users to
     * update values such as exchange rate slippage, which may have updated
     * while waiting for the lock-chain confirmations - while ensuring that
     * others can't change it for them.
     */
    var onlyInPayload: Bool? {get}
}

typealias EthArgs = [EthArg]

protocol EthType {}
extension Bool: EthType {}
extension String: EthType {}
extension Data: EthType {}

// MARK: - Int
protocol EthInt: EthType {}

extension Int: EthInt {}
extension Int8: EthInt {}
extension Int16: EthInt {}
extension Int32: EthInt {}
extension Int64: EthInt {}
extension BigInt: EthInt {}

// MARK: - UInt
protocol EthUInt: EthType {}
extension UInt: EthUInt {}
extension UInt8: EthUInt {}
extension UInt16: EthUInt {}
extension UInt32: EthUInt {}
extension UInt64: EthUInt {}
extension BigUInt: EthUInt {}

// MARK: - Types
typealias EthByte = Data
protocol Address: EthType {
    var base58EncodedString: String {get}
}


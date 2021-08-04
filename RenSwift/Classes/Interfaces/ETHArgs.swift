//
//  ETHArgs.swift
//  RenSwift
//
//  Created by Chung Tran on 04/08/2021.
//

import Foundation
import BigInt

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


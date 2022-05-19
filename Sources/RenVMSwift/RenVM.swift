//
//  RenVM.swift
//  Alamofire
//
//  Created by Chung Tran on 09/09/2021.
//

import Foundation

@available(*, deprecated, message: "This namespace will be removed soon")
public struct RenVM {
    public typealias BurnAndRelease = RenVMSwift.BurnAndRelease
    public typealias LockAndMint = RenVMSwift.LockAndMint
    public typealias Error = RenVMError
    public typealias State = RenVMState
    public typealias Session = RenVMSession
    typealias Selector = RenVMSelector
    typealias ResponseSubmitTxMint = RenVMSwift.ResponseSubmitTxMint
    public typealias ResponseQueryTxMint = RenVMSwift.ResponseQueryTxMint
    public typealias ResponseQueryConfig = RenVMSwift.ResponseQueryConfig
    public typealias ResponseQueryBlockState = RenVMSwift.ResponseQueryBlockState
    public typealias ParamsSubmitMint = RenVMSwift.ParamsSubmitMint
    typealias MintTransactionInput = RenVMSwift.MintTransactionInput
    public typealias Network = RenVMNetwork
    public typealias RpcClient = RenVMSwift.RpcClient
    public typealias SolanaChain = RenVMSwift.SolanaChain
    typealias Script = RenVMSwift.Script
    typealias Hash = RenVMSwift.Hash
}

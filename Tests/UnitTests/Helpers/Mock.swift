//
//  RenVM+Mock.swift
//  SolanaSwift_Tests
//
//  Created by Chung Tran on 11/09/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
@testable import SolanaSwift
@testable import RenVMSwift

struct Mock {
    static var mintToken: String {"BTC"}
    static var version: String {"1"}
    
    static func solanaChain(network: RenVMSwift.Network = .testnet) async throws -> SolanaChain {
        let apiClient = SolanaAPIClient()
        return try await .load(
            client: RpcClient(network: network),
            apiClient: apiClient,
            blockchainClient: BlockchainClient(apiClient: apiClient)
        )
    }
    
    static var rpcClient: RpcClient {
        .init(network: .testnet)
    }
    
    struct RpcClient: RenVMRpcClientType {
        var network: RenVMSwift.Network
        func call<T>(endpoint: String, method: String, params: Encodable, log: Bool) async throws -> T where T : Decodable {
            fatalError()
        }
        func selectPublicKey(mintTokenSymbol: String) async throws -> Data? {
            Data(base64Encoded: "Aw3WX32ykguyKZEuP0IT3RUOX5csm3PpvnFNhEVhrDVc")
        }
        func getIncomingTransactions(address: String) async throws -> [LockAndMint.IncomingTransaction] {
            fatalError()
        }
    }
    
    struct SolanaAPIClient: SolanaSwift.SolanaAPIClient {
        func getAccountInfo<T>(account: String) async throws -> BufferInfo<T>? where T : BufferLayout {
            let dataString: String
            switch T.self {
            case is SolanaChain.GatewayRegistryData.Type:
                dataString = Mock.mockGatewayRegistryData
            default:
                fatalError()
            }
            
            let data = Data(base64Encoded: dataString)!
            var binaryReader = BinaryReader(bytes: data.bytes)
            let response = try T(from: &binaryReader)
            
            return .init(lamports: 0, owner: "", data: response, executable: true, rentEpoch: 0)
        }
        
        func getBalance(account: String, commitment: Commitment?) async throws -> UInt64 {
            fatalError()
        }
        
        func getBlockCommitment(block: UInt64) async throws -> BlockCommitment {
            fatalError()
        }
        
        func getBlockTime(block: UInt64) async throws -> Date {
            fatalError()
        }
        
        func getClusterNodes() async throws -> [ClusterNodes] {
            fatalError()
        }
        
        func getBlockHeight() async throws -> UInt64 {
            fatalError()
        }
        
        func getConfirmedBlocksWithLimit(startSlot: UInt64, limit: UInt64) async throws -> [UInt64] {
            fatalError()
        }
        
        func getConfirmedBlock(slot: UInt64, encoding: String) async throws -> ConfirmedBlock {
            fatalError()
        }
        
        func getConfirmedSignaturesForAddress(account: String, startSlot: UInt64, endSlot: UInt64) async throws -> [String] {
            fatalError()
        }
        
        func getEpochInfo(commitment: Commitment?) async throws -> EpochInfo {
            fatalError()
        }
        
        func getFees(commitment: Commitment?) async throws -> Fee {
            fatalError()
        }
        
        func getSignatureStatuses(signatures: [String], configs: RequestConfiguration?) async throws -> [SignatureStatus?] {
            fatalError()
        }
        
        func getSignatureStatus(signature: String, configs: RequestConfiguration?) async throws -> SignatureStatus {
            fatalError()
        }
        
        func getTokenAccountBalance(pubkey: String, commitment: Commitment?) async throws -> TokenAccountBalance {
            fatalError()
        }
        
        func getTokenAccountsByDelegate(pubkey: String, mint: String?, programId: String?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
            fatalError()
        }
        
        func getTokenAccountsByOwner(pubkey: String, params: OwnerInfoParams?, configs: RequestConfiguration?) async throws -> [TokenAccount<AccountInfo>] {
            fatalError()
        }
        
        func getTokenLargestAccounts(pubkey: String, commitment: Commitment?) async throws -> [TokenAmount] {
            fatalError()
        }
        
        func getTokenSupply(pubkey: String, commitment: Commitment?) async throws -> TokenAmount {
            fatalError()
        }
        
        func getVersion() async throws -> Version {
            fatalError()
        }
        
        func getVoteAccounts(commitment: Commitment?) async throws -> VoteAccounts {
            fatalError()
        }
        
        func minimumLedgerSlot() async throws -> UInt64 {
            fatalError()
        }
        
        func requestAirdrop(account: String, lamports: UInt64, commitment: Commitment?) async throws -> String {
            fatalError()
        }
        
        func sendTransaction(transaction: String, configs: RequestConfiguration) async throws -> TransactionID {
            fatalError()
        }
        
        func simulateTransaction(transaction: String, configs: RequestConfiguration) async throws -> SimulationResult {
            fatalError()
        }
        
        func setLogFilter(filter: String) async throws -> String? {
            fatalError()
        }
        
        func validatorExit() async throws -> Bool {
            fatalError()
        }
        
        func getMultipleAccounts<T>(pubkeys: [String]) async throws -> [BufferInfo<T>] where T : BufferLayout {
            fatalError()
        }
        
        func getSignaturesForAddress(address: String, configs: RequestConfiguration?) async throws -> [SignatureInfo] {
            fatalError()
        }
        
        func getRecentBlockhash(commitment: Commitment?) async throws -> String {
            fatalError()
        }
        
        func observeSignatureStatus(signature: String, timeout: Int, delay: Int) -> AsyncStream<TransactionStatus> {
            fatalError()
        }
        
        func getMinimumBalanceForRentExemption(dataLength: UInt64, commitment: Commitment?) async throws -> UInt64 {
            fatalError()
        }
        
        var endpoint: APIEndPoint {
            fatalError()
        }
        
        func getTransaction(signature: String, commitment: Commitment?) async throws -> TransactionInfo? {
            fatalError()
        }
        
        func batchRequest(with requests: [JSONRPCRequestEncoder.RequestType]) async throws -> [AnyResponse<JSONRPCRequestEncoder.RequestType.Entity>] {
            fatalError()
        }
    }
    
    static var mockGatewayRegistryData: String { "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"
    }
    
    static var mockGatewayStateData: String {
        "AUS7TvQ0CAcryIiv0aWYa6DONctUFqxvuLgA/54kIgR51p04tZoHeWb1AMe700NdrXjY/AIIAAAAAAAAAAg="
    }
}

//
//  RenVM+Mock.swift
//  SolanaSwift_Tests
//
//  Created by Chung Tran on 11/09/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import RxSwift
import RxBlocking
@testable import SolanaSwift
@testable import RenVMSwift

extension RenVM {
    struct Mock {
        static var mintToken: String {"BTC"}
        static var version: String {"1"}
        
        static func solanaChain(network: RenVM.Network = .testnet) -> SolanaChain {
            try! RenVM.SolanaChain.load(
                client: RpcClient(network: network),
                solanaClient: SolanaClient()
            ).toBlocking().first()!
        }
        
        static var rpcClient: RpcClient {
            .init(network: .testnet)
        }
        
        struct RpcClient: RenVMRpcClientType {
            var network: RenVM.Network
            func call<T>(endpoint: String, method: String, params: Encodable, log: Bool) -> Single<T> where T : Decodable {
                fatalError()
            }
            func selectPublicKey(mintTokenSymbol: String) -> Single<Data?> {
                .just(Data(base64Encoded: "Aw3WX32ykguyKZEuP0IT3RUOX5csm3PpvnFNhEVhrDVc"))
            }
        }
        
        struct SolanaClient: RenVMSolanaAPIClientType {
            func waitForConfirmation(signature: String) -> Completable {
                .empty()
            }
            
            func getAccountInfo<T>(account: String, decodedTo: T.Type) -> Single<BufferInfo<T>> where T : DecodableBufferLayout {
                if decodedTo == RenVM.SolanaChain.GatewayRegistryData.self {
                    let data = Data(base64Encoded: RenVM.Mock.mockGatewayRegistryData)!
                    var pointer = 0
                    let gatewayRegistryData = try! RenVM.SolanaChain.GatewayRegistryData(buffer: data, pointer: &pointer)
                    return .just(.init(lamports: 0, owner: "", data: gatewayRegistryData as! T, executable: true, rentEpoch: 0))
                }
                fatalError()
            }
            
            func getMintData(mintAddress: String, programId: String) -> Single<Mint> {
                fatalError()
            }
            
            func getConfirmedSignaturesForAddress2(account: String, configs: RequestConfiguration?) -> Single<[SignatureInfo]> {
                fatalError()
            }
            
            func serializeAndSend(instructions: [TransactionInstruction], recentBlockhash: String?, signers: [Account], isSimulation: Bool) -> Single<String> {
                fatalError()
            }
        }
        
        static var mockGatewayRegistryData: String { "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"
        }
        
        static var mockGatewayStateData: String {
            "AUS7TvQ0CAcryIiv0aWYa6DONctUFqxvuLgA/54kIgR51p04tZoHeWb1AMe700NdrXjY/AIIAAAAAAAAAAg="
        }
    }
}

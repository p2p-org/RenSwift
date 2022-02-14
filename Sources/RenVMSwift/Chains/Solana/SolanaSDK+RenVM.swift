//
//  SolanaSDK+RenVM.swift
//  SolanaSwift
//
//  Created by Chung Tran on 15/09/2021.
//

import Foundation
import RxSwift
import SolanaSwift

extension SolanaSDK: RenVMSolanaAPIClientType {}
extension SolanaSDK: RenVMSolanaTransactionSenderType {
    public func getFeePayer() -> Single<PublicKey> {
        guard let account = accountStorage.account else {return .error(Error.unauthorized)}
        return .just(account.publicKey)
    }
}

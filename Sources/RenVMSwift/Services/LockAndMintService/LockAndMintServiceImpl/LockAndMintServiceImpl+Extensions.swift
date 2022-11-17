import Foundation
import LoggerSwift

extension LockAndMintServiceImpl {
    /// Submit if needed and mint tx
    func submitIfNeededAndMint(_ tx: LockAndMint.ProcessingTx) async throws {
        // guard for tx that was confirmed or submited only
        guard tx.state.isConfirmed || tx.state.isSubmited else {
            return
        }
        
        // mark as processing
        await persistentStore.markAsProcessing(tx)
        await notifyChanges()
        
        // get infos
        let account = try await destinationChainProvider.getAccount()
        
        guard let response = stateSubject.value.response,
              let lockAndMint = lockAndMint,
              let chain = chain
        else { throw RenVMError.unknown }

        // get state
        let state = try lockAndMint.getDepositState(
            transactionHash: tx.tx.id,
            txIndex: String(tx.tx.vout),
            amount: String(tx.tx.value),
            sendTo: response.sendTo,
            gHash: response.gHash,
            gPubkey: response.gPubkey
        )
        
        // submit
        if !tx.state.isSubmited {
            do {
                try Task.checkCancellation()
                let hash = try await lockAndMint.submitMintTransaction(state: state)
                print("submited transaction with hash: \(hash)")
                await persistentStore.markAsSubmited(tx.tx, at: Date())
                await notifyChanges()
            } catch {
                debugPrint(error)
                // try to mint anyway, ignore error
            }
        }
        
        // mint
        try Task.checkCancellation()
        Task.retrying(
            where: { _ in true },
            maxRetryCount: .max,
            retryDelay: refreshingRate
        ) { [weak self] in
            guard let self = self else { return }
            try Task.checkCancellation()
            do {
                _ = try await lockAndMint.mint(state: state, signer: account.secret)
                await self.persistentStore.markAsMinted(tx.tx, at: Date())
                await self.notifyChanges()
            }
            
            // insufficient fund error
            catch let error as RenVMError where error.isInsufficientFundError {
                await self.persistentStore.markAsInvalid(txid: tx.tx.id, error: error.processingError, at: Date())
                if self.showLog {
                    Logger.log(event: .error, message: "Could not mint transaction with id \(tx.tx.id), error: \(error)")
                }
            }
            
            // already mint error
            catch let error where chain.isAlreadyMintedError(error) {
                // already minted
                await self.persistentStore.markAsMinted(tx.tx, at: Date())
                await self.notifyChanges()
            }
            
            // other error
            catch {
                if self.showLog {
                    Logger.log(event: .error, message: "Could not mint transaction with id \(tx.tx.id), error: \(error)")
                    Logger.log(event: .info, message: "Retrying...")
                }
                throw error
            }
        }
    }
}

private extension RenVMError {
    var isInsufficientFundError: Bool {
        message.starts(with: "insufficient amount after fees")
    }
    
    var processingError: LockAndMint.ProcessingError {
        let array = message
            .replacingOccurrences(of: "insufficient amount after fees: expected at least ", with: "")
            .replacingOccurrences(of: ", got ", with: " ")
            .components(separatedBy: " ")
        
        // mark as ignored
        if array.count == 2,
           let expected = UInt64(array[0]),
           let got = UInt64(array[1])
        {
            return .insufficientFund(expected: expected, got: got)
        } else {
            return .other(message)
        }
    }
}

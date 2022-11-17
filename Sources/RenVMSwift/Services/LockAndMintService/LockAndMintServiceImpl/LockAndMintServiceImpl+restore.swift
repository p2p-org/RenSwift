import Foundation

extension LockAndMintServiceImpl {
    /// Continue with saved transactions
    func restorePreviousTask() async {
        // get all transactions that are valid and are not being processed
        let groupedTransactions = await persistentStore.processingTransactions.grouped()
        let confirmedAndSubmitedTransactions = groupedTransactions.confirmed + groupedTransactions.submited
        let transactionsToBeProcessed = confirmedAndSubmitedTransactions.filter {
            $0.isProcessing == false
        }
        
        // process transactions simutaneously
        await withTaskGroup(of: Void.self) { [weak self] group in
            for tx in transactionsToBeProcessed {
                group.addTask { [weak self] in
                    guard let self = self else {return}
                    do {
                        try Task.checkCancellation()
                        try await self.submitIfNeededAndMint(tx)
                    } catch {
                        if self.showLog {
                            print("submitIfNeededAndMint error: ", error)
                        }
                        // do not throw
                    }
                }
            }
            
            for await _ in group {}
        }
    }
}

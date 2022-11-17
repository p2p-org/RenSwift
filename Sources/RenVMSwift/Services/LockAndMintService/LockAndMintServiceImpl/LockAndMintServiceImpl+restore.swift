import Foundation

extension LockAndMintServiceImpl {
    /// Continue with saved transactions
    func restorePreviousTask() async {
        // get all transactions that are valid and are not being processed
        let groupedTransactions = await persistentStore.processingTransactions.grouped()
        let confirmedAndSubmitedTransactions = groupedTransactions.received + groupedTransactions.confirmed + groupedTransactions.submited
        let transactionsToBeProcessed = confirmedAndSubmitedTransactions.filter {
            $0.isProcessing == false
        }
        
        // process transactions simutaneously
        for tx in transactionsToBeProcessed {
            Task.detached {
                try Task.checkCancellation()
                try await self.addToQueueAndMint(tx.tx)
            }
        }
    }
}

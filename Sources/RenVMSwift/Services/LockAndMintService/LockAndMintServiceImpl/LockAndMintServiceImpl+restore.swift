import Foundation

extension LockAndMintServiceImpl {
    /// Continue with saved transactions
    func restorePreviousTask() async {
        // get all transactions that are valid and are not being processed
        let transactionsToBeProcessed = await persistentStore.processingTransactions.filter {$0.state < .minted && !$0.isProcessing}
        
        // process transactions simutaneously
        for tx in transactionsToBeProcessed {
            addToQueueAndMint(tx.tx)
        }
    }
}

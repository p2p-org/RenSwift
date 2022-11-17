import Foundation

extension LockAndMintServiceImpl {
    /// Observe and mint if there is any new transaction
    func observeNewIncommingTransactionsAndMint() async {
        repeat {
            if Task.isCancelled {
                return
            }
            await getIncommingTransactionsAndMint()
            try? await Task.sleep(nanoseconds: 1_000_000_000 * UInt64(refreshingRate)) // 5 seconds
        } while true
    }
    
    /// Get incomming transactions and mint
    private func getIncommingTransactionsAndMint() async {
        guard let address = await persistentStore.gatewayAddress
        else { return }
        
        // get incomming transaction
        guard let incommingTransactions = try? await sourceChainExplorerAPIClient.getIncommingTransactions(for: address)
        else {
            return
        }
        
        // save to persistentStore unsaved transaction
        for transaction in incommingTransactions where await !persistentStore.processingTransactions.contains(where: {$0.tx.id == transaction.id}) {
            // get marker date
            let date = transaction.blockTime == nil ? Date(): Date(timeIntervalSince1970: TimeInterval(transaction.blockTime!))
            await persistentStore.markAsReceived(transaction, at: date)
            notifyChanges()
            
            // add to queue and mint in separated task
            addToQueueAndMint(transaction)
        }
    }
}

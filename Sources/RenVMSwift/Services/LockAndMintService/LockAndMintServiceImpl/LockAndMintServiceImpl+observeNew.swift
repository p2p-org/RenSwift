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
            
            // add to queue and mint in separated task
            Task.detached { [weak self] in
                try await self?.addToQueueAndMint(transaction)
            }
        }
        await notifyChanges()
    }
    
    /// Add new received transaction
    private func addToQueueAndMint(_ transaction: ExplorerAPIIncomingTransaction) async throws {
        let confirmationsStream = sourceChainExplorerAPIClient
            .observeConfirmations(id: transaction.id)
        for await confirmations in confirmationsStream {
            Task.detached { [weak self] in
                await self?.updateConfirmationsStatus(transaction: transaction, confirmations: confirmations)
            }
        }
        try await markAsConfirmedAndMint(transaction: transaction)
    }
    
    /// Update confirmations status
    private func updateConfirmationsStatus(transaction: ExplorerAPIIncomingTransaction, confirmations: UInt) async {
        var transaction = transaction
        transaction.confirmations = confirmations
        await persistentStore.markAsReceived(transaction, at: Date())
        await notifyChanges()
    }
    
    /// Mark transaction as confirmed and mint
    private func markAsConfirmedAndMint(transaction: ExplorerAPIIncomingTransaction) async throws {
        await persistentStore.markAsConfirmed(transaction, at: Date())
        await notifyChanges()
        
        if let transaction = await persistentStore.processingTransactions
            .first(where: {$0.tx.id == transaction.id})
        {
            try await submitIfNeededAndMint(transaction)
        }
    }
}

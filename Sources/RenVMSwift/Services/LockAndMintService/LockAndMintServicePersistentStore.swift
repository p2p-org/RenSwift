import Foundation
import LoggerSwift

/// PersistentStore to persist current works
public protocol LockAndMintServicePersistentStore {
    // MARK: - Session
    
    /// Current working Session
    var session: LockAndMint.Session? { get async }
    
    /// Save session
    func save(session: LockAndMint.Session) async
    
    // MARK: - GatewayAddress
    /// CurrentGatewayAddress
    var gatewayAddress: String? { get async }
    
    /// Save gateway address
    func save(gatewayAddress: String) async
    
    // MARK: - ProcessingTransaction
    
    /// Transaction which are being processed
    var processingTransactions: [LockAndMint.ProcessingTx] { get async }
    
    /// Mark as processing
    func markAsProcessing(_ transaction: LockAndMint.ProcessingTx) async
    
    /// Mark all transaction as not processing
    func markAllTransactionsAsNotProcessing() async
    
    /// Mark as received
    func markAsReceived(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async
    
    /// Mark as confimed
    func markAsConfirmed(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async
    
    /// Mark as submited
    func markAsSubmited(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async
    
    /// Mark as minted
    func markAsMinted(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async
    
    /// Mark as invalid
    func markAsInvalid(txid: String, error: LockAndMint.ProcessingError, at date: Date) async
    
    // MARK: - Clearance
    /// Clear all (expire current session)
    func clearAll() async
}

/// Implementation of LockAndMintServicePersistentStore, using UserDefaults as storage
public actor UserDefaultLockAndMintServicePersistentStore: LockAndMintServicePersistentStore
{
    // MARK: - Properties
    
    /// Key to store session in UserDefaults
    private let userDefaultKeyForSession: String
    /// Key to store gateway address in UserDefaults
    private let userDefaultKeyForGatewayAddress: String
    /// Key to store processingTransactions in UserDefaults
    private let userDefaultKeyForProcessingTransactions: String
    
    /// Flag to indicate whether show log or not
    private let showLog: Bool
    
    // MARK: - Initializer
    
    public init(
        userDefaultKeyForSession: String,
        userDefaultKeyForGatewayAddress: String,
        userDefaultKeyForProcessingTransactions: String,
        showLog: Bool
    ) {
        self.userDefaultKeyForSession = userDefaultKeyForSession
        self.userDefaultKeyForGatewayAddress = userDefaultKeyForGatewayAddress
        self.userDefaultKeyForProcessingTransactions = userDefaultKeyForProcessingTransactions
        self.showLog = showLog
    }
    
    // MARK: - Session
    
    public var session: LockAndMint.Session? {
        getFromUserDefault(key: userDefaultKeyForSession)
    }
    
    public func save(session: LockAndMint.Session) {
        saveToUserDefault(session, key: userDefaultKeyForSession)
    }
    
    // MARK: - Gateway address
    
    public var gatewayAddress: String? {
        getFromUserDefault(key: userDefaultKeyForGatewayAddress)
    }
    
    public func save(gatewayAddress: String) {
        saveToUserDefault(gatewayAddress, key: userDefaultKeyForGatewayAddress)
    }
    
    // MARK: - Processing transactions
    
    public var processingTransactions: [LockAndMint.ProcessingTx] {
        getFromUserDefault(key: userDefaultKeyForProcessingTransactions) ?? []
    }
    
    public func markAsProcessing(_ transaction: LockAndMint.ProcessingTx) {
        save { current in
            guard let index = current.indexOf(transaction.tx.txid) else {
                return false
            }
            current[index].isProcessing = true
            return true
        }
        
        if showLog {
            Logger.log(event: .request, message: "Transaction with id \(transaction.tx.txid), vout: \(transaction.tx.vout), isConfirmed: \(transaction.tx.status.confirmed), value: \(transaction.tx.value) is being processed")
        }
    }
    
    public func markAllTransactionsAsNotProcessing() {
        save { current in
            for i in 0..<current.count {
                current[i].isProcessing = false
            }
            return true
        }
        
        if showLog {
            Logger.log(event: .info, message: "All transactions has been removed from queue")
        }
    }
    
    public func markAsReceived(_ tx: LockAndMint.IncomingTransaction, at date: Date) {
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, state: .confirming, timestamp: .init(voteAt: [tx.vout: Date()])))
                return true
            }
            
            current[index].state = .confirming
            if current[index].timestamp.voteAt[tx.vout] == nil {
                current[index].timestamp.voteAt[tx.vout] = Date()
            }
            return true
        }
        
        if showLog {
            Logger.log(event: .event, message: "Received transaction with id \(tx.txid), vout: \(tx.vout), isConfirmed: \(tx.status.confirmed), value: \(tx.value)")
        }
    }
    
    public func markAsConfirmed(_ tx: LockAndMint.IncomingTransaction, at date: Date) {
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, state: .confirmed, timestamp: .init(confirmedAt: Date())))
                return true
            }
            current[index].state = .confirmed
            if current[index].timestamp.confirmedAt == nil {
                current[index].timestamp.confirmedAt = Date()
            }
            return true
        }
        
        if showLog {
            Logger.log(event: .event, message: "Transaction with id \(tx.txid) has been confirmed, vout: \(tx.vout), value: \(tx.value)")
        }
    }
    
    public func markAsSubmited(_ tx: LockAndMint.IncomingTransaction, at date: Date) {
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, state: .submited, timestamp: .init(submitedAt: Date())))
                return true
            }
            current[index].state = .submited
            if current[index].timestamp.submitedAt == nil {
                current[index].timestamp.submitedAt = Date()
            }
            return true
        }
        
        if showLog {
            Logger.log(event: .event, message: "Transaction with id \(tx.txid) has been submited, value: \(tx.value)")
        }
    }
    
    public func markAsMinted(_ tx: LockAndMint.IncomingTransaction, at date: Date) {
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, state: .minted, timestamp: .init(submitedAt: Date())))
                return true
            }
            current[index].state = .minted
            if current[index].timestamp.mintedAt == nil {
                current[index].timestamp.mintedAt = Date()
            }
            return true
        }
        
        if showLog {
            Logger.log(event: .event, message: "Transaction with id \(tx.txid) has been minted, value: \(tx.value)")
        }
    }
    
    public func markAsInvalid(txid: String, error: LockAndMint.ProcessingError, at date: Date) {
        save { current in
            guard let index = current.indexOf(txid) else {
                return false
            }
            current[index].state = .ignored(error: error)
            if current[index].timestamp.ignoredAt == nil {
                current[index].timestamp.ignoredAt = Date()
            }
            return true
        }
        
        if showLog {
            Logger.log(event: .event, message: "Transaction with id \(txid) is invalid, error: \(error)")
        }
    }
    
    public func clearAll() {
        clearFromUserDefault(key: userDefaultKeyForSession)
        clearFromUserDefault(key: userDefaultKeyForGatewayAddress)
        clearFromUserDefault(key: userDefaultKeyForProcessingTransactions)
    }
    
    // MARK: - Private
    
    private func getFromUserDefault<T: Decodable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let session = try? JSONDecoder().decode(T.self, from: data)
        else {return nil}
        return session
    }
    
    private func saveToUserDefault<T: Encodable>(_ object: T, key: String) {
        guard let data = try? JSONEncoder().encode(object) else {return}
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func clearFromUserDefault(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    private func save(_ modify: @escaping (inout [LockAndMint.ProcessingTx]) -> Bool) {
        var current: [LockAndMint.ProcessingTx] = getFromUserDefault(key: userDefaultKeyForProcessingTransactions) ?? []
        let shouldSave = modify(&current)
        if shouldSave {
            saveToUserDefault(current, key: userDefaultKeyForProcessingTransactions)
        }
    }
}

private extension Array where Element == LockAndMint.ProcessingTx {
    func hasTx(_ tx: LockAndMint.IncomingTransaction) -> Bool {
        contains(where: { $0.tx.txid == tx.txid })
    }

    func indexOf(_ tx: LockAndMint.IncomingTransaction) -> Int? {
        firstIndex(where: { $0.tx.txid == tx.txid })
    }
    
    func indexOf(_ txid: String) -> Int? {
        firstIndex(where: { $0.tx.txid == txid })
    }
}

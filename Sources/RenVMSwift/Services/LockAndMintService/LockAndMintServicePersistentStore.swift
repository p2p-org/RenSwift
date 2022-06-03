import Foundation
import LoggerSwift

/// PersistentStore to persist current works
public protocol LockAndMintServicePersistentStore {
    // MARK: - Session
    
    /// Current working Session
    var session: LockAndMint.Session? { get async }
    
    /// Save session
    func save(session: LockAndMint.Session) async throws
    
    // MARK: - GatewayAddress
    /// CurrentGatewayAddress
    var gatewayAddress: String? { get async }
    
    /// Save gateway address
    func save(gatewayAddress: String) async throws
    
    // MARK: - ProcessingTransaction
    
    /// Transaction which are being processed
    var processingTransactions: [LockAndMint.ProcessingTx] { get async }
    
    /// Mark as received
    func markAsReceived(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
    
    /// Mark as confimed
    func markAsConfirmed(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
    
    /// Mark as submited
    func markAsSubmited(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
    
    /// Mark as minted
    func markAsMinted(_ incomingTransaction: LockAndMint.IncomingTransaction, at date: Date) async throws
    
    /// Mark as invalid
    func markAsInvalid(_ incomingTransaction: LockAndMint.IncomingTransaction, reason: String?) async throws
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
    
    // MARK: - Initializer
    
    public init(
        userDefaultKeyForSession: String,
        userDefaultKeyForGatewayAddress: String,
        userDefaultKeyForProcessingTransactions: String
    ) {
        self.userDefaultKeyForSession = userDefaultKeyForSession
        self.userDefaultKeyForGatewayAddress = userDefaultKeyForGatewayAddress
        self.userDefaultKeyForProcessingTransactions = userDefaultKeyForProcessingTransactions
    }
    
    // MARK: - Session
    
    public var session: LockAndMint.Session? {
        getFromUserDefault(key: userDefaultKeyForSession)
    }
    
    public func save(session: LockAndMint.Session) throws {
        saveToUserDefault(session, key: userDefaultKeyForSession)
    }
    
    // MARK: - Gateway address
    
    public var gatewayAddress: String? {
        getFromUserDefault(key: userDefaultKeyForGatewayAddress)
    }
    
    public func save(gatewayAddress: String) throws {
        saveToUserDefault(gatewayAddress, key: userDefaultKeyForGatewayAddress)
    }
    
    // MARK: - Processing transactions
    
    public var processingTransactions: [LockAndMint.ProcessingTx] {
        getFromUserDefault(key: userDefaultKeyForProcessingTransactions) ?? []
    }
    
    public func markAsReceived(_ tx: LockAndMint.IncomingTransaction, at date: Date) throws {
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, receivedAt: date))
                return true
            }

            if tx.vout == 3, current[index].threeVoteAt == nil {
                current[index].threeVoteAt = date
            }
            if tx.vout == 2, current[index].twoVoteAt == nil {
                current[index].twoVoteAt = date
            }
            if tx.vout == 1, current[index].oneVoteAt == nil {
                current[index].oneVoteAt = date
            }
            if tx.vout == 0, current[index].receivedAt == nil {
                current[index].receivedAt = date
            }

            return true
        }
    }
    
    public func markAsConfirmed(_ tx: LockAndMint.IncomingTransaction, at date: Date) throws {
        Logger.log(event: .event, message: "Transaction confirmed with id: \(tx.txid), detail: \(tx)")
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, confirmedAt: date))
                return true
            }
            current[index].confirmedAt = date
            return true
        }
    }
    
    public func markAsSubmited(_ tx: LockAndMint.IncomingTransaction, at date: Date) throws {
        Logger.log(event: .event, message: "Transaction submited with id: \(tx.txid), detail: \(tx)")
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, submitedAt: date))
                return true
            }
            current[index].submitedAt = date
            return true
        }
    }
    
    public func markAsMinted(_ tx: LockAndMint.IncomingTransaction, at date: Date) throws {
        Logger.log(event: .event, message: "Transaction minted with id: \(tx.txid), detail: \(tx)")
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, mintedAt: date))
                return true
            }
            current[index].mintedAt = date
            return true
        }
    }
    
    public func markAsInvalid(_ tx: LockAndMint.IncomingTransaction, reason: String?) async throws {
        Logger.log(event: .error, message: "Transaction with id \(tx.txid) is marked as invalid, reason: \(reason ?? "nil")")
        save { current in
            guard let index = current.indexOf(tx) else {
                current.append(.init(tx: tx, validationStatus: .invalid(reason: reason)))
                return true
            }
            current[index].validationStatus = .invalid(reason: reason)
            return true
        }
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
}

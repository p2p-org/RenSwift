import Foundation

/// Persistent store for recovering transaction in case of failure
public protocol BurnAndReleasePersistentStore {
    /// Get last non released transactions for retrying
    /// - Returns: Transactions that wasn't released last time
    func getNonReleasedTransactions() async -> [BurnAndRelease.BurnDetails]
    
    /// Persist non released transaction for retrying next time
    /// - Parameter transaction: transaction to be persisted
    func persistNonReleasedTransactions(_ transaction: BurnAndRelease.BurnDetails) async
    
    /// Mark transaction as released
    /// - Parameter transaction: transaction to be marked
    func markAsReleased(_ transaction: BurnAndRelease.BurnDetails) async
}

public actor UserDefaultsBurnAndReleasePersistentStore: BurnAndReleasePersistentStore {
    private let userDefaultKeyForSubmitedBurnTransactions: String
    
    public init(userDefaultKeyForSubmitedBurnTransactions: String) {
        self.userDefaultKeyForSubmitedBurnTransactions = userDefaultKeyForSubmitedBurnTransactions
    }
    
    public func getNonReleasedTransactions() -> [BurnAndRelease.BurnDetails] {
        getFromUserDefault(key: userDefaultKeyForSubmitedBurnTransactions) ?? []
    }

    public func persistNonReleasedTransactions(_ details: BurnAndRelease.BurnDetails) {
        var currentValue: [BurnAndRelease.BurnDetails] = getFromUserDefault(key: userDefaultKeyForSubmitedBurnTransactions) ?? []
        currentValue.removeAll(where: { $0.confirmedSignature == details.confirmedSignature })
        currentValue.append(details)
        saveToUserDefault(currentValue, key: userDefaultKeyForSubmitedBurnTransactions)
    }

    public func markAsReleased(_ details: BurnAndRelease.BurnDetails) {
        var currentValue: [BurnAndRelease.BurnDetails] = getFromUserDefault(key: userDefaultKeyForSubmitedBurnTransactions) ?? []
        currentValue.removeAll(where: { $0.confirmedSignature == details.confirmedSignature })
        saveToUserDefault(currentValue, key: userDefaultKeyForSubmitedBurnTransactions)
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
}

import Foundation
import SolanaSwift

/// The service for burn and release
public protocol BurnAndReleaseService {
    /// Resume on going tasks
    func resume()
    /// Check if network is testnet
    func isTestNet() -> Bool
    /// Get fee of burn and release
    func getFee() async throws -> Double
    /// Burn and release transaction
    /// - Parameters:
    ///   - recipient: receiver
    ///   - amount: amount to be sent
    /// - Returns: transaction signature
    func burnAndRelease(recipient: String, amount: UInt64) async throws -> String
}

/// Persistent store for recovering transaction in case of failure
public protocol BurnAndReleasePersistentStore {
    /// Get last non released transactions for retrying
    /// - Returns: Transactions that wasn't released last time
    func getNonReleasedTransactions() -> [BurnAndRelease.BurnDetails]
    
    /// Persist non released transaction for retrying next time
    /// - Parameter transaction: transaction to be persisted
    func persistNonReleasedTransactions(_ transaction: BurnAndRelease.BurnDetails)
    
    /// Mark transaction as released
    /// - Parameter transaction: transaction to be marked
    func markAsReleased(_ transaction: BurnAndRelease.BurnDetails)
}

/// Implementation of BurnAndReleaseService
public class BurnAndReleaseServiceImpl: BurnAndReleaseService {
    // MARK: - Nested type
    public typealias BurnDetails = BurnAndRelease.BurnDetails
    public struct DestinationChain {
        public init(name: String, symbol: String, decimals: UInt8) {
            self.name = name
            self.symbol = symbol
            self.decimals = decimals
        }
        
        let name: String
        let symbol: String
        let decimals: UInt8
        
        public static var bitcoin: Self {
            .init(name: "Bitcoin", symbol: "BTC", decimals: 8)
        }
    }

    private actor Cache {
        var burnAndRelease: BurnAndRelease?

        func save(burnAndRelease: BurnAndRelease) {
            self.burnAndRelease = burnAndRelease
        }
    }

    // MARK: - Dependencies

    private let rpcClient: RenVMRpcClientType
    private let chainProvider: ChainProvider
    private let destinationChain: DestinationChain
    private let persistentStore: BurnAndReleasePersistentStore
    private let version: String

    // MARK: - Properties

    private let cache = Cache()
    private var chain: RenVMChainType?

    // MARK: - Initializer

    public init(
        rpcClient: RenVMRpcClientType,
        chainProvider: ChainProvider,
        destinationChain: DestinationChain,
        persistentStore: BurnAndReleasePersistentStore,
        version: String
    ) {
        self.rpcClient = rpcClient
        self.chainProvider = chainProvider
        self.destinationChain = destinationChain
        self.persistentStore = persistentStore
        self.version = version
    }
    
    public func resume() {
        Task {
            try await reload()
            try await releaseUnfinishedTxsFromPersistentStore()
        }
    }
    
    public func isTestNet() -> Bool {
        rpcClient.network.isTestnet
    }

    public func getFee() async throws -> Double {
        let lamports = try await rpcClient.getTransactionFee(mintTokenSymbol: destinationChain.symbol)
        return lamports.convertToBalance(decimals: destinationChain.decimals)
    }

    public func burnAndRelease(recipient: String, amount: UInt64) async throws -> String {
        let account = try await chainProvider.getAccount()
        let burnAndRelease = try await getBurnAndRelease()
        let burnDetails = try await burnAndRelease.submitBurnTransaction(
            account: account.publicKey,
            amount: String(amount),
            recipient: recipient,
            signer: account.secret
        )
        
        persistentStore.persistNonReleasedTransactions(burnDetails)
        
        if let chain = chain {
            try await chain.waitForConfirmation(signature: burnDetails.confirmedSignature)
        }
        let signature = try await release(burnDetails)
        
        persistentStore.markAsReleased(burnDetails)
        return signature
    }
    
    // MARK: - Private
    private func reload() async throws {
        chain = try await chainProvider.load()
        let burnAndRelease = BurnAndRelease(
            rpcClient: rpcClient,
            chain: chain!,
            mintTokenSymbol: destinationChain.symbol,
            version: version,
            burnTo: destinationChain.name
        )
        await cache.save(burnAndRelease: burnAndRelease)
    }
    
    private func releaseUnfinishedTxsFromPersistentStore() async throws {
        let nonReleasedTransactions = persistentStore.getNonReleasedTransactions()
        try await withThrowingTaskGroup(of: Void.self) { group in
            for detail in nonReleasedTransactions {
                group.addTask { [weak self] in
                    guard let self = self, let chain = self.chain else { throw RenVMError.unknown }
                    do {
                        try await chain.waitForConfirmation(signature: detail.confirmedSignature)
                        _ = try await self.release(detail)
                    } catch {
                        debugPrint(error)
                    }
                }

                for try await _ in group {}
            }
        }
    }

    private func release(_ detail: BurnDetails) async throws -> String {

        let burnAndRelease = try await getBurnAndRelease()
        let state = try burnAndRelease.getBurnState(burnDetails: detail)

        return try await Task.retrying(
            where: { _ in true },
            maxRetryCount: .max,
            retryDelay: 3
        ) { () -> String in
            try Task.checkCancellation()
            return try await burnAndRelease.release(state: state, details: detail)
        }.value
    }

    private func getBurnAndRelease() async throws -> BurnAndRelease {
        if await cache.burnAndRelease == nil {
            try await reload()
        }
        if let burnAndRelease = await cache.burnAndRelease {
            return burnAndRelease
        }
        throw RenVMError("Could not initialize burn and release service")
    }
}


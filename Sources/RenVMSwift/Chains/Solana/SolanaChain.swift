import Foundation
import SolanaSwift

public struct SolanaChain: RenVMChainType {
    // MARK: - Constants
    static let gatewayRegistryStateKey  = "GatewayRegistryState"
    let gatewayStateKey                 = "GatewayStateV0.1.4"
    public let chainName: String        = "Solana"
    
    // MARK: - Properties
    let gatewayRegistryData: GatewayRegistryData
    let client: RenVMRpcClientType
    let apiClient: SolanaAPIClient
    let blockchainClient: SolanaBlockchainClient
    
    // MARK: - Methods
    public static func load(
        client: RenVMRpcClientType,
        apiClient: SolanaAPIClient,
        blockchainClient: SolanaBlockchainClient
    ) async throws -> Self {
        let pubkey = try PublicKey(string: client.network.gatewayRegistry)
        let stateKey = try PublicKey.findProgramAddress(
            seeds: [Self.gatewayRegistryStateKey.data(using: .utf8)!],
            programId: pubkey
        )
        let result: BufferInfo<GatewayRegistryData>? = try await apiClient.getAccountInfo(
            account: stateKey.0.base58EncodedString
        )
        
        guard let data = result?.data else {
            throw SolanaError.couldNotRetrieveAccountInfo
        }
        
        return .init(gatewayRegistryData: data, client: client, apiClient: apiClient, blockchainClient: blockchainClient)
    }
    
    func resolveTokenGatewayContract(mintTokenSymbol: String) throws -> PublicKey {
        guard let sHash = try? PublicKey(
                string: Base58.encode(
                    Hash.generateSHash(
                        selector: selector(mintTokenSymbol: mintTokenSymbol, direction: .to)
                    ).bytes
                )
            ),
            let index = gatewayRegistryData.selectors.firstIndex(of: sHash),
            gatewayRegistryData.gateways.count > index
        else {throw RenVMError("Could not resolve token gateway contract")}
        return gatewayRegistryData.gateways[index]
    }
    
    func getSPLTokenPubkey(mintTokenSymbol: String) throws -> PublicKey {
        let program = try resolveTokenGatewayContract(mintTokenSymbol: mintTokenSymbol)
        let sHash = Hash.generateSHash(
            selector: selector(mintTokenSymbol: mintTokenSymbol, direction: .to)
        )
        return try .findProgramAddress(seeds: [sHash], programId: program).0
    }
    
    public func getAssociatedTokenAddress(
        address: Data,
        mintTokenSymbol: String
    ) throws -> Data {
        let tokenMint = try getSPLTokenPubkey(mintTokenSymbol: mintTokenSymbol)
        return try PublicKey.associatedTokenAddress(
            walletAddress: try PublicKey(data: address),
            tokenMintAddress: tokenMint
        ).data
    }
    
    public func dataToAddress(data: Data) throws -> String {
        Base58.encode(data.bytes)
    }
    
    public func signatureToData(signature: String) throws -> Data {
        Data(Base58.decode(signature))
    }
    
    public func createAssociatedTokenAccount(
        address: PublicKey,
        mintTokenSymbol: String,
        signer: Account
    ) async throws -> String {
        let tokenMint = try getSPLTokenPubkey(mintTokenSymbol: mintTokenSymbol)
        let createAccountInstruction = try AssociatedTokenProgram
            .createAssociatedTokenAccountInstruction(
                mint: tokenMint,
                owner: address,
                payer: signer.publicKey
            )
        
        let preparedTransaction = try await blockchainClient.prepareTransaction(
            instructions: [createAccountInstruction],
            signers: [signer],
            feePayer: signer.publicKey,
            feeCalculator: nil
        )
        
        return try await blockchainClient.sendTransaction(
            preparedTransaction: preparedTransaction
        )
    }
    
    public func submitMint(
        address: Data,
        mintTokenSymbol: String,
        signer secretKey: Data,
        responceQueryMint: ResponseQueryTxMint
    ) async throws -> String {
        guard let pHash = responceQueryMint.valueIn.phash.decodeBase64URL(),
              let nHash = responceQueryMint.valueIn.nhash.decodeBase64URL(),
              let amount = responceQueryMint.valueOut.amount
        else {
            throw RenVMError.paramsMissing
        }
        
        let sHash = Hash.generateSHash(
            selector: selector(mintTokenSymbol: mintTokenSymbol, direction: .to)
        )
        
        guard let fixedSig = try responceQueryMint.valueOut.sig?.decodeBase64URL()?.fixSignatureSimple()
        else {throw RenVMError.paramsMissing}
        let sig = fixedSig
        let program = try resolveTokenGatewayContract(mintTokenSymbol: mintTokenSymbol)
        let gatewayAccountId: PublicKey = try .findProgramAddress(
            seeds: [Data(gatewayStateKey.bytes)],
            programId: program
        ).0
        let tokenMint = try getSPLTokenPubkey(mintTokenSymbol: mintTokenSymbol)
        let mintAuthority: PublicKey = try .findProgramAddress(
            seeds: [tokenMint.data],
            programId: program
        ).0
        let recipientTokenAccount = try PublicKey(data: try getAssociatedTokenAddress(address: address, mintTokenSymbol: mintTokenSymbol))
        let renVMMessage = try Self.buildRenVMMessage(
            pHash: pHash,
            amount: amount,
            token: sHash,
            to: recipientTokenAccount,
            nHash: nHash
        )
        let mintLogAccount: PublicKey = try .findProgramAddress(seeds: [renVMMessage.keccak256], programId: program).0
        let signer = try Account(secretKey: secretKey)
        
        let mintInstruction = RenProgram.mintInstruction(
            account: signer.publicKey,
            gatewayAccount: gatewayAccountId,
            tokenMint: tokenMint,
            recipientTokenAccount: recipientTokenAccount,
            mintLogAccount: mintLogAccount,
            mintAuthority: mintAuthority,
            programId: program
        )
        
        let response: BufferInfo<GatewayStateData>? = try await apiClient.getAccountInfo(
            account: gatewayAccountId.base58EncodedString
        )
        
        guard let gatewayState = response?.data else {
            throw SolanaError.couldNotRetrieveAccountInfo
        }
        
        let secpInstruction = RenProgram.createInstructionWithEthAddress2(
            ethAddress: Data(gatewayState.renVMAuthority.bytes),
            message: renVMMessage,
            signature: sig[0..<64],
            recoveryId: sig[64] - 27
        )
        
        let preparedTransaction = try await blockchainClient.prepareTransaction(
            instructions: [
                mintInstruction,
                secpInstruction
            ],
            signers: [signer],
            feePayer: signer.publicKey,
            feeCalculator: nil
        )
        return try await blockchainClient.sendTransaction(
            preparedTransaction: preparedTransaction
        )
    }
    
    public func submitBurn(
        mintTokenSymbol: String,
        account: Data,
        amount amountString: String,
        recipient: String,
        signer: Data
    ) async throws -> BurnAndRelease.BurnDetails {
        guard let amount = UInt64(amountString) else {
            throw RenVMError("Amount is not valid")
        }
        let signer = try Account(secretKey: signer)
        let account = try PublicKey(data: account)
        let program = try resolveTokenGatewayContract(mintTokenSymbol: mintTokenSymbol)
        let tokenMint = try getSPLTokenPubkey(mintTokenSymbol: mintTokenSymbol)
        let source = try PublicKey(data: try getAssociatedTokenAddress(address: account.data, mintTokenSymbol: mintTokenSymbol))
        let gatewayAccountId = try PublicKey.findProgramAddress(seeds: [Data(gatewayStateKey.bytes)], programId: program).0
        
        let response: BufferInfo<GatewayStateData>? = try await apiClient.getAccountInfo(
            account: gatewayAccountId.base58EncodedString
        )
        
        guard let gatewayState = response?.data else {
            throw SolanaError.couldNotRetrieveAccountInfo
        }
        
        let nonce = gatewayState.burnCount + 1
        let burnLogAccountId = try PublicKey.findProgramAddress(
            seeds: [Data(nonce.bytes)],
            programId: program
        ).0
        
        let burnCheckedInstruction = TokenProgram.burnCheckedInstruction(
            mint: tokenMint,
            account: source,
            owner: account,
            amount: amount,
            decimals: 8
        )
        
        let burnInstruction = RenProgram.burnInstruction(
            account: account,
            source: source,
            gatewayAccount: gatewayAccountId,
            tokenMint: tokenMint,
            burnLogAccountId: burnLogAccountId,
            recipient: Data(recipient.bytes),
            programId: program
        )
        
        let preparedTransaction = try await blockchainClient.prepareTransaction(
            instructions: [
                burnCheckedInstruction,
                burnInstruction
            ],
            signers: [signer],
            feePayer: signer.publicKey,
            feeCalculator: nil
        )
        
        let signature = try await blockchainClient.sendTransaction(
            preparedTransaction: preparedTransaction
        )
        
        return .init(confirmedSignature: signature, nonce: nonce, recipient: recipient, amount: amountString)
    }
    
    public func findMintByDepositDetail(
        nHash: Data,
        pHash: Data,
        to: PublicKey,
        mintTokenSymbol: String,
        amount: String
    ) async throws -> String {
        let program = try resolveTokenGatewayContract(mintTokenSymbol: mintTokenSymbol)
        let sHash = Hash.generateSHash(
            selector: selector(mintTokenSymbol: mintTokenSymbol, direction: .to)
        )
        let renVMMessage = try Self.buildRenVMMessage(pHash: pHash, amount: amount, token: sHash, to: to, nHash: nHash)
        
        let mintLogAccount = try PublicKey.findProgramAddress(seeds: [renVMMessage.keccak256], programId: program).0
        let bufferInfo: BufferInfo<Mint>? = try await apiClient.getAccountInfo(account: mintLogAccount.base58EncodedString)
        guard let mint = bufferInfo?.data else {
            throw RenVMError("Invalid mint info")
        }
        
        if !mint.isInitialized {return ""}
        
        let signatures = try await apiClient.getSignaturesForAddress(
            address: mintLogAccount.base58EncodedString,
            configs: nil
        )
        
        return signatures.first?.signature ?? ""
    }
    
    public func waitForConfirmation(signature: String) async throws {
        try await apiClient.waitForConfirmation(signature: signature, ignoreStatus: true)
    }
    
    // MARK: - Static methods
    public static func buildRenVMMessage(
        pHash: Data,
        amount: String,
        token: Data,
        to: PublicKey,
        nHash: Data
    ) throws -> Data {
        // serialize amount
        let amount = BInt(amount)
        let amountBytes = amount.data.bytes
        guard amountBytes.count <= 32 else {
            throw RenVMError("The amount is not valid")
        }
        var amountData = Data(repeating: 0, count: 32 - amountBytes.count)
        amountData += amountBytes
        
        // form data
        var data = Data()
        data += pHash
        data += amountData
        data += token
        data += to.data
        data += nHash
        return data
    }
}

extension SolanaChain {
    struct GatewayStateData: BufferLayout {
        let isInitialized: Bool
        let renVMAuthority: SolanaChain.GatewayStateData.RenVMAuthority
        let selectors: SolanaChain.GatewayStateData.Selectors
        let burnCount: UInt64
        let underlyingDecimals: UInt8
        
        init(from reader: inout BinaryReader) throws {
            self.isInitialized = try .init(from: &reader)
            self.renVMAuthority = try .init(from: &reader)
            self.selectors = try .init(from: &reader)
            self.burnCount = try .init(from: &reader)
            self.underlyingDecimals = try .init(from: &reader)
        }
        
        func serialize(to writer: inout Data) throws {
            try isInitialized.serialize(to: &writer)
            try renVMAuthority.serialize(to: &writer)
            try selectors.serialize(to: &writer)
            try burnCount.serialize(to: &writer)
            try underlyingDecimals.serialize(to: &writer)
        }
        
        struct RenVMAuthority: BorshCodable, Codable {
            let bytes: [UInt8]
            
            init(from reader: inout BinaryReader) throws {
                self.bytes = try reader.read(count: 20)
            }
            
            func serialize(to writer: inout Data) throws {
                writer.append(contentsOf: bytes)
            }
        }
        
        struct Selectors: BorshCodable, Codable {
            let bytes: [UInt8]
            
            init(from reader: inout BinaryReader) throws {
                self.bytes = try reader.read(count: 32)
            }
            
            func serialize(to writer: inout Data) throws {
                writer.append(contentsOf: bytes)
            }
        }
    }
    
    struct GatewayRegistryData: BufferLayout {
        let isInitialized: Bool
        let owner: PublicKey
        let count: UInt64
        let selectors: [PublicKey]
        let gateways: [PublicKey]
        
        init(from reader: inout BinaryReader) throws {
            self.isInitialized = try .init(from: &reader)
            self.owner = try .init(from: &reader)
            self.count = try .init(from: &reader)
            self.selectors = try .init(from: &reader)
            self.gateways = try .init(from: &reader)
        }
        
        func serialize(to writer: inout Data) throws {
            try isInitialized.serialize(to: &writer)
            try owner.serialize(to: &writer)
            try count.serialize(to: &writer)
            try selectors.serialize(to: &writer)
            try gateways.serialize(to: &writer)
        }
    }
}

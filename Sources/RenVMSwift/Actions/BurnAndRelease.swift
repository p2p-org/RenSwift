import Foundation
import SolanaSwift

extension BurnAndRelease {
    public struct BurnDetails: Codable, Equatable {
        public let confirmedSignature: String
        public let nonce: UInt64
        public let recipient: String
        public let amount: String
    }
}

public struct BurnAndRelease {
    // MARK: - Dependencies
    private let rpcClient: RenVMRpcClientType
    private let chain: RenVMChainType
    private let mintTokenSymbol: String
    private let version: String
    private let burnToChainName: String // Ex.: Bitcoin
    
    // MARK: - Initializer
    public init(
        rpcClient: RenVMRpcClientType,
        chain: RenVMChainType,
        mintTokenSymbol: String,
        version: String,
        burnTo: String
    ) {
        self.rpcClient = rpcClient
        self.chain = chain
        self.mintTokenSymbol = mintTokenSymbol
        self.version = version
        self.burnToChainName = burnTo
    }
    
    public func submitBurnTransaction(
        account: Data,
        amount: String,
        recipient: String,
        signer: Data
    ) async throws -> BurnDetails {
        try await chain.submitBurn(
            mintTokenSymbol: mintTokenSymbol,
            account: account,
            amount: amount,
            recipient: recipient,
            signer: signer
        )
    }
    
    public func getBurnState(burnDetails: BurnDetails) throws -> State {
        let txid = try chain.signatureToData(signature: burnDetails.confirmedSignature)
        let nonceBuffer = getNonceBuffer(nonce: BInt(burnDetails.nonce))
        let nHash = Hash.generateNHash(nonce: nonceBuffer.bytes, txId: txid.bytes, txIndex: 0)
        let pHash = Hash.generatePHash()
        let sHash = Hash.generateSHash(
            selector: .init(
                mintTokenSymbol: mintTokenSymbol,
                chainName: burnToChainName,
                direction: .to
            )
        )
        let gHash = Hash.generateGHash(
            to: try Self.addressToBytes(
                address: burnDetails.recipient
            ).hexString,
            tokenIdentifier: sHash.toHexString(),
            nonce: nonceBuffer.bytes
        )
        
        let mintTx = MintTransactionInput(gHash: gHash, gPubkey: Data(), nHash: nHash, nonce: nonceBuffer, amount: burnDetails.amount, pHash: pHash, to: burnDetails.recipient, txIndex: "0", txid: txid)
        
        let txHash = try mintTx.hash(
            selector: chain.selector(mintTokenSymbol: mintTokenSymbol, direction: .from),
            version: version
        )
            .base64urlEncodedString()
        
        var state = State()
        state.sendTo = burnDetails.recipient
        state.txIndex = "0"
        state.amount = burnDetails.amount
        state.nHash = nHash
        state.txid = txid
        state.pHash = pHash
        state.gHash = gHash
        state.txHash = txHash
        state.gPubKey = Data()
        return state
    }
    
    public func release(state: State, details: BurnDetails) async throws -> String {
        let selector = selector(direction: .from)
        let nonceBuffer = getNonceBuffer(nonce: BInt(details.nonce))
        
        // get input
        let mintTx = try MintTransactionInput(state: state, nonce: nonceBuffer)
        let hash = try mintTx
            .hash(selector: selector, version: version)
            .base64urlEncodedString()
        
        // send transaction
        _ = try await rpcClient.submitTx(
            hash: hash,
            selector: selector,
            version: version,
            input: mintTx
        )
        return hash
    }
    
    private func getNonceBuffer(nonce: BInt) -> Data {
        var data = Data(repeating: 0, count: 32-nonce.data.count)
        data += nonce.data
        return data
    }
    
    private func selector(direction: Selector.Direction) -> Selector {
        chain.selector(mintTokenSymbol: mintTokenSymbol, direction: direction)
    }
    
    static func addressToBytes(address: String) throws -> Data {
        // For new btc address type Bech32
        if let bech32 = (try? Bech32().decode(address).checksum) {
            let type = bech32[0]
            let words = Data(bech32[1...])
            let fromWords = try convert(data: words, inBits: 5, outBits: 8, pad: false)
            var data = Data()
            data += [type]
            data += fromWords
            return data
        }
        
        // For legacy bitcoin address type P2PKH or P2SH
        else {
            return Data(Base58.decode(address))
        }
    }
    
}

private func convert(
    data: Data,
    inBits: Int32,
    outBits: Int32,
    pad: Bool
) throws -> Data {
    var value: Int32 = 0
    var bits: Int32 = 0
    let maxV: Int32 = (1 << outBits) - 1
    
    var result = Data()
    
    for i in 0..<data.count {
        value = (value << inBits) | Int32(data[i])
        bits += inBits
        
        while bits >= outBits {
            bits -= outBits

            let byte = UInt8(value >> bits & maxV)
            result.append(byte)
        }
        
    }
    if pad {
        if bits > 0 {
            result.append(UInt8((value << (outBits - bits)) & maxV))
        }
    } else {
        if bits >= inBits {throw RenVMError("Excess padding")}
    }
    return result
}

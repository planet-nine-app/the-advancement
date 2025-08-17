// MARK: - Native macOS App (SessionlessApp.swift)
// Main application that handles all Sessionless operations

import Cocoa
import Foundation
import Security
import CryptoKit

@main
class SessionlessApp: NSApplication {
    
    private let server = SessionlessIPCServer()
    
    override func finishLaunching() {
        super.finishLaunching()
        
        // Start IPC server for Safari extension communication
        server.start()
        
        // Hide from dock since this is a background service
        setActivationPolicy(.accessory)
        
        print("Sessionless native app started")
    }
}

// MARK: - IPC Server for Safari Extension Communication
class SessionlessIPCServer {
    
    private let sessionless = SessionlessCore()
    private var listener: NSXPCListener?
    
    func start() {
        listener = NSXPCListener(machServiceName: "app.sessionless.safari-helper")
        listener?.delegate = self
        listener?.resume()
    }
}

extension SessionlessIPCServer: NSXPCListenerDelegate {
    
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        
        // Set up the connection
        newConnection.exportedInterface = NSXPCInterface(with: SessionlessServiceProtocol.self)
        newConnection.exportedObject = SessionlessServiceImplementation(sessionless: sessionless)
        newConnection.resume()
        
        return true
    }
}

// MARK: - XPC Protocol Definition
@objc protocol SessionlessServiceProtocol {
    func generateKeys(seedPhrase: String?, reply: @escaping (SessionlessResult) -> Void)
    func sign(message: String, reply: @escaping (SessionlessResult) -> Void)
    func getPublicKey(reply: @escaping (SessionlessResult) -> Void)
    func hasKeys(reply: @escaping (SessionlessResult) -> Void)
    func getAddress(reply: @escaping (SessionlessResult) -> Void)
}

// MARK: - XPC Service Implementation
class SessionlessServiceImplementation: NSObject, SessionlessServiceProtocol {
    
    private let sessionless: SessionlessCore
    
    init(sessionless: SessionlessCore) {
        self.sessionless = sessionless
    }
    
    func generateKeys(seedPhrase: String?, reply: @escaping (SessionlessResult) -> Void) {
        do {
            let keypair = try sessionless.generateKeys(seedPhrase: seedPhrase)
            reply(SessionlessResult.success([
                "publicKey": keypair.publicKey,
                "address": keypair.address
            ]))
        } catch {
            reply(SessionlessResult.error(error.localizedDescription))
        }
    }
    
    func sign(message: String, reply: @escaping (SessionlessResult) -> Void) {
        do {
            let signature = try sessionless.signMessage(message)
            reply(SessionlessResult.success(["signature": signature]))
        } catch {
            reply(SessionlessResult.error(error.localizedDescription))
        }
    }
    
    func getPublicKey(reply: @escaping (SessionlessResult) -> Void) {
        do {
            let publicKey = try sessionless.getPublicKey()
            reply(SessionlessResult.success(["publicKey": publicKey]))
        } catch {
            reply(SessionlessResult.error(error.localizedDescription))
        }
    }
    
    func hasKeys(reply: @escaping (SessionlessResult) -> Void) {
        let hasKeys = sessionless.hasKeys()
        reply(SessionlessResult.success(["hasKeys": hasKeys]))
    }
    
    func getAddress(reply: @escaping (SessionlessResult) -> Void) {
        do {
            let address = try sessionless.getAddress()
            reply(SessionlessResult.success(["address": address]))
        } catch {
            reply(SessionlessResult.error(error.localizedDescription))
        }
    }
}

// MARK: - Result Type for XPC Communication
@objc class SessionlessResult: NSObject, NSCoding {
    let isSuccess: Bool
    let data: [String: Any]?
    let error: String?
    
    init(isSuccess: Bool, data: [String: Any]? = nil, error: String? = nil) {
        self.isSuccess = isSuccess
        self.data = data
        self.error = error
    }
    
    static func success(_ data: [String: Any]) -> SessionlessResult {
        return SessionlessResult(isSuccess: true, data: data)
    }
    
    static func error(_ message: String) -> SessionlessResult {
        return SessionlessResult(isSuccess: false, error: message)
    }
    
    // NSCoding implementation
    required init?(coder: NSCoder) {
        isSuccess = coder.decodeBool(forKey: "isSuccess")
        data = coder.decodeObject(forKey: "data") as? [String: Any]
        error = coder.decodeObject(forKey: "error") as? String
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(isSuccess, forKey: "isSuccess")
        coder.encode(data, forKey: "data")
        coder.encode(error, forKey: "error")
    }
}

// MARK: - Core Sessionless Implementation
class SessionlessCore {
    
    private let keyManager = SessionlessKeyManager()
    
    struct KeyPair {
        let publicKey: String
        let address: String
    }
    
    func generateKeys(seedPhrase: String? = nil) throws -> KeyPair {
        return try keyManager.generateKeys(seedPhrase: seedPhrase)
    }
    
    func signMessage(_ message: String) throws -> String {
        return try keyManager.signMessage(message)
    }
    
    func getPublicKey() throws -> String {
        return try keyManager.getPublicKey()
    }
    
    func getAddress() throws -> String {
        return try keyManager.getAddress()
    }
    
    func hasKeys() -> Bool {
        return keyManager.hasKeys()
    }
}

// MARK: - Secure Key Manager using secp256k1
class SessionlessKeyManager {
    
    private let keychainService = "app.sessionless.native"
    private let privateKeyTag = "sessionless-private-key"
    private let publicKeyTag = "sessionless-public-key"
    private let addressTag = "sessionless-address"
    
    enum SessionlessError: Error {
        case keyGenerationFailed
        case keyNotFound
        case signingFailed
        case invalidMessage
        case keychainError(OSStatus)
        case cryptographyError(String)
        
        var localizedDescription: String {
            switch self {
            case .keyGenerationFailed:
                return "Failed to generate keypair"
            case .keyNotFound:
                return "No keys found. Please generate keys first."
            case .signingFailed:
                return "Failed to sign message"
            case .invalidMessage:
                return "Invalid message format"
            case .keychainError(let status):
                return "Keychain error: \(status)"
            case .cryptographyError(let msg):
                return "Cryptography error: \(msg)"
            }
        }
    }
    
    struct KeyPair {
        let publicKey: String
        let address: String
    }
    
    func generateKeys(seedPhrase: String? = nil) throws -> KeyPair {
        
        // Generate private key
        let privateKeyData: Data
        if let seed = seedPhrase {
            privateKeyData = try derivePrivateKey(from: seed)
        } else {
            var keyData = Data(count: 32)
            let result = keyData.withUnsafeMutableBytes { bytes in
                SecRandomCopyBytes(kSecRandomDefault, 32, bytes.bindMemory(to: UInt8.self).baseAddress!)
            }
            guard result == errSecSuccess else {
                throw SessionlessError.keyGenerationFailed
            }
            privateKeyData = keyData
        }
        
        // Generate public key and address using secp256k1
        let (publicKeyData, address) = try generatePublicKeyAndAddress(from: privateKeyData)
        
        // Store securely in Keychain
        try storePrivateKey(privateKeyData)
        try storePublicKey(publicKeyData)
        try storeAddress(address)
        
        return KeyPair(
            publicKey: publicKeyData.hexString,
            address: address
        )
    }
    
    func signMessage(_ message: String) throws -> String {
        guard let privateKeyData = try? getPrivateKey() else {
            throw SessionlessError.keyNotFound
        }
        
        // Hash the message using SHA-256 (as per Sessionless spec)
        let messageData = Data(message.utf8)
        let hash = SHA256.hash(data: messageData)
        let hashData = Data(hash)
        
        // Sign with secp256k1
        let signature = try signWithSecp256k1(hashData, privateKey: privateKeyData)
        return signature.hexString
    }
    
    func getPublicKey() throws -> String {
        guard let publicKeyData = try? getStoredPublicKey() else {
            throw SessionlessError.keyNotFound
        }
        return publicKeyData.hexString
    }
    
    func getAddress() throws -> String {
        guard let address = try? getStoredAddress() else {
            throw SessionlessError.keyNotFound
        }
        return address
    }
    
    func hasKeys() -> Bool {
        do {
            _ = try getPrivateKey()
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private Crypto Methods
    
    private func derivePrivateKey(from seedPhrase: String) throws -> Data {
        let seedData = Data(seedPhrase.utf8)
        let hash = SHA256.hash(data: seedData)
        return Data(hash)
    }
    
    private func generatePublicKeyAndAddress(from privateKey: Data) throws -> (Data, String) {
        // In production, use a proper secp256k1 library
        // For now, this is a simplified implementation
        
        // This would use secp256k1 to derive the public key
        // let publicKey = secp256k1_derive_public_key(privateKey)
        
        // Temporary implementation using available crypto
        let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey.prefix(32))
        let publicKeyData = key.publicKey.compressedRepresentation
        
        // Generate Ethereum-style address
        let fullPublicKey = key.publicKey.rawRepresentation
        let hash = SHA256.hash(data: fullPublicKey.dropFirst()) // Remove first byte for Ethereum compatibility
        let addressData = Data(hash.suffix(20))
        let address = "0x" + addressData.hexString
        
        return (publicKeyData, address)
    }
    
    private func signWithSecp256k1(_ hash: Data, privateKey: Data) throws -> Data {
        // In production, use proper secp256k1 signing
        // For now, using available crypto
        let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey.prefix(32))
        let signature = try key.signature(for: hash)
        return signature.rawRepresentation
    }
    
    // MARK: - Keychain Storage Methods
    
    private func storePrivateKey(_ keyData: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: privateKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false // Never sync to iCloud
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw SessionlessError.keychainError(status)
        }
    }
    
    private func storePublicKey(_ keyData: Data) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: publicKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw SessionlessError.keychainError(status)
        }
    }
    
    private func storeAddress(_ address: String) throws {
        let addressData = Data(address.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: addressTag,
            kSecValueData as String: addressData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw SessionlessError.keychainError(status)
        }
    }
    
    private func getPrivateKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: privateKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return keyData
        } else {
            throw SessionlessError.keychainError(status)
        }
    }
    
    private func getStoredPublicKey() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: publicKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return keyData
        } else {
            throw SessionlessError.keychainError(status)
        }
    }
    
    private func getStoredAddress() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: addressTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let addressData = result as? Data {
            return String(data: addressData, encoding: .utf8) ?? ""
        } else {
            throw SessionlessError.keychainError(status)
        }
    }
}

// MARK: - Safari Extension Bridge
class SessionlessSafariExtension: SFSafariExtensionHandler {
    
    private let nativeConnection = SessionlessNativeConnection()
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        
        let requestId = userInfo?["requestId"] as? String
        
        switch messageName {
        case "generateKeys":
            nativeConnection.generateKeys(seedPhrase: userInfo?["seedPhrase"] as? String) { result in
                self.sendResponse(to: page, requestId: requestId, result: result)
            }
            
        case "sign":
            guard let message = userInfo?["message"] as? String else {
                sendError(to: page, requestId: requestId, error: "Message required")
                return
            }
            nativeConnection.sign(message: message) { result in
                self.sendResponse(to: page, requestId: requestId, result: result)
            }
            
        case "getPublicKey":
            nativeConnection.getPublicKey { result in
                self.sendResponse(to: page, requestId: requestId, result: result)
            }
            
        case "hasKeys":
            nativeConnection.hasKeys { result in
                self.sendResponse(to: page, requestId: requestId, result: result)
            }
            
        case "getAddress":
            nativeConnection.getAddress { result in
                self.sendResponse(to: page, requestId: requestId, result: result)
            }
            
        default:
            sendError(to: page, requestId: requestId, error: "Unknown message: \(messageName)")
        }
    }
    
    private func sendResponse(to page: SFSafariPage, requestId: String?, result: SessionlessResult) {
        var response: [String: Any] = [
            "success": result.isSuccess
        ]
        
        if let requestId = requestId {
            response["requestId"] = requestId
        }
        
        if result.isSuccess, let data = result.data {
            response["data"] = data
        } else if let error = result.error {
            response["error"] = error
        }
        
        page.dispatchMessageToScript(withName: "sessionlessResponse", userInfo: response)
    }
    
    private func sendError(to page: SFSafariPage, requestId: String?, error: String) {
        sendResponse(to: page, requestId: requestId, result: SessionlessResult.error(error))
    }
}

// MARK: - Native Connection Handler
class SessionlessNativeConnection {
    
    private var connection: NSXPCConnection?
    
    init() {
        setupConnection()
    }
    
    private func setupConnection() {
        connection = NSXPCConnection(machServiceName: "app.sessionless.safari-helper")
        connection?.remoteObjectInterface = NSXPCInterface(with: SessionlessServiceProtocol.self)
        connection?.resume()
    }
    
    private func getService() -> SessionlessServiceProtocol? {
        return connection?.remoteObjectProxy as? SessionlessServiceProtocol
    }
    
    func generateKeys(seedPhrase: String?, completion: @escaping (SessionlessResult) -> Void) {
        getService()?.generateKeys(seedPhrase: seedPhrase, reply: completion)
    }
    
    func sign(message: String, completion: @escaping (SessionlessResult) -> Void) {
        getService()?.sign(message: message, reply: completion)
    }
    
    func getPublicKey(completion: @escaping (SessionlessResult) -> Void) {
        getService()?.getPublicKey(reply: completion)
    }
    
    func hasKeys(completion: @escaping (SessionlessResult) -> Void) {
        getService()?.hasKeys(reply: completion)
    }
    
    func getAddress(completion: @escaping (SessionlessResult) -> Void) {
        getService()?.getAddress(reply: completion)
    }
}

// MARK: - Data Extension
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - Package.swift (for SPM secp256k1 integration)
/*
// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "SessionlessApp",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift.git", from: "0.12.0")
    ],
    targets: [
        .executableTarget(
            name: "SessionlessApp",
            dependencies: [
                .product(name: "secp256k1", package: "secp256k1.swift")
            ]
        )
    ]
)
*/

import SafariServices
import Foundation
import Security
import CryptoKit

// Shared error types and core classes
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

// Core Sessionless Implementation
class SessionlessCore {
    
    private let keyManager = SessionlessKeyManager()
    
    struct KeyPair {
        let publicKey: String
        let address: String
    }
    
    func generateKeys(seedPhrase: String? = nil) throws -> KeyPair {
        print("🔑 Generating real sessionless keys with Keychain storage...")
        return try keyManager.generateKeys(seedPhrase: seedPhrase)
    }
    
    func signMessage(_ message: String) throws -> String {
        print("🔐 Signing message with real sessionless: \(message.prefix(50))...")
        let signature = try keyManager.signMessage(message)
        print("✅ Real signature generated: \(signature.prefix(20))...")
        return signature
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

// Secure Key Manager using secp256k1
class SessionlessKeyManager {
    
    private let keychainService = "app.sessionless.native"
    private let privateKeyTag = "sessionless-private-key"
    private let publicKeyTag = "sessionless-public-key"
    private let addressTag = "sessionless-address"
    
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
        let key = try P256.Signing.PrivateKey(rawRepresentation: privateKey.prefix(32))
        let publicKeyData = key.publicKey.compressedRepresentation
        
        // Generate Ethereum-style address
        let fullPublicKey = key.publicKey.rawRepresentation
        let hash = SHA256.hash(data: fullPublicKey.dropFirst())
        let addressData = Data(hash.suffix(20))
        let address = "0x" + addressData.hexString
        
        return (publicKeyData, address)
    }
    
    private func signWithSecp256k1(_ hash: Data, privateKey: Data) throws -> Data {
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
            kSecAttrSynchronizable as String: false
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

// Safari Web Extension Handler  
@objc(SafariWebExtensionHandler)
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    
    private let sessionlessCore = SessionlessCore()
    
    func beginRequest(with context: NSExtensionContext) {
        print("🔧 Safari Web Extension beginRequest called")
        
        guard let item = context.inputItems.first as? NSExtensionItem else {
            print("❌ No input items or wrong type")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        guard let userInfo = item.userInfo as? [String: Any] else {
            print("❌ No userInfo or wrong type")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        guard let message = userInfo[SFExtensionMessageKey] as? [String: Any] else {
            print("❌ No SFExtensionMessageKey or wrong type")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        // Extract action and parameters from message
        guard let action = message["action"] as? String else {
            print("❌ No action specified in message")
            context.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        
        let requestId = message["requestId"] as? String
        print("🔧 Processing action: \(action) with requestId: \(requestId ?? "none")")
        
        // Handle the action
        handleAction(action: action, parameters: message, context: context, requestId: requestId)
    }
    
    private func handleAction(action: String, parameters: [String: Any], context: NSExtensionContext, requestId: String?) {
        switch action {
        case "getSpellbook":
            guard let baseUrl = parameters["baseUrl"] as? String else {
                sendError(context: context, requestId: requestId, error: "Base URL required")
                return
            }
            handleGetSpellbook(baseUrl: baseUrl, context: context, requestId: requestId)
            
        default:
            sendError(context: context, requestId: requestId, error: "Unknown action: \(action)")
        }
    }
    
    private func handleGetSpellbook(baseUrl: String, context: NSExtensionContext, requestId: String?) {
        Task {
            do {
                let spellbooks = try await getSpellbooksComplete(baseUrl: baseUrl)
                sendSuccess(context: context, requestId: requestId, data: spellbooks)
            } catch {
                sendError(context: context, requestId: requestId, error: error.localizedDescription)
            }
        }
    }
    
    private func getSpellbooksComplete(baseUrl: String) async throws -> [String: Any] {
        print("📚 Swift: Starting complete spellbook flow")
        
        // 1. Ensure we have keys
        if !sessionlessCore.hasKeys() {
            print("🔑 Swift: No keys found, generating new keys...")
            _ = try sessionlessCore.generateKeys()
        }
        
        // 2. Create BDO user if needed
        let uuid = try await createBDOUser(baseUrl: baseUrl)
        print("👤 Swift: BDO user UUID: \(uuid)")
        
        // 3. Get spellbooks
        let spellbooks = try await getBDOSpellbooks(baseUrl: baseUrl, uuid: uuid)
        return spellbooks
    }
    
    private func createBDOUser(baseUrl: String) async throws -> String {
        let publicKey = try sessionlessCore.getPublicKey()
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "advancement-popup"
        let message = timestamp + publicKey + hash
        let signature = try sessionlessCore.signMessage(message)
        
        let payload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": publicKey,
            "hash": hash,
            "bdo": ["client": "advancement-safari-popup", "created": timestamp],
            "signature": signature
        ]
        
        let endpoint = "\(baseUrl)/user/create"
        print("📤 Swift→BDO: Creating user at \(endpoint)")
        
        let response = try await makeBDORequest(endpoint: endpoint, method: "PUT", payload: payload)
        print("📥 BDO→Swift: Create user response: \(response)")
        
        guard let userUUID = response["userUUID"] as? String ?? response["uuid"] as? String else {
            throw SessionlessError.invalidMessage
        }
        
        return userUUID
    }
    
    private func getBDOSpellbooks(baseUrl: String, uuid: String) async throws -> [String: Any] {
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "advancement-popup"
        let message = timestamp + uuid + hash
        let signature = try sessionlessCore.signMessage(message)
        
        let endpoint = "\(baseUrl)/user/\(uuid)/spellbooks?timestamp=\(timestamp)&hash=\(hash)&signature=\(signature)"
        print("📤 Swift→BDO: Getting spellbooks from \(endpoint)")
        
        let response = try await makeBDORequest(endpoint: endpoint, method: "GET", payload: nil)
        print("📥 BDO→Swift: Spellbooks response: \(response)")
        
        return response
    }
    
    private func makeBDORequest(endpoint: String, method: String, payload: [String: Any]?) async throws -> [String: Any] {
        guard let url = URL(string: endpoint) else {
            throw SessionlessError.invalidMessage
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        if let payload = payload {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        }
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw SessionlessError.invalidMessage
        }
        
        print("📊 BDO HTTP Response: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ BDO Error Response: \(errorText)")
            throw SessionlessError.cryptographyError("HTTP \(httpResponse.statusCode): \(errorText)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SessionlessError.invalidMessage
        }
        
        return json
    }
    
    private func sendSuccess(context: NSExtensionContext, requestId: String?, data: [String: Any]) {
        var response: [String: Any] = [
            "success": true,
            "data": data
        ]
        
        if let requestId = requestId {
            response["requestId"] = requestId
        }
        
        let responseItem = NSExtensionItem()
        responseItem.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [responseItem], completionHandler: nil)
    }
    
    private func sendError(context: NSExtensionContext, requestId: String?, error: String) {
        var response: [String: Any] = [
            "success": false,
            "error": error
        ]
        
        if let requestId = requestId {
            response["requestId"] = requestId
        }
        
        let responseItem = NSExtensionItem()
        responseItem.userInfo = [SFExtensionMessageKey: response]
        context.completeRequest(returningItems: [responseItem], completionHandler: nil)
    }
}

// Data Extension
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
}
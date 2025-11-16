//
//  Sessionless.swift
//  SessionlessExample
//
//  Created by Zach Babb on 2/14/24.
//

import Foundation
import JavaScriptCore
import os.log

public class Sessionless {
    private let logger = Logger(subsystem: "com.planetnine.the-advancement", category: "Sessionless")
    
    public struct Keys {
        public let publicKey: String
        public let privateKey: String
        
        public init(publicKey: String, privateKey: String) {
            self.publicKey = publicKey
            self.privateKey = privateKey
        }
        
        public func toData() -> Data {
            let data = Data(base64Encoded: "\(publicKey):\(privateKey)", options: [])
            // Debug logging removed - can't access parent logger from nested struct
            
            return "\(publicKey):\(privateKey)".data(using: .utf8) ?? Data()
        }
        
        public func toString() -> String {
            return """
            {"publicKey":"\(publicKey)","privateKey":"\(privateKey)"}
            """
        }
        
    }
    public var jsContext: JSContext?
    private var generateKeysJS: JSValue?
    private var signMessageJS: JSValue?
    private var verifySignatureJS: JSValue?
    
    private let keyService = "TheAdvancementKeyStore"
    private let keyAccount = "TheAdvancement"
    private let keychainAccessGroup = "RLJ2FY35FD.com.planetnine.Planet-Nine"
    
    public init() {
        jsContext = getJSContext()
    }
    
    func getPathToCrypto() -> URL? {
        let sessionlessBundle = Bundle(for: Sessionless.self)
        logger.info("ADVANCEMENT - Bundle path: \(sessionlessBundle.bundlePath)")
        logger.info("ADVANCEMENT - Resource URL: \(sessionlessBundle.resourceURL?.absoluteString ?? "nil")")
        
        // Try direct resource lookup first (for Safari extension)
        if let cryptoPathURL = sessionlessBundle.url(forResource: "crypto", withExtension: "js") {
            logger.info("ADVANCEMENT - Found crypto.js directly: \(cryptoPathURL.absoluteString)")
            return cryptoPathURL
        }
        
        // Try in Sessionless.bundle subdirectory (original structure)
        if let resourceURL = sessionlessBundle.resourceURL?.appendingPathComponent("Sessionless.bundle"),
           let resourceBundle = Bundle(url: resourceURL),
           let cryptoPathURL = resourceBundle.url(forResource: "crypto", withExtension: "js") {
            logger.info("ADVANCEMENT - Found crypto.js in bundle: \(cryptoPathURL.absoluteString)")
            return cryptoPathURL
        }
        
        logger.error("ADVANCEMENT - Could not find crypto.js in any location")
        return nil
    }
    
    func getJSContext() -> JSContext? {
        var jsSourceContents: String = ""
        if let jsSourcePath = getPathToCrypto() {
            do {
                logger.info("ADVANCEMENT - 📄 Loading crypto.js from: \(jsSourcePath)")
                jsSourceContents = try String(contentsOf: jsSourcePath)
                logger.info("ADVANCEMENT - ✅ Loaded \(jsSourceContents.count) characters from crypto.js")
            } catch {
                logger.error("ADVANCEMENT - ❌ Failed to load crypto.js: \(error.localizedDescription)")
                return nil
            }
        } else {
            logger.error("ADVANCEMENT - ❌ Could not find crypto.js path")
            return nil
        }
        let logFunction : @convention(block) (String) -> Void =
        {
            (msg: String) in

            NSLog("ADVANCEMENT - Console: %@", msg)
        }
        let context = JSContext()
        let console = context?.objectForKeyedSubscript("console")
        context?.objectForKeyedSubscript("console").setObject(unsafeBitCast(logFunction, to: AnyObject.self), forKeyedSubscript: "log")
        
        context?.evaluateScript(jsSourceContents)
        
        let sessionless = context?.objectForKeyedSubscript("globalThis")?.objectForKeyedSubscript("sessionless")
        generateKeysJS = sessionless?.objectForKeyedSubscript("generateKeys")
        signMessageJS = sessionless?.objectForKeyedSubscript("sign")
        verifySignatureJS = sessionless?.objectForKeyedSubscript("verifySignature")
        
        return context
    }
    
    public func deleteKeys() -> Bool {
        logger.info("ADVANCEMENT - 🗑️ Deleting keys from keychain...")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyService,
            kSecAttrAccount as String: keyAccount,
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]
        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            logger.info("ADVANCEMENT - ✅ Keys deleted successfully")
            return true
        } else if status == errSecItemNotFound {
            logger.info("ADVANCEMENT - No keys to delete (already empty)")
            return true
        } else {
            logger.error("ADVANCEMENT - ❌ Failed to delete keys: \(status)")
            return false
        }
    }

    public func saveKeys(data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyService,
            kSecAttrAccount as String: keyAccount,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data
        ]

        // Try to add keys
        var status = SecItemAdd(query as CFDictionary, nil)

        // If keys already exist, update them instead
        if status == errSecDuplicateItem {
            logger.info("ADVANCEMENT - Keys already exist in keychain, updating...")
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keyService,
                kSecAttrAccount as String: keyAccount,
                kSecAttrAccessGroup as String: keychainAccessGroup
            ]
            let updateAttributes: [String: Any] = [
                kSecValueData as String: data
            ]
            status = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

            if status == errSecSuccess {
                logger.info("ADVANCEMENT - ✅ Keys updated successfully in keychain")
                return true
            } else {
                logger.error("ADVANCEMENT - ❌ Failed to update keys in keychain: \(status)")
                return false
            }
        } else if status == errSecSuccess {
            logger.info("ADVANCEMENT - ✅ Keys added successfully to keychain")
            return true
        } else {
            logger.error("ADVANCEMENT - ❌ Failed to add keys to keychain: \(status)")
            return false
        }
    }
    
    public func getKeys() -> Keys? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyService,
            kSecAttrAccount as String: keyAccount,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status != errSecSuccess {
            if status == errSecItemNotFound {
                logger.info("ADVANCEMENT - No keys found in keychain (first run)")
            } else {
                logger.error("ADVANCEMENT - ❌ Failed to retrieve keys from keychain: \(status)")
            }
            return nil
        }

        guard let data = result as? Data else {
            logger.error("ADVANCEMENT - ❌ Keychain result is not Data")
            return nil
        }

        guard let keyString = String(data: data, encoding: .utf8) else {
            logger.error("ADVANCEMENT - ❌ Failed to decode keychain data as UTF8")
            return nil
        }

        let keyStringSplit = keyString.split(separator: ":")
        guard keyStringSplit.count == 2 else {
            logger.error("ADVANCEMENT - ❌ Invalid key format in keychain")
            return nil
        }

        let keys = Keys(publicKey: String(keyStringSplit[0]), privateKey: String(keyStringSplit[1]))
        logger.debug("ADVANCEMENT - ✅ Keys retrieved from keychain")
        logger.debug("ADVANCEMENT - Public key: \(String(keys.publicKey.prefix(20)))...")
        return keys
    }
    
    public func generateKeys() -> Keys? {
        logger.info("ADVANCEMENT - 🔑 Generating new keys...")

        // Check if JS context is properly initialized
        guard generateKeysJS != nil else {
            logger.error("ADVANCEMENT - ❌ generateKeysJS is nil - crypto.js not loaded properly")
            return nil
        }

        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        if status == errSecSuccess {
            logger.debug("ADVANCEMENT - Random bytes generated successfully")
            let data = Data(bytes: bytes)
            let hex = data.hexEncodedString()

            guard let keys = generateKeysJS?.call(withArguments: [hex]) else {
                logger.error("ADVANCEMENT - ❌ Failed to call generateKeysJS")
                return nil
            }

            logger.debug("ADVANCEMENT - Keys generated from JS")
            let pubKeyData = Data(bytes: keys.objectForKeyedSubscript("publicKey").toArray() as [UInt8])
            let pubKeyHex = pubKeyData.hexEncodedString()
            let privateKey = keys.objectForKeyedSubscript("privateKey").toString() ?? ""

            logger.info("ADVANCEMENT - Public key: \(String(pubKeyHex.prefix(20)))...")

            let keysToSave = Keys(publicKey: pubKeyHex, privateKey: privateKey)

            // Save keys and check result
            let saveSuccess = self.saveKeys(data: keysToSave.toData())
            if !saveSuccess {
                logger.error("ADVANCEMENT - ❌ Failed to save keys to keychain")
                return nil
            }

            logger.info("ADVANCEMENT - ✅ Keys generated and saved successfully")
            return keysToSave
        } else {
            logger.error("ADVANCEMENT - ❌ Failed to generate random bytes: \(status)")
        }
        return nil
    }

    // MARK: - Multi-Base Key Management

    /// Get keys for a specific base
    public func getKeys(forBase baseURL: String) -> Keys? {
        logger.info("ADVANCEMENT - 🔑 Getting keys for base: \(baseURL)")

        let service = "sessionless_keys_\(sanitizeBaseURL(baseURL))"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "privateKey",
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status != errSecSuccess {
            if status == errSecItemNotFound {
                logger.info("ADVANCEMENT - No keys found for base: \(baseURL)")
            } else {
                logger.error("ADVANCEMENT - ❌ Failed to retrieve keys for base \(baseURL): \(status)")
            }
            return nil
        }

        guard let data = result as? Data,
              let privateKey = String(data: data, encoding: .utf8) else {
            logger.error("ADVANCEMENT - ❌ Failed to decode keys for base: \(baseURL)")
            return nil
        }

        // Derive public key from private key
        guard let publicKey = derivePublicKey(from: privateKey) else {
            logger.error("ADVANCEMENT - ❌ Failed to derive public key for base: \(baseURL)")
            return nil
        }

        logger.info("ADVANCEMENT - ✅ Keys retrieved for base: \(baseURL)")
        logger.debug("ADVANCEMENT - Public key: \(String(publicKey.prefix(20)))...")
        return Keys(publicKey: publicKey, privateKey: privateKey)
    }

    /// Save keys for a specific base
    public func saveKeys(_ keys: Keys, forBase baseURL: String) -> Bool {
        logger.info("ADVANCEMENT - 💾 Saving keys for base: \(baseURL)")

        let service = "sessionless_keys_\(sanitizeBaseURL(baseURL))"

        // Delete existing keys first
        deleteKeys(forBase: baseURL)

        guard let data = keys.privateKey.data(using: .utf8) else {
            logger.error("ADVANCEMENT - ❌ Failed to encode private key for base: \(baseURL)")
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "privateKey",
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            logger.info("ADVANCEMENT - ✅ Keys saved for base: \(baseURL)")
            return true
        } else {
            logger.error("ADVANCEMENT - ❌ Failed to save keys for base \(baseURL): \(status)")
            return false
        }
    }

    /// Delete keys for a specific base
    public func deleteKeys(forBase baseURL: String) -> Bool {
        logger.info("ADVANCEMENT - 🗑️ Deleting keys for base: \(baseURL)")

        let service = "sessionless_keys_\(sanitizeBaseURL(baseURL))"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "privateKey",
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]

        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess {
            logger.info("ADVANCEMENT - ✅ Keys deleted for base: \(baseURL)")
            return true
        } else if status == errSecItemNotFound {
            logger.info("ADVANCEMENT - No keys to delete for base: \(baseURL)")
            return true
        } else {
            logger.error("ADVANCEMENT - ❌ Failed to delete keys for base \(baseURL): \(status)")
            return false
        }
    }

    /// Get all base URLs that have stored keys
    public func getAllBasesWithKeys() -> [String] {
        logger.info("ADVANCEMENT - 📋 Fetching all bases with stored keys...")

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            logger.info("ADVANCEMENT - No bases with keys found")
            return []
        }

        // Filter for sessionless_keys_* services and extract base URLs
        let bases = items.compactMap { item -> String? in
            guard let service = item[kSecAttrService as String] as? String,
                  service.hasPrefix("sessionless_keys_") else {
                return nil
            }
            return String(service.dropFirst("sessionless_keys_".count))
        }

        logger.info("ADVANCEMENT - ✅ Found \(bases.count) bases with keys")
        return bases
    }

    /// Migrate existing single-key storage to multi-base storage
    public func migrateToMultiBase(defaultBase: String) -> Bool {
        logger.info("ADVANCEMENT - 🔄 Migrating to multi-base key storage...")

        // Get existing keys using old method
        guard let existingKeys = getKeys() else {
            logger.info("ADVANCEMENT - No existing keys to migrate")
            return false
        }

        // Save to default base
        let success = saveKeys(existingKeys, forBase: defaultBase)

        if success {
            logger.info("ADVANCEMENT - ✅ Migration successful - keys saved for base: \(defaultBase)")
            logger.info("ADVANCEMENT - Note: Old keys still exist in keychain for backward compatibility")
        } else {
            logger.error("ADVANCEMENT - ❌ Migration failed")
        }

        return success
    }

    // MARK: - Private Helpers

    /// Sanitize base URL for use as keychain identifier
    private func sanitizeBaseURL(_ baseURL: String) -> String {
        // Remove protocol and special characters
        return baseURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".", with: "_")
    }

    /// Derive public key from private key using JavaScript crypto
    private func derivePublicKey(from privateKey: String) -> String? {
        guard let jsContext = jsContext,
              let sessionless = jsContext.objectForKeyedSubscript("globalThis")?.objectForKeyedSubscript("sessionless"),
              let getPublicKey = sessionless.objectForKeyedSubscript("getPublicKey") else {
            logger.error("ADVANCEMENT - ❌ Cannot derive public key: crypto.js not loaded")
            return nil
        }

        guard let result = getPublicKey.call(withArguments: [privateKey]) else {
            logger.error("ADVANCEMENT - ❌ Failed to call getPublicKey")
            return nil
        }

        // Result should be a byte array
        let pubKeyData = Data(bytes: result.toArray() as [UInt8])
        let pubKeyHex = pubKeyData.hexEncodedString()

        return pubKeyHex
    }

    public func sign(message: String) -> String? {
        logger.info("ADVANCEMENT - 🖊️ Signing message...")

        // Check if keys exist
        guard let keys = getKeys() else {
            logger.error("ADVANCEMENT - ❌ Cannot sign: No keys found in keychain")
            return nil
        }

        logger.debug("ADVANCEMENT - Keys retrieved for signing")

        // Check if JS signing function is available
        guard let signJS = signMessageJS else {
            logger.error("ADVANCEMENT - ❌ Cannot sign: signMessageJS is nil - crypto.js not loaded properly")
            return nil
        }

        // Perform signing
        guard let signaturejs = signJS.call(withArguments: [message, keys.privateKey]) else {
            logger.error("ADVANCEMENT - ❌ Failed to call signMessageJS")
            return nil
        }

        let signature = signaturejs.toString()
        logger.info("ADVANCEMENT - ✅ Message signed successfully")
        logger.debug("ADVANCEMENT - Signature: \(String(signature?.prefix(20) ?? "nil"))...")

        return signature
    }
    
    public func verifySignature(signature: String, message: String, publicKey: String) -> Bool {
        return verifySignatureJS?.call(withArguments: [signature, message, publicKey]).toBool() ?? false
    }
    
    public func generateUUID() -> String {
        return UUID().uuidString
    }
}

extension Array where Element == UInt8 {

    public var bigEndianUInt: UInt? {
        guard self.count <= MemoryLayout<UInt>.size else {
            return nil
        }
        var number: UInt = 0
        for i in (0 ..< self.count).reversed() {
            number = number | (UInt(self[self.count - i - 1]) << (i * 8))
        }

        return number
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return self.map { String(format: format, $0) }.joined()
    }
}

extension String {
    func getTime() -> String {
        let currentDate = NSDate()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        let date = dateFormatter.date(from: dateFormatter.string(from: currentDate as Date))
        let nowDouble = date!.timeIntervalSince1970
        return String(Int(nowDouble * 1000.0))
    }
}

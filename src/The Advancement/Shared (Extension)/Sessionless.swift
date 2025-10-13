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
    private let keychainAccessGroup = "com.planetnine.Planet-Nine"
    
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
    
    public func saveKeys(data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyService,
            kSecAttrAccount as String: keyAccount,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data
        ]
        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
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
        if result == nil {
            return nil
        }
        if let data = result.unsafelyUnwrapped as? Data,
           let keyString = String(data: data, encoding: .utf8) {
            let keyStringSplit = keyString.split(separator: ":")
            let keys = Keys(publicKey: String(keyStringSplit[0]), privateKey: String(keyStringSplit[1]))
            return keys
        }
        return nil
    }
    
    public func generateKeys() -> Keys? {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        if status == errSecSuccess { 
            logger.debug("ADVANCEMENT - Random bytes: \(bytes)")
            let data = Data(bytes: bytes)
            let hex = data.hexEncodedString()
            let keys = generateKeysJS?.call(withArguments: [hex])
            logger.debug("ADVANCEMENT - Generated keys: \(String(describing: keys))")
            logger.debug("ADVANCEMENT - Private key: \(String(describing: keys?.objectForKeyedSubscript("privateKey")))")
            let pubKeyData = Data(bytes: keys?.objectForKeyedSubscript("publicKey").toArray() as [UInt8])
            let pubKeyHex = pubKeyData.hexEncodedString()
            logger.debug("ADVANCEMENT - Public key hex: \(pubKeyHex)")
            
            let keysToSave = Keys(publicKey: pubKeyHex, privateKey: keys?.objectForKeyedSubscript("privateKey").toString() ?? "")
            self.saveKeys(data: keysToSave.toData())
            return keysToSave
        }
        return nil
    }
    
    public func sign(message: String) -> String? {
        guard let keys = getKeys(),
              let signaturejs = signMessageJS?.call(withArguments: [message, keys.privateKey]) else {
            return nil
        }
        let signature = signaturejs.toString()
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

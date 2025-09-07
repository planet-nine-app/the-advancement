import SafariServices
import Foundation
import os.log

@objc(SafariWebExtensionHandler)
@available(macOS 12.0, *)
class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {
    
    private let sessionless = Sessionless()
    private let logger = Logger(subsystem: "com.planetnine.the-advancement", category: "SafariExtension")
    
    func beginRequest(with context: NSExtensionContext) {
        logger.info("ADVANCEMENT - 🔧 Safari Web Extension beginRequest called")
        
        guard let item = context.inputItems.first as? NSExtensionItem else {
            logger.error("ADVANCEMENT - ❌ No input items or wrong type")
            context.completeRequest(returningItems: [["foo": "item"]], completionHandler: nil)
            return
        }
        
        guard let userInfo = item.userInfo as? [String: Any] else {
            logger.error("ADVANCEMENT - ❌ No userInfo or wrong type")
            context.completeRequest(returningItems: [["foo": "userInfo"]], completionHandler: nil)
            return
        }
        
        guard let message = userInfo[SFExtensionMessageKey] as? [String: Any] else {
            logger.error("ADVANCEMENT - ❌ No SFExtensionMessageKey or wrong type")
            context.completeRequest(returningItems:
                                        [["foo": "message"]], completionHandler: nil)
            return
        }
        
        // Extract action and parameters from message
        guard let action = message["action"] as? String else {
            logger.error("ADVANCEMENT - ❌ No action specified in message")
            context.completeRequest(returningItems: [["foo": "action"]], completionHandler: nil)
            return
        }
        
        let requestId = message["requestId"] as? String
        logger.info("ADVANCEMENT - 🔧 Processing action: \(action) with requestId: \(requestId ?? "none")")
        
        // Handle the action
        handleAction(action: action, parameters: message, context: context, requestId: requestId)
    }
    
    private func handleAction(action: String, parameters: [String: Any], context: NSExtensionContext, requestId: String?) {
        switch action {
        case "test":
            logger.info("ADVANCEMENT - 🧪 Swift: Test action received")
            sendSuccess(context: context, requestId: requestId, data: ["message": "Swift native messaging working!"])
            
        case "getSpellbook":
            guard let baseUrl = parameters["baseUrl"] as? String else {
                sendError(context: context, requestId: requestId, error: "Base URL required")
                return
            }
            handleGetSpellbook(baseUrl: baseUrl, context: context, requestId: requestId)
            
        case "generateKeys":
            handleGenerateKeys(context: context, requestId: requestId)
            
        case "castSpell":
            guard let spellName = parameters["spellName"] as? String,
                  let magicPayload = parameters["magicPayload"] as? [String: Any],
                  let destinations = parameters["destinations"] as? [[String: Any]] else {
                sendError(context: context, requestId: requestId, error: "castSpell requires spellName, magicPayload, and destinations")
                return
            }
            handleCastSpell(spellName: spellName, magicPayload: magicPayload, destinations: destinations, context: context, requestId: requestId)
            
        case "createFountUser":
            handleCreateFountUser(context: context, requestId: requestId)
            
        case "clearFountUser":
            handleClearFountUser(context: context, requestId: requestId)
            
        case "clearBdoUser":
            handleClearBdoUser(context: context, requestId: requestId)
            
        case "signCovenantStep":
            handleSignCovenantStep(parameters: parameters, context: context, requestId: requestId)
            
        case "getBDOCard":
            guard let bdoPubKey = parameters["bdoPubKey"] as? String else {
                sendError(context: context, requestId: requestId, error: "getBDOCard requires bdoPubKey parameter")
                return
            }
            let baseUrl = parameters["baseUrl"] as? String ?? "https://dev.bdo.allyabase.com/"
            handleGetBDOCard(bdoPubKey: bdoPubKey, baseUrl: baseUrl, context: context, requestId: requestId)
            
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
    
    private func handleGetBDOCard(bdoPubKey: String, baseUrl: String, context: NSExtensionContext, requestId: String?) {
        logger.info("ADVANCEMENT - 🃏 Swift: Handling getBDOCard request for pubKey: \(bdoPubKey)")
        logger.info("ADVANCEMENT - 🔗 Swift: Using base URL: \(baseUrl)")
        
        Task {
            do {
                // Try multiple BDO environments to find the magistack
                let bdoEnvironments = [
                    baseUrl,
                    "https://dev.bdo.allyabase.com/",
                    "http://127.0.0.1:5114/", 
                    "http://localhost:3003/"
                ]
                
                var lastError: Error?
                
                for bdoUrl in bdoEnvironments {
                    do {
                        logger.info("ADVANCEMENT - 🔍 Swift: Trying BDO environment: \(bdoUrl)")
                        
                        let magistackData = try await getBDOCardFromUrl(bdoPubKey: bdoPubKey, bdoUrl: bdoUrl)
                        
                        logger.info("ADVANCEMENT - ✅ Swift: Found magistack at \(bdoUrl)")
                        sendSuccess(context: context, requestId: requestId, data: magistackData)
                        return
                        
                    } catch {
                        logger.info("ADVANCEMENT - ❌ Swift: Failed to get magistack from \(bdoUrl): \(error)")
                        lastError = error
                        continue
                    }
                }
                
                // If we get here, all environments failed
                logger.error("ADVANCEMENT - ❌ Swift: All BDO environments failed for pubKey: \(bdoPubKey)")
                sendError(context: context, requestId: requestId, error: lastError?.localizedDescription ?? "Magistack not found in any BDO environment")
                
            } catch {
                logger.error("ADVANCEMENT - ❌ Swift: getBDOCard error: \(error)")
                sendError(context: context, requestId: requestId, error: error.localizedDescription)
            }
        }
    }
    
    private func handleGenerateKeys(context: NSExtensionContext, requestId: String?) {
        logger.info("ADVANCEMENT - 🔑 Swift: Generating new keys...")
        
        // Check if JavaScript context is loaded
        if sessionless.jsContext == nil {
            logger.error("ADVANCEMENT - ❌ Swift: JavaScript context is nil - crypto.js not loaded")
            sendError(context: context, requestId: requestId, error: "JavaScript context not loaded - crypto.js missing")
            return
        }
        
        logger.info("ADVANCEMENT - ✅ Swift: JavaScript context loaded successfully")
        
        if let keys = sessionless.generateKeys() {
            logger.info("ADVANCEMENT - ✅ Swift: Keys generated successfully")
            logger.info("ADVANCEMENT - 📋 Swift: Public key: \(keys.publicKey)")
            
            let response: [String: Any] = [
                "success": true,
                "publicKey": keys.publicKey
            ]
            
            sendSuccess(context: context, requestId: requestId, data: response)
        } else {
            logger.error("ADVANCEMENT - ❌ Swift: Failed to generate keys")
            sendError(context: context, requestId: requestId, error: "Failed to generate keys")
        }
    }
    
    private func handleCastSpell(spellName: String, magicPayload: [String: Any], destinations: [[String: Any]], context: NSExtensionContext, requestId: String?) {
        logger.info("ADVANCEMENT - 🪄 [STEP 4/6] SWIFT: Starting castSpell for \(spellName)")
        logger.info("ADVANCEMENT - 🔮 [STEP 4/6] SWIFT: MAGIC payload: \(magicPayload)")
        logger.info("ADVANCEMENT - 🎯 [STEP 4/6] SWIFT: Destinations: \(destinations)")
        
        Task {
            do {
                // 1. Ensure we have sessionless keys
                if sessionless.getKeys() == nil {
                    logger.info("ADVANCEMENT - 🔑 [STEP 4/6] SWIFT: No keys found, generating...")
                    _ = sessionless.generateKeys()
                }
                
                // 2. Get or create fount user
                let fountUser = try await getOrCreateFountUser()
                logger.info("ADVANCEMENT - 👤 [STEP 4/6] SWIFT: Using fount user: \(fountUser)")
                
                // 3. Update MAGIC payload with real fount user data
                var updatedPayload = magicPayload
                updatedPayload["casterUUID"] = fountUser["uuid"]
                updatedPayload["ordinal"] = fountUser["ordinal"]
                
                // 4. Sign the MAGIC payload
                let signedPayload = try await signMagicPayload(updatedPayload)
                logger.info("ADVANCEMENT - ✅ [STEP 4/6] SWIFT: Signed MAGIC payload")
                
                // 5. Post to first destination
                guard let firstDest = destinations.first,
                      let stopURL = firstDest["stopURL"] as? String else {
                    throw NSError(domain: "CastSpellError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No valid first destination"])
                }
                
                let fullURL = stopURL + spellName
                logger.info("ADVANCEMENT - 🎯 [STEP 4/6] SWIFT: POSTing to: \(fullURL)")
                
                let response = try await postSpellToServer(signedPayload, url: fullURL)
                logger.info("ADVANCEMENT - 📥 [STEP 4/6] SWIFT: Server response received")
                
                sendSuccess(context: context, requestId: requestId, data: response)
                
            } catch {
                logger.error("ADVANCEMENT - ❌ [STEP 4/6] SWIFT: castSpell error: \(error)")
                sendError(context: context, requestId: requestId, error: error.localizedDescription)
            }
        }
    }
    
    private func handleCreateFountUser(context: NSExtensionContext, requestId: String?) {
        logger.info("ADVANCEMENT - 👤 Swift: Creating fount user...")
        
        Task {
            do {
                let fountUser = try await getOrCreateFountUser()
                sendSuccess(context: context, requestId: requestId, data: fountUser)
            } catch {
                sendError(context: context, requestId: requestId, error: error.localizedDescription)
            }
        }
    }
    
    private func handleClearFountUser(context: NSExtensionContext, requestId: String?) {
        logger.info("ADVANCEMENT - 🗑️ Swift: Clearing fount user from UserDefaults...")
        
        // Clear fount user from UserDefaults
        UserDefaults.standard.removeObject(forKey: "fountUser")
        
        let response: [String: Any] = [
            "success": true,
            "message": "Fount user cleared from Swift UserDefaults"
        ]
        
        sendSuccess(context: context, requestId: requestId, data: response)
        logger.info("ADVANCEMENT - ✅ Swift: Fount user cleared successfully")
    }
    
    private func handleClearBdoUser(context: NSExtensionContext, requestId: String?) {
        logger.info("ADVANCEMENT - 🗑️ Swift: Clearing BDO user from UserDefaults...")
        
        // Clear BDO user from UserDefaults (if we store it there)
        UserDefaults.standard.removeObject(forKey: "bdoUser")
        
        let response: [String: Any] = [
            "success": true,
            "message": "BDO user cleared from Swift UserDefaults"
        ]
        
        sendSuccess(context: context, requestId: requestId, data: response)
        logger.info("ADVANCEMENT - ✅ Swift: BDO user cleared successfully")
    }
    
    private func handleSignCovenantStep(parameters: [String: Any], context: NSExtensionContext, requestId: String?) {
        logger.info("ADVANCEMENT - 📜 Swift: Handling covenant step signing...")
        
        guard let contractUuid = parameters["contractUuid"] as? String,
              let stepId = parameters["stepId"] as? String,
              let covenantUrl = parameters["covenantUrl"] as? String,
              let timestamp = parameters["timestamp"] as? String else {
            logger.error("ADVANCEMENT - ❌ Swift: Missing covenant parameters")
            sendError(context: context, requestId: requestId, error: "Missing covenant parameters: contractUuid, stepId, covenantUrl, timestamp required")
            return
        }
        
        logger.info("ADVANCEMENT - 📜 Swift: Contract: \(contractUuid), Step: \(stepId), Service: \(covenantUrl)")
        
        Task {
            do {
                let result = try await signCovenantStep(
                    contractUuid: contractUuid,
                    stepId: stepId,
                    covenantUrl: covenantUrl,
                    timestamp: timestamp
                )
                
                sendSuccess(context: context, requestId: requestId, data: result)
                logger.info("ADVANCEMENT - ✅ Swift: Covenant step signed successfully")
                
            } catch {
                logger.error("ADVANCEMENT - ❌ Swift: Covenant step signing failed: \(error)")
                sendError(context: context, requestId: requestId, error: error.localizedDescription)
            }
        }
    }
    
    private func getSpellbooksComplete(baseUrl: String) async throws -> [String: Any] {
        logger.info("ADVANCEMENT - 📚 Swift: Starting complete spellbook flow")
        
        // 1. Ensure we have keys
        if sessionless.getKeys() == nil {
            logger.info("ADVANCEMENT - 🔑 Swift: No keys found, generating new keys...")
            _ = sessionless.generateKeys()
        }
                
        // 2. Create BDO user if needed
        let uuid = try await createBDOUser(baseUrl: baseUrl)
        logger.info("ADVANCEMENT - 👤 Swift: BDO user UUID: \(uuid)")
        
        // 3. Get spellbooks
        let spellbooks = try await getBDOSpellbooks(baseUrl: baseUrl, uuid: uuid)
        return spellbooks
    }
    
    
    private func createBDOUser(baseUrl: String) async throws -> String {
        guard let keys = sessionless.getKeys() else {
            throw NSError(domain: "SessionlessError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No keys available"])
        }
        
        let publicKey = keys.publicKey
        let timestamp = "".getTime()
        let hash = "advancement-popup"
        let message = timestamp + publicKey + hash
        
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SessionlessError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to sign message"])
        }
        
        let payload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": publicKey,
            "hash": hash,
            "bdo": ["client": "advancement-safari-popup", "created": timestamp],
            "signature": signature
        ]
        
        let endpoint = "\(baseUrl)user/create"
        logger.info("ADVANCEMENT - 📤 Swift→BDO: Creating user at \(endpoint)")
        
        let response = try await makeBDORequest(endpoint: endpoint, method: "PUT", payload: payload)
        logger.info("ADVANCEMENT - 📥 BDO→Swift: Create user response: \(response)")
        
        guard let userUUID = response["userUUID"] as? String ?? response["uuid"] as? String else {
            throw NSError(domain: "SessionlessError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid message"])
        }
        
        return userUUID
    }
    
    private func getBDOSpellbooks(baseUrl: String, uuid: String) async throws -> [String: Any] {
        let timestamp = "".getTime()
        let hash = "advancement-popup"
        let message = timestamp + uuid + hash
        
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SessionlessError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to sign message"])
        }
        
        let endpoint = "\(baseUrl)user/\(uuid)/spellbooks?timestamp=\(timestamp)&hash=\(hash)&signature=\(signature)"
        logger.info("ADVANCEMENT - 📤 Swift→BDO: Getting spellbooks from \(endpoint)")
        
        let response = try await makeBDORequest(endpoint: endpoint, method: "GET", payload: nil)
        logger.info("ADVANCEMENT - 📥 BDO→Swift: Spellbooks response: \(response)")
        
        return response
    }
    
    private func getBDOCardFromUrl(bdoPubKey: String, bdoUrl: String) async throws -> [String: Any] {
        // Ensure we have sessionless keys for authentication
        if sessionless.getKeys() == nil {
            logger.info("ADVANCEMENT - 🔑 Swift: No keys found, generating new keys for BDO access...")
            _ = sessionless.generateKeys()
        }
        
        // Create or get BDO user for authenticated access
        let uuid = try await createBDOUser(baseUrl: bdoUrl)
        logger.info("ADVANCEMENT - 👤 Swift: Using BDO user UUID: \(uuid) for magistack retrieval")
        
        // Create authenticated BDO request for the magistack
        let timestamp = "".getTime()
        let hash = "advancement-magistack"
        let message = timestamp + uuid + hash
        
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "BDOCardError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to sign BDO card request"])
        }
        
        // Construct authenticated magistack endpoint
        let endpoint = "\(bdoUrl)\(bdoPubKey)?timestamp=\(timestamp)&hash=\(hash)&signature=\(signature)&uuid=\(uuid)"
        logger.info("ADVANCEMENT - 📤 Swift→BDO: Getting magistack from \(endpoint)")
        
        let response = try await makeBDORequest(endpoint: endpoint, method: "GET", payload: nil)
        logger.info("ADVANCEMENT - 📥 BDO→Swift: Magistack response received")
        
        return response
    }
    
    private func makeBDORequest(endpoint: String, method: String, payload: [String: Any]?) async throws -> [String: Any] {
        guard let url = URL(string: endpoint) else {
            throw NSError(domain: "SessionlessError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
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
            throw NSError(domain: "SessionlessError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }
        
        logger.info("ADVANCEMENT - 📊 BDO HTTP Response: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("ADVANCEMENT - ❌ BDO Error Response: \(errorText)")
            throw NSError(domain: "SessionlessError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorText)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SessionlessError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }
        
        return json
    }
    
    private func makeAuthenticatedRequest(to urlString: String, method: String = "GET", payload: [String: Any]? = nil) async throws -> [String: Any] {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "HTTPError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(urlString)"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let payload = payload {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        }
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "HTTPError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }
        
        if httpResponse.statusCode >= 400 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorText)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "HTTPError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }
        
        return json
    }
    
    // MARK: - MAGIC Protocol Functions
    
    private func getOrCreateFountUser() async throws -> [String: Any] {
        // Try to get existing fount user from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "fountUser"),
           let fountUser = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let uuid = fountUser["uuid"] as? String,
           let ordinal = fountUser["ordinal"] as? Int {
            logger.info("ADVANCEMENT - 🔍 Swift: Using stored fount user: \(uuid)")
            return fountUser
        }
        
        // No stored user, create new one via fount
        logger.info("ADVANCEMENT - 👤 Swift: Creating new fount user...")
        
        // Ensure we have sessionless keys
        guard let keys = sessionless.getKeys() else {
            throw NSError(domain: "FountUserError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No sessionless keys available"])
        }
        
        // Create fount user payload
        let timestamp = "".getTime()
        let message = timestamp + keys.publicKey
        
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "FountUserError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to sign fount user message"])
        }
        
        let payload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": keys.publicKey,
            "signature": signature
        ]
        
        // Post to fount to create user
        let fountUrl = "http://127.0.0.1:5117/user/create" // Test environment fount
        let response = try await makeAuthenticatedRequest(to: fountUrl, method: "PUT", payload: payload)
        
        guard let uuid = response["uuid"] as? String else {
            throw NSError(domain: "FountUserError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No UUID in fount response"])
        }
        
        let fountUser: [String: Any] = [
            "uuid": uuid,
            "ordinal": 0, // Start with ordinal 0
            "created": timestamp,
            "pubKey": keys.publicKey
        ]
        
        // Store for future use
        if let data = try? JSONSerialization.data(withJSONObject: fountUser) {
            UserDefaults.standard.set(data, forKey: "fountUser")
            logger.info("ADVANCEMENT - 💾 Swift: Stored fount user: \(uuid)")
        }
        
        return fountUser
    }
    
    private func signMagicPayload(_ payload: [String: Any]) async throws -> [String: Any] {
        // Create message to sign from MAGIC protocol fields
        guard let timestamp = payload["timestamp"] as? String,
              let spell = payload["spell"] as? String,
              let casterUUID = payload["casterUUID"] as? String,
              let totalCost = payload["totalCost"] as? Int,
              let ordinal = payload["ordinal"] as? Int else {
            throw NSError(domain: "MagicSignError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid MAGIC payload structure"])
        }
        
        // MAGIC protocol signing message
        let message = timestamp + spell + casterUUID + String(totalCost) + String(ordinal)
        
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "MagicSignError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to sign MAGIC payload"])
        }
        
        var signedPayload = payload
        signedPayload["casterSignature"] = signature
        
        logger.info("ADVANCEMENT - ✅ Swift: MAGIC payload signed successfully")
        return signedPayload
    }
    
    private func postSpellToServer(_ signedPayload: [String: Any], url: String) async throws -> [String: Any] {
        logger.info("ADVANCEMENT - 🌐 Swift: POSTing spell to \(url)")
        
        guard let requestUrl = URL(string: url) else {
            throw NSError(domain: "SpellPostError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL: \(url)"])
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: signedPayload)
        } catch {
            throw NSError(domain: "SpellPostError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize spell payload"])
        }
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "SpellPostError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }
        
        logger.info("ADVANCEMENT - 📊 Swift: Server response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("ADVANCEMENT - ❌ Swift: Server error: \(errorText)")
            throw NSError(domain: "SpellPostError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorText)"])
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "SpellPostError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response from server"])
        }
        
        return json
    }
    
    private func signCovenantStep(contractUuid: String, stepId: String, covenantUrl: String, timestamp: String) async throws -> [String: Any] {
        logger.info("ADVANCEMENT - 📜 Swift: Starting covenant step signing process")
        
        // 1. Ensure we have keys
        if sessionless.getKeys() == nil {
            logger.info("ADVANCEMENT - 🔑 Swift: No keys found, generating new keys...")
            _ = sessionless.generateKeys()
        }
        
        guard let keys = sessionless.getKeys() else {
            throw NSError(domain: "CovenantError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get sessionless keys"])
        }
        
        logger.info("ADVANCEMENT - 🔑 Swift: Using public key: \(keys.publicKey)")
        
        // 2. Create authentication message: timestamp + userUUID + contractUUID + stepId
        // Use public key as userUUID for covenant authentication (sessionless pattern)
        let userUUID = keys.publicKey
        let authMessage = timestamp + userUUID + contractUuid + stepId
        
        logger.info("ADVANCEMENT - 🔐 Swift: Auth message: \(authMessage)")
        
        // 3. Sign the authentication message
        guard let signature = sessionless.sign(message: authMessage) else {
            throw NSError(domain: "CovenantError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to sign authentication message"])
        }
        
        logger.info("ADVANCEMENT - ✍️ Swift: Generated signature: \(signature)")
        
        // 4. Prepare covenant API request
        let requestPayload: [String: Any] = [
            "signature": signature,
            "timestamp": timestamp,
            "userUUID": userUUID,
            "pubKey": keys.publicKey
        ]
        
        // 5. Make authenticated request to covenant service
        let signUrl = "\(covenantUrl)/step/\(contractUuid)/\(stepId)/sign"
        logger.info("ADVANCEMENT - 📡 Swift: POSTing to covenant service: \(signUrl)")
        
        guard let requestUrl = URL(string: signUrl) else {
            throw NSError(domain: "CovenantError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid covenant URL: \(signUrl)"])
        }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("The-Advancement-Swift/1.0", forHTTPHeaderField: "User-Agent")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestPayload)
        } catch {
            throw NSError(domain: "CovenantError", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize covenant request"])
        }
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw NSError(domain: "CovenantError", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }
        
        logger.info("ADVANCEMENT - 📊 Swift: Covenant response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode >= 400 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("ADVANCEMENT - ❌ Swift: Covenant service error: \(errorText)")
            
            // Try to parse error response
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorData["error"] as? String {
                throw NSError(domain: "CovenantError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            } else {
                throw NSError(domain: "CovenantError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorText)"])
            }
        }
        
        // Parse successful response
        guard let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "CovenantError", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to parse covenant response"])
        }
        
        logger.info("ADVANCEMENT - ✅ Swift: Covenant step signed successfully")
        logger.info("ADVANCEMENT - 📋 Swift: Response data keys: \(responseData.keys.joined(separator: ", "))")
        
        return [
            "success": true,
            "stepCompleted": responseData["stepCompleted"] ?? false,
            "contractUuid": contractUuid,
            "stepId": stepId,
            "userUUID": userUUID,
            "response": responseData
        ]
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

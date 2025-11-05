//
//  BDOService.swift
//  Shared Extension Code
//
//  Created by Claude on 10/7/25.
//

import Foundation

struct FountUser {
    let uuid: String
    let publicKey: String
}

class BDOService {
    private let bdoBaseUrl = "http://127.0.0.1:5114/"
    private let fountBaseUrl = "http://127.0.0.1:5117/"
    private let sessionless: Sessionless

    init(sessionless: Sessionless) {
        self.sessionless = sessionless
    }

    // MARK: - Public Methods

    /// Fetches a BDO from BDO service by its public key
    func fetchBDO(bdoPubKey: String) async throws -> [String: Any] {
        NSLog("BDOSERVICE: 🔍 Fetching BDO for pubKey: %@", bdoPubKey)

        do {
            // Try authenticated fetch first
            return try await fetchBDOFromServer(bdoPubKey: bdoPubKey, baseUrl: bdoBaseUrl)
        } catch {
            NSLog("BDOSERVICE: ❌ BDO server fetch failed: %@", error.localizedDescription)
            NSLog("BDOSERVICE: 🔄 Falling back to Fount...")
            return try await fetchBDOFromFount(bdoPubKey: bdoPubKey)
        }
    }

    // MARK: - Private Methods

    private func fetchBDOFromServer(bdoPubKey: String, baseUrl: String) async throws -> [String: Any] {
        // For BDO access, we need to use the proper BDO user endpoint format:
        // GET /user/{uuid}/bdo?pubKey={pubKey}&timestamp={timestamp}&hash={hash}&signature={signature}

        // Get or create BDO user UUID (persisted in UserDefaults)
        let bdoUserUUID = try await getBDOUserUUID()
        NSLog("BDOSERVICE: 🔍 Fetching BDO for pubKey: %@ with user UUID: %@", bdoPubKey, bdoUserUUID)

        // Generate timestamp
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        // Create message to sign (for BDO GET requests, we sign: timestamp + hash + uuid)
        let hash = ""
        let messageToSign = "\(timestamp)\(hash)\(bdoUserUUID)"

        // Sign the message using Sessionless
        guard let signature = sessionless.sign(message: messageToSign) else {
            throw BDOError.serializationError("Failed to sign BDO request")
        }

        // Create the proper BDO API URL with query parameters
        var urlComponents = URLComponents(string: "\(baseUrl)user/\(bdoUserUUID)/bdo")!
        urlComponents.queryItems = [
            URLQueryItem(name: "pubKey", value: bdoPubKey.lowercased()),
            URLQueryItem(name: "timestamp", value: timestamp),
            URLQueryItem(name: "hash", value: hash),
            URLQueryItem(name: "signature", value: signature)
        ]

        guard let url = urlComponents.url else {
            throw BDOError.invalidURL
        }

        NSLog("BDOSERVICE: 🌐 Fetching BDO from: %@", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BDOError.invalidResponse
        }

        NSLog("BDOSERVICE: 📡 BDO response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            // If BDO endpoint fails, try fetching as public BDO (no user auth needed)
            NSLog("BDOSERVICE: BDO endpoint failed with status %d, trying public BDO fetch", httpResponse.statusCode)
            return try await fetchPublicBDO(bdoPubKey: bdoPubKey, baseUrl: baseUrl)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BDOError.invalidJSON
        }

        return jsonObject
    }

    private func fetchPublicBDO(bdoPubKey: String, baseUrl: String) async throws -> [String: Any] {
        NSLog("BDOSERVICE: 🌍 Fetching public BDO by pubKey: %@", bdoPubKey)

        // Public BDOs can be fetched directly by pubKey without authentication
        var urlComponents = URLComponents(string: "\(baseUrl)public/bdo")!
        urlComponents.queryItems = [
            URLQueryItem(name: "pubKey", value: bdoPubKey.lowercased())
        ]

        guard let url = urlComponents.url else {
            throw BDOError.invalidURL
        }

        NSLog("BDOSERVICE: 🌐 Fetching public BDO from: %@", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BDOError.invalidResponse
        }

        NSLog("BDOSERVICE: 📡 Public BDO response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            throw BDOError.httpError(httpResponse.statusCode)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BDOError.invalidJSON
        }

        NSLog("BDOSERVICE: ✅ Successfully fetched public BDO")
        return jsonObject
    }

    private func getBDOUserUUID() async throws -> String {
        // Check if we already have a BDO user UUID stored
        if let existingUUID = UserDefaults.standard.string(forKey: "bdoUserUUID") {
            return existingUUID
        }

        // Need to create a new BDO user via API
        NSLog("BDOSERVICE: 🆕 No BDO user UUID found, creating new BDO user...")
        let newUUID = try await createBDOUser()

        // Store the UUID for future use
        UserDefaults.standard.set(newUUID, forKey: "bdoUserUUID")
        NSLog("BDOSERVICE: ✅ Created and saved new BDO user UUID: %@", newUUID)

        return newUUID
    }

    private func createBDOUser() async throws -> String {
        // Get or generate Sessionless keys
        var keys = sessionless.getKeys()
        if keys == nil {
            NSLog("BDOSERVICE: 🔑 No Sessionless keys found, generating new keys...")
            keys = sessionless.generateKeys()
            guard keys != nil else {
                throw BDOError.serializationError("Failed to generate Sessionless keys")
            }
            NSLog("BDOSERVICE: ✅ Sessionless keys generated: %@", keys!.publicKey)
        }

        guard let keys = keys else {
            throw BDOError.serializationError("No Sessionless keys available")
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "" // Empty for user creation

        // Message to sign: timestamp + hash + pubKey
        let messageToSign = "\(timestamp)\(hash)\(keys.publicKey)"

        guard let signature = sessionless.sign(message: messageToSign) else {
            throw BDOError.serializationError("Failed to sign user creation request")
        }

        // Create request body
        let requestBody: [String: Any] = [
            "timestamp": timestamp,
            "hash": hash,
            "pubKey": keys.publicKey,
            "signature": signature,
            "public": false,
            "bdo": [:]
        ]

        var request = URLRequest(url: URL(string: "\(bdoBaseUrl)user/create")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        NSLog("BDOSERVICE: 📡 Creating BDO user...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BDOError.invalidResponse
        }

        NSLog("BDOSERVICE: 📡 BDO user create response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw BDOError.httpError(httpResponse.statusCode)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuid = jsonObject["uuid"] as? String else {
            throw BDOError.invalidJSON
        }

        NSLog("BDOSERVICE: ✅ BDO user created with UUID: %@", uuid)
        return uuid
    }

    private func fetchBDOFromFount(bdoPubKey: String) async throws -> [String: Any] {
        // First ensure we have a Fount user
        let fountUser = try await ensureFountUser()

        // Try to fetch existing BDO
        let fountUrl = "\(fountBaseUrl)bdo/\(bdoPubKey)"

        guard let url = URL(string: fountUrl) else {
            throw BDOError.invalidURL
        }

        NSLog("BDOSERVICE: 📡 Fetching BDO from Fount: %@", fountUrl)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BDOError.invalidResponse
        }

        NSLog("BDOSERVICE: 📡 Fount response status: %d", httpResponse.statusCode)

        if httpResponse.statusCode == 404 {
            // BDO not found in Fount, create it
            NSLog("BDOSERVICE: 📦 BDO not found in Fount, creating it with user: %@", fountUser.uuid)
            return try await createBDOInFount(bdoPubKey: bdoPubKey, fountUser: fountUser)
        }

        guard httpResponse.statusCode == 200 else {
            throw BDOError.httpError(httpResponse.statusCode)
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bdoData = jsonObject else {
            throw BDOError.invalidJSON
        }

        NSLog("BDOSERVICE: ✅ BDO fetched from Fount successfully")
        return bdoData
    }

    private func ensureFountUser() async throws -> FountUser {
        let keyPair = generateOrRetrieveKeyPair()
        NSLog("BDOSERVICE: 👤 Creating Fount user with pubKey: %@", keyPair.publicKey)
        return try await createFountUser(keyPair: keyPair)
    }

    private func generateOrRetrieveKeyPair() -> (publicKey: String, privateKey: String) {
        let pubKey = "02a3b4c5d6e7f8910111213141516171819202122232425262728293031323334"
        let privKey = "a3b4c5d6e7f8910111213141516171819202122232425262728293031323334"
        return (publicKey: pubKey, privateKey: privKey)
    }

    private func createFountUser(keyPair: (publicKey: String, privateKey: String)) async throws -> FountUser {
        let createUserUrl = "\(fountBaseUrl)users"

        guard let url = URL(string: createUserUrl) else {
            throw BDOError.invalidURL
        }

        let requestBody: [String: Any] = [
            "publicKey": keyPair.publicKey,
            "signature": "placeholder"
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        NSLog("BDOSERVICE: 📡 Creating Fount user...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BDOError.invalidResponse
        }

        NSLog("BDOSERVICE: 📡 Fount create user response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw BDOError.httpError(httpResponse.statusCode)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuid = jsonObject["uuid"] as? String else {
            throw BDOError.invalidJSON
        }

        NSLog("BDOSERVICE: ✅ Fount user created with UUID: %@", uuid)
        return FountUser(uuid: uuid, publicKey: keyPair.publicKey)
    }

    private func createBDOInFount(bdoPubKey: String, fountUser: FountUser) async throws -> [String: Any] {
        let createBDOUrl = "\(fountBaseUrl)bdo"

        guard let url = URL(string: createBDOUrl) else {
            throw BDOError.invalidURL
        }

        let requestBody: [String: Any] = [
            "pubKey": bdoPubKey,
            "data": [:]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        NSLog("BDOSERVICE: 📡 Creating BDO in Fount...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw BDOError.invalidResponse
        }

        NSLog("BDOSERVICE: 📡 Fount create BDO response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw BDOError.httpError(httpResponse.statusCode)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BDOError.invalidJSON
        }

        NSLog("BDOSERVICE: ✅ BDO created in Fount successfully")
        return jsonObject
    }
}

// MARK: - Error Types

enum BDOError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidJSON
    case serializationError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidJSON:
            return "Invalid JSON data"
        case .serializationError(let details):
            return "Serialization error: \(details)"
        }
    }
}

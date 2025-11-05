//
//  SanoraService.swift
//  AdvanceKey
//
//  Created by Claude on 9/20/25.
//

import Foundation

public class SanoraService {
    private let baseURL: String
    private let sessionless: Sessionless

    // Sanora product structure
    public struct Product {
        public let title: String
        public let description: String
        public let price: Int // price in cents
        public let uuid: String
        public let productId: String
        public let timestamp: String
        public let imageURL: String?
        public let redirectURL: String?

        public init(from json: [String: Any]) {
            self.title = json["title"] as? String ?? "Unknown Product"
            self.description = json["description"] as? String ?? ""
            self.price = json["price"] as? Int ?? 0
            self.uuid = json["uuid"] as? String ?? ""
            self.productId = json["productId"] as? String ?? ""
            self.timestamp = json["timestamp"] as? String ?? ""
            self.imageURL = json["imageURL"] as? String
            self.redirectURL = json["redirectURL"] as? String
        }

        public var formattedPrice: String {
            let dollars = Double(price) / 100.0
            return String(format: "$%.2f", dollars)
        }
    }

    public struct SanoraUser {
        public let uuid: String
        public let pubKey: String
        public let timestamp: String

        public init(from json: [String: Any]) {
            self.uuid = json["uuid"] as? String ?? ""
            self.pubKey = json["pubKey"] as? String ?? ""
            self.timestamp = json["timestamp"] as? String ?? ""
        }
    }

    public init(baseURL: String = Configuration.Sanora.baseURL) {
        self.baseURL = baseURL
        self.sessionless = Sessionless()
    }

    // MARK: - Public Products (No Auth Required)

    /// Fetches all products from the Sanora base (public endpoint)
    public func fetchAllProducts() async throws -> [Product] {
        let url = URL(string: "\(baseURL)/products/base")!

        print("🔍 Fetching products from: \(url)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SanoraError.invalidResponse
        }

        print("📡 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            throw SanoraError.httpError(httpResponse.statusCode)
        }

        // The response is an array of dictionaries, where each dictionary contains product objects
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: [String: Any]]] else {
            print("❌ Failed to parse JSON response - expected array of dictionaries")
            throw SanoraError.invalidJSON
        }

        print("✅ Parsed \(json.count) base dictionaries from Sanora")

        // Flatten the nested structure: extract all product objects from all dictionaries
        var products: [Product] = []
        for baseDictionary in json {
            for (_, productData) in baseDictionary {
                products.append(Product(from: productData))
            }
        }

        print("✅ Extracted \(products.count) total products")
        return products
    }

    /// Fetches a single product by UUID from Sanora
    public func fetchProductByUUID(_ uuid: String) async throws -> Product {
        let url = URL(string: "\(baseURL)/product/\(uuid)")!

        print("🔍 Fetching product by UUID from: \(url)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SanoraError.invalidResponse
        }

        print("📡 Response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 404 {
                throw SanoraError.productNotFound(uuid)
            }
            throw SanoraError.httpError(httpResponse.statusCode)
        }

        // Single product response should be a dictionary
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON response - expected product object")
            throw SanoraError.invalidJSON
        }

        print("✅ Retrieved product for UUID: \(uuid)")

        return Product(from: json)
    }

    // MARK: - Authenticated User Operations

    /// Creates a user in Sanora using sessionless authentication
    public func createUser() async throws -> SanoraUser {
        guard let keys = sessionless.getKeys() else {
            throw SanoraError.noKeys
        }

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let message = "\(keys.publicKey):\(timestamp)"

        guard let signature = try sessionless.sign(message: message) else {
            throw SanoraError.signingFailed
        }

        let url = URL(string: "\(baseURL)/user/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = [
            "pubKey": keys.publicKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("🔐 Creating Sanora user with pubKey: \(keys.publicKey)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SanoraError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw SanoraError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SanoraError.invalidJSON
        }

        let user = SanoraUser(from: json)
        print("✅ Created Sanora user: \(user.uuid)")
        return user
    }

    /// Creates a product for the authenticated user
    public func createProduct(
        userUUID: String,
        title: String,
        description: String,
        price: Int,
        redirectURL: String? = nil
    ) async throws -> SanoraUser {
        guard let keys = sessionless.getKeys() else {
            throw SanoraError.noKeys
        }

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let message = "\(title):\(description):\(price):\(timestamp)"

        guard let signature = try sessionless.sign(message: message) else {
            throw SanoraError.signingFailed
        }

        let url = URL(string: "\(baseURL)/user/\(userUUID)/product/\(title)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "title": title,
            "description": description,
            "price": String(price),
            "timestamp": timestamp,
            "signature": signature
        ]

        if let redirectURL = redirectURL {
            body["redirectURL"] = redirectURL
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("📦 Creating product: \(title) for user: \(userUUID)")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SanoraError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw SanoraError.httpError(httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SanoraError.invalidJSON
        }

        return SanoraUser(from: json)
    }

    // MARK: - Helper Methods

    /// Ensures the user exists in Sanora, creates one if necessary
    public func ensureUser() async throws -> SanoraUser {
        // For this demo, we'll always create a user
        // In production, you might want to cache the user UUID
        return try await createUser()
    }

    /// Gets a formatted price string for display
    public func formatPrice(_ priceInCents: Int) -> String {
        let dollars = Double(priceInCents) / 100.0
        return String(format: "$%.2f", dollars)
    }
}

// MARK: - Error Types

public enum SanoraError: Error, LocalizedError {
    case noKeys
    case signingFailed
    case invalidResponse
    case httpError(Int)
    case invalidJSON
    case networkError(Error)
    case productNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .noKeys:
            return "No sessionless keys available"
        case .signingFailed:
            return "Failed to sign message with sessionless"
        case .invalidResponse:
            return "Invalid response from Sanora"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidJSON:
            return "Invalid JSON response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .productNotFound(let uuid):
            return "Product not found for UUID: \(uuid)"
        }
    }
}

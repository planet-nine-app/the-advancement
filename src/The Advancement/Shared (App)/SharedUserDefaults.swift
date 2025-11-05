//
//  SharedUserDefaults.swift
//  The Advancement
//
//  Shared UserDefaults configuration for App Group
//

import Foundation

struct SharedUserDefaults {

    // MARK: - App Group Configuration
    private static let appGroupIdentifier = "group.com.planetnine.Planet-Nine"

    // MARK: - Shared Instance
    static let shared: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            fatalError("Failed to initialize UserDefaults with app group: \(appGroupIdentifier)")
        }
        return userDefaults
    }()

    // MARK: - Keys
    struct Keys {
        static let holdings = "holdings"
        static let cart = "cart"
        static let currentUserPubKey = "currentUserPubKey"
        static let covenantUserUUID = "covenantUserUUID"
        static let carrierBag = "carrier_bag"
        static let testAccess = "test_app_group_access"
    }

    // MARK: - Holdings Management
    static func getHoldings() -> [[String: Any]] {
        return shared.array(forKey: Keys.holdings) as? [[String: Any]] ?? []
    }

    static func saveHoldings(_ holdings: [[String: Any]]) {
        shared.set(holdings, forKey: Keys.holdings)
        shared.synchronize()
    }

    static func addHolding(bdoPubKey: String, type: String, title: String) {
        var holdings = getHoldings()

        // Remove existing holding with same bdoPubKey
        holdings.removeAll { holding in
            (holding["bdoPubKey"] as? String) == bdoPubKey
        }

        // Add new holding
        let newHolding: [String: Any] = [
            "bdoPubKey": bdoPubKey,
            "type": type,
            "title": title,
            "savedAt": ISO8601DateFormatter().string(from: Date())
        ]

        holdings.append(newHolding)
        saveHoldings(holdings)
    }

    // MARK: - Cart Management
    static func getCart() -> [[String: Any]] {
        return shared.array(forKey: Keys.cart) as? [[String: Any]] ?? []
    }

    static func saveCart(_ cart: [[String: Any]]) {
        shared.set(cart, forKey: Keys.cart)
        shared.synchronize()
    }

    static func addToCart(productId: String, baseUuid: String, quantity: Int = 1) {
        var cart = getCart()

        // Check if item already exists in cart
        if let index = cart.firstIndex(where: { ($0["productId"] as? String) == productId }) {
            // Update quantity
            var existingItem = cart[index]
            let currentQuantity = existingItem["quantity"] as? Int ?? 1
            existingItem["quantity"] = currentQuantity + quantity
            existingItem["updatedAt"] = ISO8601DateFormatter().string(from: Date())
            cart[index] = existingItem
        } else {
            // Add new item
            let newItem: [String: Any] = [
                "productId": productId,
                "baseUuid": baseUuid,
                "quantity": quantity,
                "addedAt": ISO8601DateFormatter().string(from: Date()),
                "updatedAt": ISO8601DateFormatter().string(from: Date())
            ]
            cart.append(newItem)
        }

        saveCart(cart)
        NSLog("CART: Added/updated item - productId: %@, quantity: %d, cart count: %d", productId, quantity, cart.count)
    }

    static func removeFromCart(productId: String) {
        var cart = getCart()
        cart.removeAll { ($0["productId"] as? String) == productId }
        saveCart(cart)
        NSLog("CART: Removed item - productId: %@, cart count: %d", productId, cart.count)
    }

    static func updateCartItemQuantity(productId: String, quantity: Int) {
        var cart = getCart()

        if let index = cart.firstIndex(where: { ($0["productId"] as? String) == productId }) {
            if quantity <= 0 {
                // Remove item if quantity is 0 or negative
                cart.remove(at: index)
            } else {
                // Update quantity
                var item = cart[index]
                item["quantity"] = quantity
                item["updatedAt"] = ISO8601DateFormatter().string(from: Date())
                cart[index] = item
            }
            saveCart(cart)
            NSLog("CART: Updated quantity - productId: %@, new quantity: %d", productId, quantity)
        }
    }

    static func clearCart() {
        saveCart([])
        NSLog("CART: Cleared all items")
    }

    static func getCartItemCount() -> Int {
        let cart = getCart()
        return cart.reduce(0) { total, item in
            let quantity = item["quantity"] as? Int ?? 1
            return total + quantity
        }
    }

    // MARK: - User Management
    static func getCurrentUserPubKey() -> String? {
        return shared.string(forKey: Keys.currentUserPubKey)
    }

    static func setCurrentUserPubKey(_ pubKey: String) {
        shared.set(pubKey, forKey: Keys.currentUserPubKey)
        shared.synchronize()
        NSLog("USER: Set current user pubKey: %@", pubKey)
    }

    static func getCovenantUserUUID() -> String? {
        return shared.string(forKey: Keys.covenantUserUUID)
    }

    static func setCovenantUserUUID(_ uuid: String) {
        shared.set(uuid, forKey: Keys.covenantUserUUID)
        shared.synchronize()
        NSLog("COVENANT: Set user UUID: %@", uuid)
    }

    // Get Fount UUID from App Group shared UserDefaults
    static func getFountUserUUID() -> String? {
        return shared.string(forKey: "fountUserUUID")
    }

    // Set Fount UUID in App Group shared UserDefaults
    static func setFountUserUUID(_ uuid: String) {
        shared.set(uuid, forKey: "fountUserUUID")
        shared.synchronize()
        NSLog("FOUNT: Set Fount user UUID: %@", uuid)
    }

    // MARK: - CarrierBag Management
    static func getCarrierBag() -> [String: Any]? {
        return shared.dictionary(forKey: Keys.carrierBag)
    }

    static func saveCarrierBag(_ carrierBag: [String: Any]) {
        shared.set(carrierBag, forKey: Keys.carrierBag)
        shared.synchronize()
        NSLog("CARRIERBAG: Saved carrierBag with %d collections", carrierBag.keys.count)
    }

    static func updateCarrierBagCollection(_ collection: String, items: [[String: Any]]) {
        var carrierBag = getCarrierBag() ?? createEmptyCarrierBag()
        carrierBag[collection] = items
        carrierBag["lastUpdated"] = ISO8601DateFormatter().string(from: Date())
        saveCarrierBag(carrierBag)
        NSLog("CARRIERBAG: Updated collection '%@' with %d items", collection, items.count)
    }

    static func addToCarrierBagCollection(_ collection: String, item: [String: Any]) {
        var carrierBag = getCarrierBag() ?? createEmptyCarrierBag()
        var items = carrierBag[collection] as? [[String: Any]] ?? []
        items.append(item)
        carrierBag[collection] = items
        carrierBag["lastUpdated"] = ISO8601DateFormatter().string(from: Date())
        saveCarrierBag(carrierBag)
        NSLog("CARRIERBAG: Added item to collection '%@' (now %d items)", collection, items.count)
    }

    static func createEmptyCarrierBag() -> [String: Any] {
        return [
            "type": "carrierBag",
            "cookbook": [],
            "apothecary": [],
            "gallery": [],
            "bookshelf": [],
            "familiarPen": [],
            "machinery": [],
            "metallics": [],
            "music": [],
            "oracular": [],
            "greenHouse": [],
            "closet": [],
            "games": [],
            "events": [],
            "contracts": [],
            "stacks": [],
            "addresses": [],  // Shipping addresses for purchases
            "lastUpdated": ISO8601DateFormatter().string(from: Date())
        ]
    }

    // MARK: - Testing
    static func testAccess() -> Bool {
        let testKey = Keys.testAccess
        let testValue = "test_\(Date().timeIntervalSince1970)"

        shared.set(testValue, forKey: testKey)
        shared.synchronize()

        return shared.string(forKey: testKey) == testValue
    }

    // MARK: - Debug
    static func debugPrint(prefix: String) {
        let allKeys = Array(shared.dictionaryRepresentation().keys).sorted()
        let relevantKeys = allKeys.filter {
            !$0.hasPrefix("Apple") &&
            !$0.hasPrefix("NS") &&
            !$0.hasPrefix("AK") &&
            !$0.hasPrefix("PK") &&
            !$0.hasPrefix("WebKit")
        }

        NSLog("%@: 🔍 Shared UserDefaults contents:", prefix)
        for key in relevantKeys {
            let value = shared.object(forKey: key)
            NSLog("%@:   - '%@': %@", prefix, key, String(describing: value))
        }

        let holdings = getHoldings()
        NSLog("%@: 📦 Holdings count: %d", prefix, holdings.count)
        for (index, holding) in holdings.enumerated() {
            let title = holding["title"] as? String ?? "Unknown"
            let type = holding["type"] as? String ?? "Unknown"
            NSLog("%@:   [%d] %@ (%@)", prefix, index, title, type)
        }
    }
}
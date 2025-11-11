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
        static let testAccess = "test_app_group_access"
        static let cart = "cart"
        static let covenantUserUUID = "covenant_user_uuid"
        static let currentUserPubKey = "current_user_pubkey"
        static let carrierBag = "carrier_bag"
    }

    // MARK: - Holdings Management
    static func getHoldings() -> [[String: Any]] {
        return shared.array(forKey: Keys.holdings) as? [[String: Any]] ?? []
    }

    static func saveHoldings(_ holdings: [[String: Any]]) {
        shared.set(holdings, forKey: Keys.holdings)
        shared.synchronize()
    }

    static func addHolding(bdoPubKey: String, type: String, title: String, collection: String? = nil) {
        var holdings = getHoldings()

        // Remove existing holding with same bdoPubKey
        holdings.removeAll { holding in
            (holding["bdoPubKey"] as? String) == bdoPubKey
        }

        // Add new holding
        var newHolding: [String: Any] = [
            "bdoPubKey": bdoPubKey,
            "type": type,
            "title": title,
            "savedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Add collection if specified
        if let collection = collection {
            newHolding["collection"] = collection
        }

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

    static func addToCart(productId: String, baseUuid: String, quantity: Int) {
        var cart = getCart()

        // Check if product already in cart
        if let existingIndex = cart.firstIndex(where: {
            ($0["productId"] as? String) == productId && ($0["baseUuid"] as? String) == baseUuid
        }) {
            // Update quantity
            var item = cart[existingIndex]
            let currentQuantity = item["quantity"] as? Int ?? 1
            item["quantity"] = currentQuantity + quantity
            cart[existingIndex] = item
        } else {
            // Add new item
            let newItem: [String: Any] = [
                "productId": productId,
                "baseUuid": baseUuid,
                "quantity": quantity,
                "addedAt": ISO8601DateFormatter().string(from: Date())
            ]
            cart.append(newItem)
        }

        saveCart(cart)
    }

    static func getCartItemCount() -> Int {
        let cart = getCart()
        return cart.reduce(0) { total, item in
            total + (item["quantity"] as? Int ?? 0)
        }
    }

    // MARK: - Covenant User Management
    static func getCovenantUserUUID() -> String? {
        return shared.string(forKey: Keys.covenantUserUUID)
    }

    static func setCovenantUserUUID(_ uuid: String) {
        shared.set(uuid, forKey: Keys.covenantUserUUID)
        shared.synchronize()
    }

    // MARK: - Current User Management
    static func getCurrentUserPubKey() -> String? {
        return shared.string(forKey: Keys.currentUserPubKey)
    }

    static func setCurrentUserPubKey(_ pubKey: String) {
        shared.set(pubKey, forKey: Keys.currentUserPubKey)
        shared.synchronize()
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

    // Get Addie UUID from App Group shared UserDefaults
    static func getAddieUUID() -> String? {
        return shared.string(forKey: "addieUserUUID")
    }

    // Set Addie UUID in App Group shared UserDefaults
    static func setAddieUUID(_ uuid: String) {
        shared.set(uuid, forKey: "addieUserUUID")
        shared.synchronize()
        NSLog("ADDIE: Set Addie user UUID: %@", uuid)
    }

    // MARK: - CarrierBag Management
    static func getCarrierBag() -> [String: Any]? {
        return shared.dictionary(forKey: Keys.carrierBag)
    }

    static func saveCarrierBag(_ carrierBag: [String: Any]) {
        shared.set(carrierBag, forKey: Keys.carrierBag)
        shared.synchronize()
    }

    static func updateCarrierBagCollection(_ collection: String, items: [[String: Any]]) {
        var carrierBag = getCarrierBag() ?? createEmptyCarrierBag()
        carrierBag[collection] = items
        carrierBag["lastUpdated"] = ISO8601DateFormatter().string(from: Date())
        saveCarrierBag(carrierBag)
    }

    static func addToCarrierBagCollection(_ collection: String, item: [String: Any]) {
        var carrierBag = getCarrierBag() ?? createEmptyCarrierBag()
        var items = carrierBag[collection] as? [[String: Any]] ?? []
        items.append(item)
        carrierBag[collection] = items
        carrierBag["lastUpdated"] = ISO8601DateFormatter().string(from: Date())
        saveCarrierBag(carrierBag)
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
            "store": [],  // Shared affiliate links
            "links": [],  // Personal links (like linktree)
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
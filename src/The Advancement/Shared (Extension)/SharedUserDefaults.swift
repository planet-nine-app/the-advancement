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
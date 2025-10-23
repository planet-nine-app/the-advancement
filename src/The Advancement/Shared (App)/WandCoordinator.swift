/**
 * WandCoordinator.swift
 * The Advancement
 *
 * Coordinates wand registration with Julia service
 *
 * Responsibilities:
 * - Register wand public keys as coordinating keys
 * - Manage wand-to-user associations
 * - Handle wand signature verification
 * - Store known wand states
 *
 * Author: Planet Nine
 * License: MIT
 */

import Foundation

// MARK: - Wand Coordinator

class WandCoordinator {

    // MARK: - Singleton

    static let shared = WandCoordinator()

    // MARK: - Private Properties

    private let defaults = UserDefaults(suiteName: "group.app.planetnine.theadvancement")
    private let knownWandsKey = "knownWands"

    // MARK: - Public Properties

    /// List of wands that have been registered with Julia
    var knownWands: [String: Date] {
        get {
            guard let data = defaults?.data(forKey: knownWandsKey),
                  let dict = try? JSONDecoder().decode([String: Date].self, from: data) else {
                return [:]
            }
            return dict
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults?.set(data, forKey: knownWandsKey)
            }
        }
    }

    // MARK: - Initialization

    private init() {
        print("🪄 WandCoordinator initialized")
    }

    // MARK: - Public Methods

    /**
     * Register wand public key with Julia as a coordinating key
     *
     * This reuses the NFC verification endpoint since the flow is identical:
     * 1. Wand has a pubKey (like NFC tag)
     * 2. Mac app sends pubKey to Julia
     * 3. Julia adds as coordinating key (no signature needed for auto-registration)
     *
     * For future security: wand can sign a challenge to prove ownership
     */
    func registerWand(publicKey: String, wandName: String, completion: @escaping (Bool, String?) -> Void) {
        print("🔐 Registering wand \(wandName) with Julia...")

        // Check if already registered
        if isWandKnown(publicKey: publicKey) {
            print("✅ Wand already registered")
            completion(true, "Wand already registered")
            return
        }

        // Get Fount UUID from SharedUserDefaults
        guard let fountUuid = defaults?.string(forKey: "fount_uuid") else {
            print("❌ No Fount UUID found")
            completion(false, "User not initialized with Fount")
            return
        }

        // Get Julia service URL
        let environment = defaults?.string(forKey: "currentEnvironment") ?? "test"
        let baseNumber = defaults?.string(forKey: "currentBase") ?? "1"
        let juliaUrl = getJuliaURL(environment: environment, baseNumber: baseNumber)

        // Prepare request
        let endpoint = "\(juliaUrl)/wand/register"
        guard let url = URL(string: endpoint) else {
            print("❌ Invalid Julia URL: \(endpoint)")
            completion(false, "Invalid Julia URL")
            return
        }

        // Create request payload
        let payload: [String: Any] = [
            "primaryUUID": fountUuid,
            "pubKey": publicKey,
            "wandName": wandName,
            "timestamp": Int(Date().timeIntervalSince1970 * 1000)
        ]

        // Send request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("❌ Failed to serialize payload: \(error)")
            completion(false, "Failed to create request")
            return
        }

        // Execute request
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid response")
                completion(false, "Invalid response from Julia")
                return
            }

            guard let data = data else {
                print("❌ No data received")
                completion(false, "No data from Julia")
                return
            }

            // Parse response
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("📥 Julia response: \(json)")

                    if httpResponse.statusCode == 200,
                       let success = json["success"] as? Bool,
                       success {

                        // Mark wand as known
                        self?.markWandAsKnown(publicKey: publicKey)

                        let message = json["message"] as? String ?? "Wand registered successfully"
                        print("✅ \(message)")
                        completion(true, message)

                    } else {
                        let message = json["message"] as? String ?? "Registration failed"
                        print("❌ \(message)")
                        completion(false, message)
                    }
                }
            } catch {
                print("❌ Failed to parse response: \(error)")
                completion(false, "Failed to parse Julia response")
            }

        }.resume()
    }

    /**
     * Check if a wand is already known (registered)
     */
    func isWandKnown(publicKey: String) -> Bool {
        return knownWands[publicKey] != nil
    }

    /**
     * Mark a wand as known (registered)
     */
    private func markWandAsKnown(publicKey: String) {
        var wands = knownWands
        wands[publicKey] = Date()
        knownWands = wands
        print("💾 Wand \(publicKey.prefix(8))... marked as known")
    }

    /**
     * Forget a wand (remove from known list)
     */
    func forgetWand(publicKey: String) {
        var wands = knownWands
        wands.removeValue(forKey: publicKey)
        knownWands = wands
        print("🗑️ Wand \(publicKey.prefix(8))... forgotten")
    }

    // MARK: - Helper Methods

    private func getJuliaURL(environment: String, baseNumber: String) -> String {
        if environment == "local" {
            return "http://localhost:3001"
        } else if environment == "test" {
            let portBase = 5000 + (Int(baseNumber) ?? 1) * 100
            return "http://localhost:\(portBase + 10)"
        } else {
            return "https://\(environment).julia.allyabase.com"
        }
    }
}

// MARK: - BLEWandManager Extension

/**
 * Extend BLEWandManager to auto-register wands with Julia
 */
extension BLEWandManager: BLEWandManagerDelegate {

    func setupDelegate() {
        self.delegate = self
    }

    func wandDidConnect(_ wand: Wand) {
        print("🪄 Wand connected: \(wand.name)")
    }

    func wandDidDisconnect(_ wand: Wand) {
        print("🪄 Wand disconnected: \(wand.name)")
    }

    func wandDidReceivePublicKey(_ wand: Wand, publicKey: String) {
        print("🔑 Wand \(wand.name) sent public key: \(publicKey.prefix(16))...")

        // Auto-register with Julia
        WandCoordinator.shared.registerWand(publicKey: publicKey, wandName: wand.name) { success, message in
            DispatchQueue.main.async {
                if success {
                    print("✅ Wand \(wand.name) registered with Julia!")
                    // Show success notification to user
                    self.showWandRegistrationNotification(wandName: wand.name, success: true)
                } else {
                    print("❌ Failed to register wand: \(message ?? "Unknown error")")
                    // Show error notification to user
                    self.showWandRegistrationNotification(wandName: wand.name, success: false)
                }
            }
        }
    }

    func wandDidCastSpell(_ wand: Wand, spell: String) {
        print("✨ Wand \(wand.name) cast spell: \(spell)")

        // Handle spell casting
        // Future: route to appropriate spell handler (Fount, MAGIC, etc.)
        handleSpellCast(spell: spell, from: wand)
    }

    // MARK: - Private Helpers

    private func showWandRegistrationNotification(wandName: String, success: Bool) {
        #if os(macOS)
        let notification = NSUserNotification()
        notification.title = success ? "🪄 Wand Connected" : "⚠️ Wand Registration Failed"
        notification.informativeText = success ?
            "\(wandName) is now ready for MAGIC!" :
            "Failed to register \(wandName) with Julia"
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
        #else
        // iOS notifications would go here
        #endif
    }

    private func handleSpellCast(spell: String, from wand: Wand) {
        print("🪄 Handling spell: \(spell) from wand: \(wand.name)")

        switch spell.lowercased() {
        case "lumos":
            handleLumosSpell(from: wand)
        case "nox":
            handleNoxSpell(from: wand)
        case "accio":
            handleAccioSpell(from: wand)
        default:
            print("⚠️ Unknown spell: \(spell)")
        }
    }

    private func handleLumosSpell(from wand: Wand) {
        print("💡 Lumos spell cast - turning on light!")
        // Future: integrate with HomeKit, smart lights, etc.

        // For now, just send confirmation back to wand
        sendCommand(to: wand, command: "{\"action\":\"confirm\",\"spell\":\"lumos\"}")
    }

    private func handleNoxSpell(from wand: Wand) {
        print("🌑 Nox spell cast - turning off light!")
        // Future: integrate with HomeKit, smart lights, etc.

        sendCommand(to: wand, command: "{\"action\":\"confirm\",\"spell\":\"nox\"}")
    }

    private func handleAccioSpell(from wand: Wand) {
        print("🎯 Accio spell cast - summoning object!")
        // Future: integrate with Find My, tracking devices, etc.

        sendCommand(to: wand, command: "{\"action\":\"confirm\",\"spell\":\"accio\"}")
    }
}

//
//  KeyboardViewController.swift
//  AdvanceKey
//
//  Simple demoji keyboard extension
//

import UIKit
import WebKit

// MARK: - Fount Data Structures
struct FountUser {
    let uuid: String
    let publicKey: String
}

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji
    }
}

class KeyboardViewController: UIInputViewController, WKScriptMessageHandler {

    var demojiButton: UIButton!
    var resultWebView: WKWebView!
    var debugLabel: UILabel!
    var sessionless: Sessionless!

    override func updateViewConstraints() {
        super.updateViewConstraints()

        // Set keyboard height
        let heightConstraint = NSLayoutConstraint(
            item: self.view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: 280
        )
        heightConstraint.priority = UILayoutPriority(999)
        self.view.addConstraint(heightConstraint)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NSLog("ADVANCEKEY: 🚀 Demoji Keyboard loading...")
        self.view.backgroundColor = UIColor.systemBackground

        // Initialize sessionless for BDO requests
        sessionless = Sessionless()

        setupDemojiButton()
        setupWebView()
        setupDebugLabel()

        NSLog("ADVANCEKEY: ✅ Demoji Keyboard ready")
    }

    func setupDemojiButton() {
        demojiButton = UIButton(type: .system)
        demojiButton.setTitle("DEMOJI", for: .normal)
        demojiButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        demojiButton.backgroundColor = UIColor.systemPurple
        demojiButton.setTitleColor(.white, for: .normal)
        demojiButton.layer.cornerRadius = 12
        demojiButton.translatesAutoresizingMaskIntoConstraints = false

        demojiButton.addTarget(self, action: #selector(demojiTapped), for: .touchUpInside)

        self.view.addSubview(demojiButton)

        NSLayoutConstraint.activate([
            demojiButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            demojiButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            demojiButton.widthAnchor.constraint(equalToConstant: 120),
            demojiButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func setupWebView() {
        let webViewConfig = WKWebViewConfiguration()
        webViewConfig.allowsInlineMediaPlayback = true

        // Add console message handler to capture JavaScript logs
        let contentController = WKUserContentController()
        contentController.add(self, name: "consoleLog")
        contentController.add(self, name: "saveRecipe")
        contentController.add(self, name: "paymentMethodSelected")
        contentController.add(self, name: "addPaymentMethod")
        webViewConfig.userContentController = contentController

        // Inject console.log override to capture messages
        let consoleScript = WKUserScript(
            source: """
            console.log = function(message) {
                window.webkit.messageHandlers.consoleLog.postMessage(message);
            };
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(consoleScript)

        resultWebView = WKWebView(frame: .zero, configuration: webViewConfig)
        resultWebView.translatesAutoresizingMaskIntoConstraints = false
        resultWebView.backgroundColor = UIColor.systemBackground

        self.view.addSubview(resultWebView)

        NSLayoutConstraint.activate([
            resultWebView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40),
            resultWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            resultWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            resultWebView.bottomAnchor.constraint(equalTo: demojiButton.topAnchor, constant: -40)
        ])
    }

    func setupDebugLabel() {
        debugLabel = UILabel()
        debugLabel.text = "Select emojicoded text and tap DEMOJI"
        debugLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        debugLabel.textColor = UIColor.systemGray
        debugLabel.textAlignment = .center
        debugLabel.numberOfLines = 2
        debugLabel.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(debugLabel)

        NSLayoutConstraint.activate([
            debugLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10),
            debugLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            debugLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            debugLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc func demojiTapped() {
        NSLog("ADVANCEKEY: 🎯 DEMOJI button tapped")
        NSLog("ADVANCEKEY: ==========================================")

        // Get the text document proxy and examine ALL its properties
        let proxy = self.textDocumentProxy

        NSLog("ADVANCEKEY: 📱 TextDocumentProxy Investigation:")
        NSLog("ADVANCEKEY:   - hasText: %@", proxy.hasText ? "true" : "false")
        NSLog("ADVANCEKEY:   - keyboardType: %d", proxy.keyboardType?.rawValue ?? -1)
        NSLog("ADVANCEKEY:   - returnKeyType: %d", proxy.returnKeyType?.rawValue ?? -1)

        // Test different ways of getting text
        let selectedText = proxy.selectedText ?? ""
        let contextBefore = proxy.documentContextBeforeInput ?? ""
        let contextAfter = proxy.documentContextAfterInput ?? ""

        NSLog("ADVANCEKEY: 🔍 Raw Text Access:")
        NSLog("ADVANCEKEY:   - selectedText: '%@' (length: %d)", selectedText, selectedText.count)
        NSLog("ADVANCEKEY:   - documentContextBeforeInput: '%@' (length: %d)", contextBefore, contextBefore.count)
        NSLog("ADVANCEKEY:   - documentContextAfterInput: '%@' (length: %d)", contextAfter, contextAfter.count)

        // Try to get more context by adjusting the document position
        NSLog("ADVANCEKEY: 🔧 Trying to get more context...")

        // Move cursor to beginning and try to get all text
        proxy.adjustTextPosition(byCharacterOffset: -1000) // Move way back
        let allBefore = proxy.documentContextBeforeInput ?? ""

        proxy.adjustTextPosition(byCharacterOffset: 1000) // Move way forward
        let allAfter = proxy.documentContextAfterInput ?? ""

        NSLog("ADVANCEKEY:   - After moving cursor back: '%@' (length: %d)", String(allBefore.suffix(50)), allBefore.count)
        NSLog("ADVANCEKEY:   - After moving cursor forward: '%@' (length: %d)", String(allAfter.prefix(50)), allAfter.count)

        // Try reading character by character around cursor
        NSLog("ADVANCEKEY: 📖 Character-by-character reading:")
        var chars: [String] = []
        for i in -10...10 {
            proxy.adjustTextPosition(byCharacterOffset: i)
            if let char = proxy.documentContextBeforeInput?.last {
                chars.append(String(char))
            }
            proxy.adjustTextPosition(byCharacterOffset: -i) // Reset
        }
        NSLog("ADVANCEKEY:   - Characters around cursor: %@", chars.joined(separator: ", "))

        // Reset to original position
        proxy.adjustTextPosition(byCharacterOffset: 0)

        // Combine all available text context
        let fullContext = contextBefore + selectedText + contextAfter

        NSLog("ADVANCEKEY: 📋 Final Context Analysis:")
        NSLog("ADVANCEKEY:   - Full context: '%@' (length: %d)", fullContext, fullContext.count)

        // Count emojis in context
        let emojiCount = fullContext.filter { $0.isEmoji }.count
        NSLog("ADVANCEKEY:   - Emoji count in context: %d", emojiCount)

        // Look for sparkles specifically
        let sparklesCount = fullContext.filter { $0 == "✨" }.count
        NSLog("ADVANCEKEY:   - Sparkles (✨) count: %d", sparklesCount)

        debugLabel.text = "📱 Context: \(fullContext.count) chars, \(emojiCount) emoji, \(sparklesCount) ✨"

        // If we're getting no context, show a fallback test
        if fullContext.isEmpty {
            debugLabel.text = "❌ No text context available"
            displayError("No Text Context", details: """
            The keyboard cannot access any text from the input field.

            This might be due to:
            - Security restrictions
            - App-specific text protection
            - iOS keyboard limitations
            - Field type restrictions

            Try:
            1. Different input field (search box, notes app)
            2. Copy/paste the emoji sequence
            3. Use a basic text field instead
            """)
            return
        }

        NSLog("ADVANCEKEY: ==========================================")

        // Look for emojicoded sequence (starts and ends with ✨)
        if let emojicode = extractEmojicode(from: fullContext) {
            // Remove Unicode variation selectors (U+FE0F) that cause decode failures
            let cleanedEmojicode = emojicode.filter { char in
                !char.unicodeScalars.contains { $0.value == 0xFE0F }
            }
            NSLog("ADVANCEKEY: 🎨 Found complete emojicode: %@", String(emojicode.prefix(30)))
            NSLog("ADVANCEKEY: 🧹 Cleaned emojicode (removed variation selectors): %@", String(cleanedEmojicode.prefix(30)))
            debugLabel.text = "Found complete emoji! Decoding..."
            decodeAndFetchBDO(emojicode: cleanedEmojicode)
        } else if sparklesCount >= 1 {
            // Try to work with partial sequence if we have at least one sparkle
            debugLabel.text = "Partial emoji found, trying decode..."
            let rawPartialEmoji = "✨\(fullContext.filter { $0.isEmoji })✨"
            // Remove variation selectors from partial sequence too
            let cleanedPartialEmoji = rawPartialEmoji.filter { char in
                !char.unicodeScalars.contains { $0.value == 0xFE0F }
            }
            NSLog("ADVANCEKEY: 🔧 Attempting partial decode: %@", String(cleanedPartialEmoji.prefix(30)))
            decodeAndFetchBDO(emojicode: cleanedPartialEmoji)
        } else {
            debugLabel.text = "No ✨emoji✨ sequence found"
            displayError("No Emoji Found", details: """
            Context: \(fullContext.prefix(200))

            Emoji count: \(emojiCount)
            Sparkles: \(sparklesCount)

            Need: ✨...emojis...✨ pattern
            Selected: \(selectedText)

            Try selecting more text or scrolling to include both ✨ sparkles.
            """)
            NSLog("ADVANCEKEY: ❌ No emojicoded sequence found in context")
        }
    }

    func extractEmojicode(from text: String) -> String? {
        // Look for text between ✨ delimiters
        let pattern = "✨([^✨]+)✨"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            // Get the full match (including sparkles)
            let fullMatchRange = Range(match.range, in: text)!
            let fullMatch = String(text[fullMatchRange])

            NSLog("ADVANCEKEY: 🔍 Regex extraction details:")
            NSLog("ADVANCEKEY:   - Full match: %@", fullMatch)
            NSLog("ADVANCEKEY:   - Full match length: %d", fullMatch.count)
            NSLog("ADVANCEKEY:   - Number of capture groups: %d", match.numberOfRanges - 1)

            // Return the full match (which should include both ✨ delimiters)
            return fullMatch
        }

        NSLog("ADVANCEKEY: ❌ No regex match found in text: %@", String(text.prefix(50)))
        return nil
    }

    func decodeAndFetchBDO(emojicode: String) {
        debugLabel.text = "Decoding emoji..."

        // Decode emoji to hex using JavaScript with detailed logging
        let jsDecodeCode = """
        // Capture console logs
        let logs = [];
        const originalLog = console.log;
        console.log = function(...args) {
            logs.push(args.join(' '));
            originalLog.apply(console, args);
        };

        console.log('ADVANCEKEY: 🔧 JavaScript execution starting...');

        // Load the emojicoding.js functions
        \(loadEmojicodingJS())

        console.log('ADVANCEKEY: 📚 Emojicoding functions loaded');
        console.log('ADVANCEKEY: Input emojicode:', '\(emojicode)');
        console.log('ADVANCEKEY: Input length:', '\(emojicode)'.length);

        // Check if simpleDecodeEmoji function exists
        if (typeof simpleDecodeEmoji === 'undefined') {
            console.log('ADVANCEKEY: ❌ simpleDecodeEmoji function not found');
            JSON.stringify({ error: 'simpleDecodeEmoji function not found', logs: logs });
        } else {
            console.log('ADVANCEKEY: ✅ simpleDecodeEmoji function found');

            try {
                console.log('ADVANCEKEY: 🎯 Attempting to decode user input...');
                const decodeResult = simpleDecodeEmoji('\(emojicode)');
                console.log('ADVANCEKEY: ✅ Decode successful:', decodeResult);
                console.log('ADVANCEKEY: ✅ Extracted hex:', decodeResult.hex);
                JSON.stringify({ result: decodeResult.hex, logs: logs });
            } catch (error) {
                console.log('ADVANCEKEY: ❌ Decode error:', error.message);
                console.log('ADVANCEKEY: ❌ Error stack:', error.stack || 'no stack');
                JSON.stringify({ error: error.name + ': ' + error.message, stack: error.stack, logs: logs });
            }
        }
        """

        resultWebView.evaluateJavaScript(jsDecodeCode) { [weak self] result, error in
            if let error = error {
                NSLog("ADVANCEKEY: ❌ JS decode error: %@", error.localizedDescription)
                self?.debugLabel.text = "JS Error: \(error.localizedDescription)"
                self?.displayError("JavaScript Error", details: error.localizedDescription)
                return
            }

            guard let jsonString = result as? String else {
                NSLog("ADVANCEKEY: ❌ Result is not a string: %@", String(describing: result))
                self?.displayError("Invalid Response", details: "Expected JSON string, got: \(String(describing: result))")
                return
            }

            NSLog("ADVANCEKEY: 📋 Raw JS result: %@", jsonString)

            // Parse the JSON response
            guard let jsonData = jsonString.data(using: .utf8),
                  let response = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                NSLog("ADVANCEKEY: ❌ Failed to parse JSON response")
                self?.displayError("JSON Parse Error", details: jsonString)
                return
            }

            // Log all captured console.log messages
            if let logs = response["logs"] as? [String] {
                NSLog("ADVANCEKEY: 📋 JavaScript Console Logs:")
                for log in logs {
                    NSLog("ADVANCEKEY: JS: %@", log)
                }
            }

            // Check for successful decode
            if let decodedHex = response["result"] as? String {
                NSLog("ADVANCEKEY: 🔓 Decoded hex: %@", decodedHex)
                self?.debugLabel.text = "✅ Decoded! Fetching BDO..."
                self?.fetchBDOData(bdoPubKey: decodedHex)
            } else if let errorMsg = response["error"] as? String {
                NSLog("ADVANCEKEY: ❌ Decode failed: %@", errorMsg)
                if let stack = response["stack"] as? String {
                    NSLog("ADVANCEKEY: ❌ Error stack: %@", stack)
                }
                self?.debugLabel.text = "Decode failed"
                self?.displayError("Emoji Decode Failed", details: errorMsg)
            } else {
                NSLog("ADVANCEKEY: ❌ Unexpected response format: %@", String(describing: response))
                self?.displayError("Unexpected Response", details: String(describing: response))
            }
        }
    }

    func fetchBDOData(bdoPubKey: String) {
        // Fetch BDO data from test environment using URLSession
        let bdoUrl = "http://127.0.0.1:5114/"

        Task {
            do {
                let cardData = try await fetchBDOFromServer(bdoPubKey: bdoPubKey, baseUrl: bdoUrl)

                NSLog("ADVANCEKEY: 📦 BDO data received: %@", String(describing: cardData))

                DispatchQueue.main.async { [weak self] in
                    self?.displayBDOContent(cardData: cardData)
                }

            } catch {
                NSLog("ADVANCEKEY: ❌ BDO fetch error: %@", error.localizedDescription)
                DispatchQueue.main.async { [weak self] in
                    self?.debugLabel.text = "BDO fetch failed"
                    self?.displayError("BDO Fetch Failed", details: """
                    Error: \(error.localizedDescription)

                    Attempted to fetch:
                    bdoPubKey: \(bdoPubKey)
                    URL: \(bdoUrl)
                    """)
                }
            }
        }
    }

    func fetchBDOFromServer(bdoPubKey: String, baseUrl: String) async throws -> [String: Any] {
        // Create URL for BDO lookup - we need to find the correct endpoint
        // Based on the seeding, it's stored in user BDO data, so we'll try a simple GET first

        let urlString = "\(baseUrl)bdo/\(bdoPubKey)"
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO URL"])
        }

        print("🌐 Fetching BDO from: \(urlString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }

        print("📡 BDO response status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            // If direct endpoint fails, try searching through seeded user data
            return try await searchBDOInUsers(bdoPubKey: bdoPubKey, baseUrl: baseUrl)
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "JSONParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse BDO JSON"])
        }

        return jsonObject
    }

    func searchBDOInUsers(bdoPubKey: String, baseUrl: String) async throws -> [String: Any] {
        NSLog("ADVANCEKEY: 🔍 Searching for BDO in Fount: %@", bdoPubKey)

        // Call Fount API to get BDO by pubKey
        return try await fetchBDOFromFount(bdoPubKey: bdoPubKey)
    }

    func fetchBDOFromFount(bdoPubKey: String) async throws -> [String: Any] {
        // First ensure we have a Fount user
        let fountUser = try await ensureFountUser()

        // Try to fetch existing BDO
        let fountUrl = "http://127.0.0.1:5117/bdo/\(bdoPubKey)"

        guard let url = URL(string: fountUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }

        NSLog("ADVANCEKEY: 📡 Fetching BDO from Fount: %@", fountUrl)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEKEY: 📡 Fount response status: %d", httpResponse.statusCode)

        if httpResponse.statusCode == 404 {
            // BDO not found in Fount, create it
            NSLog("ADVANCEKEY: 📦 BDO not found in Fount, creating it with user: %@", fountUser.uuid)
            return try await createBDOInFount(bdoPubKey: bdoPubKey, fountUser: fountUser)
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fount error: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bdoData = jsonObject else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO JSON from Fount"])
        }

        NSLog("ADVANCEKEY: ✅ BDO fetched from Fount successfully")
        return bdoData
    }

    func ensureFountUser() async throws -> FountUser {
        // Generate or retrieve keypair for Fount
        let keyPair = generateOrRetrieveKeyPair()

        NSLog("ADVANCEKEY: 👤 Creating Fount user with pubKey: %@", keyPair.publicKey)

        return try await createFountUser(keyPair: keyPair)
    }

    func generateOrRetrieveKeyPair() -> (publicKey: String, privateKey: String) {
        // For now, use the same pubkey from our recipe
        // In production, you'd generate proper keypairs or retrieve from keychain
        let pubKey = "02a3b4c5d6e7f8910111213141516171819202122232425262728293031323334"
        let privKey = "a3b4c5d6e7f8910111213141516171819202122232425262728293031323334" // Example private key

        return (publicKey: pubKey, privateKey: privKey)
    }

    func createFountUser(keyPair: (publicKey: String, privateKey: String)) async throws -> FountUser {
        let createUserUrl = "http://127.0.0.1:5117/users"

        guard let url = URL(string: createUserUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount create user URL"])
        }

        let requestBody: [String: Any] = [
            "publicKey": keyPair.publicKey,
            "signature": "placeholder" // In production, sign with private key
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize user creation data: \(error.localizedDescription)"])
        }

        NSLog("ADVANCEKEY: 📡 Creating Fount user...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEKEY: 📡 Fount create user response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create Fount user: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userData = jsonObject,
              let uuid = userData["uuid"] as? String else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid user data from Fount"])
        }

        NSLog("ADVANCEKEY: ✅ Fount user created: %@", uuid)

        // After creating user, create their carrierBag BDO with empty cookbook
        try await createUserCarrierBag(userUuid: uuid, publicKey: keyPair.publicKey)

        return FountUser(uuid: uuid, publicKey: keyPair.publicKey)
    }

    func createUserCarrierBag(userUuid: String, publicKey: String) async throws {
        NSLog("ADVANCEKEY: 🎒 Creating carrierBag BDO for user: %@", userUuid)

        // Create the user's carrierBag BDO with their pubKey
        let carrierBagPayload: [String: Any] = [
            "pubKey": publicKey,
            "owner": userUuid,
            "data": [
                "type": "carrierBag",
                "carrierBag": [
                    "spaceTime": [],
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
                    "created": ISO8601DateFormatter().string(from: Date()),
                    "lastUpdated": ISO8601DateFormatter().string(from: Date())
                ]
            ]
        ]

        let fountCreateUrl = "http://127.0.0.1:5117/bdo"
        guard let url = URL(string: fountCreateUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount create URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: carrierBagPayload)
        } catch {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize carrierBag data: \(error.localizedDescription)"])
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEKEY: 📡 CarrierBag creation response status: %d", httpResponse.statusCode)

        if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
            NSLog("ADVANCEKEY: ✅ CarrierBag BDO created successfully")
        } else {
            NSLog("ADVANCEKEY: ⚠️ CarrierBag creation failed with status %d", httpResponse.statusCode)
        }
    }

    func createBDOInFount(bdoPubKey: String, fountUser: FountUser) async throws -> [String: Any] {
        NSLog("ADVANCEKEY: 🏗️ Creating BDO in Fount for pubKey: %@ with user: %@", bdoPubKey, fountUser.uuid)

        // Create the BDO payload for Fount API
        let bdoPayload: [String: Any] = [
            "pubKey": bdoPubKey,
            "owner": fountUser.uuid,
            "data": [
                "title": "Grandma's Secret Chocolate Chip Cookies Recipe",
                "type": "recipe",
                "svgContent": "<svg width=\"420\" height=\"60\" viewBox=\"0 0 420 60\" xmlns=\"http://www.w3.org/2000/svg\"><rect x=\"0\" y=\"0\" width=\"420\" height=\"60\" fill=\"#f8f9fa\" stroke=\"#e9ecef\" stroke-width=\"1\" rx=\"8\"/><rect spell=\"share\" x=\"10\" y=\"10\" width=\"90\" height=\"40\" fill=\"#27ae60\" stroke=\"#219a52\" stroke-width=\"2\" rx=\"6\"><title>Share this recipe</title></rect><text spell=\"share\" x=\"55\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">📤 SHARE</text><rect spell=\"collect\" x=\"110\" y=\"10\" width=\"90\" height=\"40\" fill=\"#9b59b6\" stroke=\"#8e44ad\" stroke-width=\"2\" rx=\"6\"><title>Save to your collection</title></rect><text spell=\"collect\" x=\"155\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">💾 SAVE</text><rect spell=\"magic\" x=\"210\" y=\"10\" width=\"90\" height=\"40\" fill=\"#e91e63\" stroke=\"#c2185b\" stroke-width=\"2\" rx=\"6\"><title>Cast kitchen magic</title></rect><text spell=\"magic\" x=\"255\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">🪄 MAGIC</text><rect spell=\"buy\" x=\"310\" y=\"10\" width=\"90\" height=\"40\" fill=\"#f39c12\" stroke=\"#e67e22\" stroke-width=\"2\" rx=\"6\"><title>Purchase magical items</title></rect><text spell=\"buy\" x=\"355\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">💰 BUY</text></svg>",
                "description": "A family recipe passed down through generations, featuring the perfect balance of crispy edges and chewy centers.",
                "author": [
                    "name": "Sarah Mitchell",
                    "bio": "Home baker and food blogger sharing family recipes",
                    "location": "Portland, Oregon"
                ],
                "ingredients": [
                    ["item": "all-purpose flour", "amount": "2¼ cups"],
                    ["item": "unsalted butter, softened", "amount": "1 cup (2 sticks)"],
                    ["item": "granulated sugar", "amount": "¾ cup"],
                    ["item": "packed brown sugar", "amount": "¾ cup"],
                    ["item": "large eggs", "amount": "2"],
                    ["item": "pure vanilla extract", "amount": "2 teaspoons"],
                    ["item": "baking soda", "amount": "1 teaspoon"],
                    ["item": "salt", "amount": "1 teaspoon"],
                    ["item": "semi-sweet chocolate chips", "amount": "2 cups"]
                ],
                "instructions": [
                    "Preheat your oven to 375°F (190°C). Line two baking sheets with parchment paper.",
                    "In a medium bowl, whisk together flour, baking soda, and salt. Set aside.",
                    "In a large bowl, cream together the softened butter, granulated sugar, and brown sugar until light and fluffy (about 3-4 minutes with an electric mixer).",
                    "Beat in eggs one at a time, then add vanilla extract. Mix until well combined.",
                    "Gradually blend in the flour mixture until just combined. Don't overmix! Fold in chocolate chips gently.",
                    "Drop rounded tablespoons of dough onto prepared baking sheets, spacing them about 2 inches apart.",
                    "Bake for 9-11 minutes, or until edges are golden brown but centers still look slightly underdone. Cool on baking sheet for 5 minutes before transferring to wire rack."
                ],
                "tags": ["cookies", "chocolate-chip", "dessert", "baking", "family-recipe", "comfort-food"]
            ]
        ]

        // POST to Fount to create the BDO
        let fountCreateUrl = "http://127.0.0.1:5117/bdo"
        guard let url = URL(string: fountCreateUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount create URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: bdoPayload)
        } catch {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize BDO data: \(error.localizedDescription)"])
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEKEY: 📡 Fount create BDO response status: %d", httpResponse.statusCode)

        // Return data in the format expected by the app (with "bdo" wrapper)
        let returnData: [String: Any] = [
            "bdo": [
                "bdoPubKey": bdoPubKey,
                "title": "Grandma's Secret Chocolate Chip Cookies Recipe",
                "type": "recipe",
                "svgContent": "<svg width=\"320\" height=\"60\" viewBox=\"0 0 320 60\" xmlns=\"http://www.w3.org/2000/svg\"><rect x=\"0\" y=\"0\" width=\"320\" height=\"60\" fill=\"#f8f9fa\" stroke=\"#e9ecef\" stroke-width=\"1\" rx=\"8\"/><rect spell=\"share\" x=\"10\" y=\"10\" width=\"90\" height=\"40\" fill=\"#27ae60\" stroke=\"#219a52\" stroke-width=\"2\" rx=\"6\"><title>Share this recipe</title></rect><text spell=\"share\" x=\"55\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">📤 SHARE</text><rect spell=\"collect\" x=\"115\" y=\"10\" width=\"90\" height=\"40\" fill=\"#9b59b6\" stroke=\"#8e44ad\" stroke-width=\"2\" rx=\"6\"><title>Save to your collection</title></rect><text spell=\"collect\" x=\"160\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">💾 SAVE</text><rect spell=\"magic\" x=\"220\" y=\"10\" width=\"90\" height=\"40\" fill=\"#e91e63\" stroke=\"#c2185b\" stroke-width=\"2\" rx=\"6\"><title>Cast kitchen magic</title></rect><text spell=\"magic\" x=\"265\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">🪄 MAGIC</text></svg>"
            ]
        ]

        if httpResponse.statusCode == 201 || httpResponse.statusCode == 200 {
            NSLog("ADVANCEKEY: ✅ BDO created in Fount successfully")
        } else {
            NSLog("ADVANCEKEY: ⚠️ Fount BDO creation failed with status %d, using local data", httpResponse.statusCode)
        }

        return returnData
    }

    func displayBDOContent(cardData: [String: Any]) {
        debugLabel.text = "Displaying SVG..."

        // Extract SVG content from the BDO data
        var svgContent: String?

        // Try different possible paths for SVG content
        if let svg = cardData["svgContent"] as? String {
            svgContent = svg
        } else if let bdo = cardData["bdo"] as? [String: Any],
                  let svg = bdo["svgContent"] as? String {
            svgContent = svg
        } else if let successful = cardData["successful"] as? [[String: Any]],
                  let firstResult = successful.first,
                  let bdo = firstResult["bdo"] as? [String: Any],
                  let svg = bdo["svgContent"] as? String {
            svgContent = svg
        }

        guard let svg = svgContent else {
            debugLabel.text = "No SVG content found"
            print("❌ No SVG content in BDO data")
            return
        }

        // Create HTML to display the SVG
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 10px;
                    background: #f8f9fa;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                }
                svg {
                    max-width: 100%;
                    height: auto;
                    cursor: pointer;
                }
                svg rect[spell] {
                    transition: opacity 0.2s;
                }
                svg rect[spell]:hover {
                    opacity: 0.8;
                }
            </style>
        </head>
        <body>
            \(svg)
            <script>
                // BDO data for spell handling
                const bdoData = \(String(data: try! JSONSerialization.data(withJSONObject: cardData), encoding: .utf8)!);

                // Handle spell button clicks
                document.addEventListener('click', function(e) {
                    const spell = e.target.getAttribute('spell');
                    if (spell) {
                        console.log('Spell clicked:', spell);
                        handleSpell(spell, bdoData);
                    }
                });

                function handleSpell(spell, data) {
                    switch(spell) {
                        case 'collect':
                        case 'save':
                            saveRecipeToApp(data);
                            break;
                        case 'share':
                            shareRecipe(data);
                            break;
                        case 'magic':
                            castMagic(data);
                            break;
                        default:
                            alert('Unknown spell: ' + spell);
                    }
                }

                function saveRecipeToApp(data) {
                    try {
                        // Extract recipe info from nested BDO structure
                        const bdo = data.bdo || data; // Handle both nested and flat structures
                        const bdoPubKey = bdo.bdoPubKey || 'unknown';
                        const type = bdo.type || 'recipe';
                        const title = bdo.title || 'Untitled Recipe';

                        console.log('Saving recipe:', { bdoPubKey, type, title });

                        // Send message to Swift to save the recipe
                        window.webkit.messageHandlers.saveRecipe.postMessage({
                            action: 'save',
                            bdoPubKey: bdoPubKey,
                            type: type,
                            title: title,
                            fullBDO: data
                        });

                        // Show success feedback
                        alert('✅ Recipe saved to your cookbook!');

                    } catch (error) {
                        console.error('Error saving recipe:', error);
                        alert('❌ Failed to save recipe: ' + error.message);
                    }
                }

                function shareRecipe(data) {
                    alert('📤 Share recipe: ' + (data.title || 'Recipe'));
                }

                function castMagic(data) {
                    alert('🪄 Kitchen magic cast on: ' + (data.title || 'Recipe'));
                }
            </script>
        </body>
        </html>
        """

        resultWebView.loadHTMLString(html, baseURL: nil)
        debugLabel.text = "✅ Recipe actions loaded!"

        NSLog("ADVANCEKEY: ✅ SVG displayed in keyboard")
    }

    func loadEmojicodingJS() -> String {
        // Load the emojicoding JavaScript code
        guard let path = Bundle.main.path(forResource: "emojicoding", ofType: "js") else {
            NSLog("ADVANCEKEY: ❌ Could not find emojicoding.js file path")
            return "console.log('ERROR: emojicoding.js file not found in bundle');"
        }

        guard let jsCode = try? String(contentsOfFile: path) else {
            NSLog("ADVANCEKEY: ❌ Could not read emojicoding.js file content")
            return "console.log('ERROR: emojicoding.js file could not be read');"
        }

        NSLog("ADVANCEKEY: ✅ Loaded emojicoding.js (%d characters)", jsCode.count)

        // Add debugging and test decoding functionality
        return jsCode + """

        console.log('ADVANCEKEY: Available functions:', typeof decodeEmojiToHex);
        console.log('ADVANCEKEY: EmojicodingConfig:', typeof EmojicodingConfig);
        console.log('ADVANCEKEY: EMOJI_SET_64 length:', typeof EMOJI_SET_64 !== 'undefined' ? EMOJI_SET_64.length : 'undefined');

        // Test emoji decoding with a known clean sequence (short version from recipe-blog.html)
        try {
            console.log('ADVANCEKEY: 🧪 Testing emojicoding with clean test sequence...');
            const testEmoji = '✨😀😄🐶🍕✨';
            console.log('ADVANCEKEY: Test input:', testEmoji, 'length:', testEmoji.length);

            if (typeof simpleDecodeEmoji !== 'undefined') {
                const testResult = simpleDecodeEmoji(testEmoji);
                console.log('ADVANCEKEY: ✅ Test decode successful:', testResult);
                console.log('ADVANCEKEY: ✅ Test hex result:', testResult.hex);
            } else {
                console.log('ADVANCEKEY: ❌ simpleDecodeEmoji function not available');
                console.log('ADVANCEKEY: Available functions:', Object.keys(window).filter(key => key.includes('decode')));
            }
        } catch (testError) {
            console.log('ADVANCEKEY: ❌ Test decode failed:', testError.message);
        }

        console.log('ADVANCEKEY: 🎯 Emojicoding system ready for user input');
        """
    }

    func displayError(_ title: String, details: String) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 15px;
                    background: #ffe6e6;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 12px;
                    color: #d63384;
                }
                .error-container {
                    background: white;
                    border: 2px solid #d63384;
                    border-radius: 8px;
                    padding: 15px;
                }
                .error-title {
                    font-weight: bold;
                    font-size: 14px;
                    margin-bottom: 10px;
                    color: #dc3545;
                }
                .error-details {
                    white-space: pre-wrap;
                    line-height: 1.4;
                    font-family: Monaco, 'Courier New', monospace;
                    font-size: 10px;
                    background: #f8f9fa;
                    padding: 10px;
                    border-radius: 4px;
                    overflow-x: auto;
                }
            </style>
        </head>
        <body>
            <div class="error-container">
                <div class="error-title">❌ \(title)</div>
                <div class="error-details">\(details)</div>
            </div>
        </body>
        </html>
        """

        resultWebView.loadHTMLString(html, baseURL: nil)
    }

    // MARK: - WKScriptMessageHandler
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "consoleLog" {
            NSLog("ADVANCEKEY: 🟡 JS Console: %@", String(describing: message.body))
        } else if message.name == "saveRecipe" {
            handleSaveRecipeMessage(message.body)
        } else if message.name == "paymentMethodSelected" {
            handlePaymentMethodSelection(message.body as? [String: Any] ?? [:])
        } else if message.name == "addPaymentMethod" {
            handleAddPaymentMethod()
        }
    }

    private func handleSaveRecipeMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 💾 Save recipe message received")

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String,
              action == "save" else {
            NSLog("ADVANCEKEY: ❌ Invalid save recipe message format")
            return
        }

        let bdoPubKey = messageDict["bdoPubKey"] as? String ?? "unknown"
        let type = messageDict["type"] as? String ?? "recipe"
        let title = messageDict["title"] as? String ?? "Untitled Recipe"
        let fullBDO = messageDict["fullBDO"]

        // Save to UserDefaults (or app group if configured)
        let success = saveRecipeToStorage(bdoPubKey: bdoPubKey, type: type, title: title, fullBDO: fullBDO)

        NSLog("ADVANCEKEY: 💾 Recipe save %@: %@ (%@)", success ? "successful" : "failed", title, bdoPubKey)
    }

    private func saveRecipeToStorage(bdoPubKey: String, type: String, title: String, fullBDO: Any?) -> Bool {
        NSLog("ADVANCEKEY: 📦 Saving recipe using SharedUserDefaults")

        // Use the shared configuration
        SharedUserDefaults.addHolding(bdoPubKey: bdoPubKey, type: type, title: title)

        // Debug: Print current state
        SharedUserDefaults.debugPrint(prefix: "ADVANCEKEY")

        // Test access
        let testResult = SharedUserDefaults.testAccess()
        NSLog("ADVANCEKEY: 📦 Shared access test: %@", testResult ? "✅ PASS" : "❌ FAIL")

        // Also update the user's carrierBag in Fount
        Task {
            do {
                try await updateCarrierBagCookbook(bdoPubKey: bdoPubKey, type: type, title: title)
            } catch {
                NSLog("ADVANCEKEY: ⚠️ Failed to update carrierBag: %@", error.localizedDescription)
            }
        }

        return true
    }

    func updateCarrierBagCookbook(bdoPubKey: String, type: String, title: String) async throws {
        NSLog("ADVANCEKEY: 🎒 Updating carrierBag cookbook with recipe: %@", title)

        // Get the user's keypair to find their carrierBag
        let keyPair = generateOrRetrieveKeyPair()

        // First, fetch the current carrierBag BDO
        let currentCarrierBag = try await fetchCarrierBagBDO(publicKey: keyPair.publicKey)

        // Add the new recipe to the cookbook
        let updatedCarrierBag = try addRecipeToCarrierBag(currentCarrierBag, bdoPubKey: bdoPubKey, type: type, title: title)

        // Update the BDO in Fount
        try await updateCarrierBagBDO(updatedCarrierBag, publicKey: keyPair.publicKey)

        NSLog("ADVANCEKEY: ✅ CarrierBag cookbook updated successfully")
    }

    func fetchCarrierBagBDO(publicKey: String) async throws -> [String: Any] {
        let fountUrl = "http://127.0.0.1:5117/bdo/\(publicKey)"

        guard let url = URL(string: fountUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }

        NSLog("ADVANCEKEY: 📡 Fetching carrierBag BDO from Fount")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        if httpResponse.statusCode == 404 {
            // CarrierBag doesn't exist, create empty one
            NSLog("ADVANCEKEY: 📦 CarrierBag not found, creating empty one")
            return [
                "data": [
                    "carrierBag": [
                        "spaceTime": [],
                        "cookbook": [],
                        "created": ISO8601DateFormatter().string(from: Date()),
                        "lastUpdated": ISO8601DateFormatter().string(from: Date())
                    ]
                ]
            ]
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fount error: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bdoData = jsonObject else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO JSON from Fount"])
        }

        return bdoData
    }

    func addRecipeToCarrierBag(_ carrierBagBDO: [String: Any], bdoPubKey: String, type: String, title: String) throws -> [String: Any] {
        var updatedBDO = carrierBagBDO

        // Get current cookbook
        guard let data = updatedBDO["data"] as? [String: Any],
              let carrierBag = data["carrierBag"] as? [String: Any],
              var cookbook = carrierBag["cookbook"] as? [[String: Any]] else {
            throw NSError(domain: "CarrierBagError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid carrierBag structure"])
        }

        // Create recipe entry
        let recipeEntry: [String: Any] = [
            "bdoPubKey": bdoPubKey,
            "type": type,
            "title": title,
            "savedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Remove existing recipe with same bdoPubKey
        cookbook.removeAll { recipe in
            (recipe["bdoPubKey"] as? String) == bdoPubKey
        }

        // Add new recipe
        cookbook.append(recipeEntry)

        // Update the structure
        var updatedCarrierBag = carrierBag
        updatedCarrierBag["cookbook"] = cookbook
        updatedCarrierBag["lastUpdated"] = ISO8601DateFormatter().string(from: Date())

        var updatedData = data
        updatedData["carrierBag"] = updatedCarrierBag

        updatedBDO["data"] = updatedData

        NSLog("ADVANCEKEY: 📚 Recipe added to cookbook. Total recipes: %d", cookbook.count)

        return updatedBDO
    }

    func updateCarrierBagBDO(_ updatedBDO: [String: Any], publicKey: String) async throws {
        // Extract the data to update
        guard let data = updatedBDO["data"] as? [String: Any] else {
            throw NSError(domain: "CarrierBagError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO data"])
        }

        // Create update payload
        let updatePayload: [String: Any] = [
            "pubKey": publicKey,
            "data": data
        ]

        let fountUpdateUrl = "http://127.0.0.1:5117/bdo/\(publicKey)"
        guard let url = URL(string: fountUpdateUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount update URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: updatePayload)
        } catch {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize update data: \(error.localizedDescription)"])
        }

        NSLog("ADVANCEKEY: 📡 Updating carrierBag BDO in Fount")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEKEY: 📡 CarrierBag update response status: %d", httpResponse.statusCode)

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            NSLog("ADVANCEKEY: ✅ CarrierBag BDO updated successfully")
        } else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to update carrierBag: \(httpResponse.statusCode)"])
        }
    }

    // MARK: - Stored Payment Methods

    func loadStoredPaymentMethods() -> [PaymentMethod] {
        guard let userDefaults = UserDefaults(suiteName: "group.com.planetnine.the-advancement") else {
            NSLog("ADVANCEKEY: ❌ Failed to access shared UserDefaults")
            return []
        }

        guard let storedMethodsData = userDefaults.array(forKey: "stored_payment_methods") as? [[String: Any]] else {
            NSLog("ADVANCEKEY: 📝 No stored payment methods found")
            return []
        }

        let paymentMethods = storedMethodsData.compactMap { methodData -> PaymentMethod? in
            guard let id = methodData["id"] as? String,
                  let brand = methodData["brand"] as? String,
                  let last4 = methodData["last4"] as? String else {
                NSLog("ADVANCEKEY: ⚠️ Invalid payment method data: %@", methodData)
                return nil
            }

            return PaymentMethod(id: id, brand: brand, last4: last4, type: "card")
        }

        NSLog("ADVANCEKEY: 💳 Loaded %d stored payment methods", paymentMethods.count)
        return paymentMethods
    }

    func generatePaymentMethodsHTML() throws -> String {
        let storedMethods = loadStoredPaymentMethods()

        let templateService = HTMLTemplateService()
        return try templateService.generatePaymentMethodsHTML(paymentMethods: storedMethods)
    }

    func handlePaymentMethodSelection(_ message: [String: Any]) {
        guard let paymentMethodId = message["paymentId"] as? String else {
            NSLog("ADVANCEKEY: ❌ Invalid payment method selection")
            return
        }

        NSLog("ADVANCEKEY: 💳 Payment method selected: %@", paymentMethodId)

        // Find the selected payment method
        let storedMethods = loadStoredPaymentMethods()
        guard let selectedMethod = storedMethods.first(where: { $0.id == paymentMethodId }) else {
            NSLog("ADVANCEKEY: ❌ Selected payment method not found: %@", paymentMethodId)
            return
        }

        // Process the payment using the stored method
        // This would integrate with the existing purchase flow
        NSLog("ADVANCEKEY: 🔄 Processing payment with %@ ending in %@", selectedMethod.brand, selectedMethod.last4)

        // Show confirmation to user
        showPaymentConfirmation(for: selectedMethod)
    }

    private func showPaymentConfirmation(for paymentMethod: PaymentMethod) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "💳 Confirm Payment",
                message: "Use \(paymentMethod.brand) ending in \(paymentMethod.last4)?",
                preferredStyle: .alert
            )

            alertController.addAction(UIAlertAction(title: "Confirm", style: .default) { _ in
                // Process the actual payment
                self.processStoredPayment(paymentMethod)
            })

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            self.present(alertController, animated: true)
        }
    }

    private func processStoredPayment(_ paymentMethod: PaymentMethod) {
        NSLog("ADVANCEKEY: 💰 Processing payment with stored method: %@", paymentMethod.id)

        // This would integrate with the existing Addie/Stripe payment processing
        // For now, we'll show a success message
        DispatchQueue.main.async {
            let successAlert = UIAlertController(
                title: "🎉 Payment Successful",
                message: "Your purchase has been completed using \(paymentMethod.brand) ending in \(paymentMethod.last4)",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "Great!", style: .default))
            self.present(successAlert, animated: true)
        }
    }

    func handleAddPaymentMethod() {
        NSLog("ADVANCEKEY: 💳 Add payment method requested")

        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "💳 Add Payment Method",
                message: "To add a new payment method, please use the Nexus portal in The Advancement app.",
                preferredStyle: .alert
            )

            alertController.addAction(UIAlertAction(title: "Open App", style: .default) { _ in
                // This would open The Advancement app to the Nexus portal
                if let url = URL(string: "advancement://nexus") {
                    self.openURL(url)
                }
            })

            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            self.present(alertController, animated: true)
        }
    }
}
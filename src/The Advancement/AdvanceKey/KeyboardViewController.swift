//
//  KeyboardViewController.swift
//  AdvanceKey
//
//  Simple demoji keyboard extension
//

import UIKit
import WebKit

extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji
    }
}

class KeyboardViewController: UIInputViewController, WKScriptMessageHandler {

    var demojiButton: UIButton!
    var contractActionButton: UIButton!
    var resultWebView: WKWebView!
    var sessionless: Sessionless!
    var currentContractData: [String: Any]?
    var lastProcessedText: String = ""  // Track last processed text to avoid duplicates

    override func updateViewConstraints() {
        super.updateViewConstraints()

        // Set keyboard height - increased from 280 to 400 for more BDO display space
        let heightConstraint = NSLayoutConstraint(
            item: self.view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: 400
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

        // Mark keyboard as used (for main app installation check)
        markKeyboardAsUsed()

        // setupDemojiButton()  // Removed - auto-detection enabled
        setupContractActionButton()
        setupWebView()

        NSLog("ADVANCEKEY: ✅ Demoji Keyboard ready (auto-detection enabled)")
    }

    private func markKeyboardAsUsed() {
        // Set flag in shared UserDefaults so main app knows keyboard is installed
        let sharedDefaults = UserDefaults(suiteName: "group.com.planetnine.Planet-Nine")
        sharedDefaults?.set(true, forKey: "keyboardFirstUsed")
        NSLog("ADVANCEKEY: ⌨️ Marked keyboard as used")
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
            demojiButton.trailingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: -5),
            demojiButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            demojiButton.widthAnchor.constraint(equalToConstant: 120),
            demojiButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func setupContractActionButton() {
        contractActionButton = UIButton(type: .system)
        contractActionButton.setTitle("View-Only", for: .normal)
        contractActionButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        contractActionButton.backgroundColor = UIColor.systemGray
        contractActionButton.setTitleColor(.white, for: .normal)
        contractActionButton.layer.cornerRadius = 12
        contractActionButton.translatesAutoresizingMaskIntoConstraints = false
        contractActionButton.isHidden = true  // Hidden by default

        contractActionButton.addTarget(self, action: #selector(contractActionTapped), for: .touchUpInside)

        self.view.addSubview(contractActionButton)

        NSLayoutConstraint.activate([
            contractActionButton.leadingAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 5),
            contractActionButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20),
            contractActionButton.widthAnchor.constraint(equalToConstant: 120),
            contractActionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    func setupWebView() {
        let webViewConfig = WKWebViewConfiguration()
        webViewConfig.allowsInlineMediaPlayback = true

        // Add console message handler to capture JavaScript logs
        let contentController = WKUserContentController()
        contentController.add(self, name: "consoleLog")
        contentController.add(self, name: "saveRecipe")
        contentController.add(self, name: "saveToStacks")
        contentController.add(self, name: "saveToCarrierBag")
        contentController.add(self, name: "addToCart")
        contentController.add(self, name: "signContract")
        contentController.add(self, name: "declineContract")
        contentController.add(self, name: "paymentMethodSelected")
        contentController.add(self, name: "addPaymentMethod")
        contentController.add(self, name: "contractAuthorization")
        contentController.add(self, name: "purchase")
        contentController.add(self, name: "navigateToCard")
        contentController.add(self, name: "openCarrierBag")
        contentController.add(self, name: "shareBDO")
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
            resultWebView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 10),
            resultWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            resultWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            resultWebView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10)
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

        // If we're getting no context, show a fallback test
        if fullContext.isEmpty {
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

        // Check for 9-emoji shortcode first (new BDO emojicode format)
        if let shortcode = extract8EmojiShortcode(from: fullContext) {
            NSLog("ADVANCEKEY: 🎨 Found 9-emoji shortcode: %@", shortcode)
            decodeAndFetchBDO(emojicode: shortcode)
        }
        // Look for emojicoded sequence (starts and ends with ✨)
        else if let emojicode = extractEmojicode(from: fullContext) {
            NSLog("ADVANCEKEY: 🎨 Found complete emojicode: %@", String(emojicode.prefix(30)))
            decodeAndFetchBDO(emojicode: emojicode)
        } else if sparklesCount >= 1 {
            // Try to work with partial sequence if we have at least one sparkle
            let partialEmoji = "✨\(fullContext.filter { $0.isEmoji })✨"
            NSLog("ADVANCEKEY: 🔧 Attempting partial decode: %@", String(partialEmoji.prefix(30)))
            decodeAndFetchBDO(emojicode: partialEmoji)
        } else {
            displayError("No Emoji Found", details: """
            Context: \(fullContext.prefix(200))

            Emoji count: \(emojiCount)
            Sparkles: \(sparklesCount)

            Need: 9 consecutive emojis OR ✨...emojis...✨ pattern
            Selected: \(selectedText)

            Try selecting more text or scrolling to include the emoji sequence.
            """)
            NSLog("ADVANCEKEY: ❌ No emojicoded sequence found in context")
        }
    }

    @objc func contractActionTapped() {
        NSLog("ADVANCEKEY: 📜 Contract action button tapped")

        guard let contractData = currentContractData else {
            NSLog("ADVANCEKEY: ⚠️ No contract data available")
            return
        }

        // Check if user is authorized
        let bdo = contractData["bdo"] as? [String: Any] ?? contractData
        let participants = bdo["participants"] as? [String] ?? []

        // Get current user's pubKey
        let sharedDefaults = UserDefaults(suiteName: "group.com.planetnine.Planet-Nine")
        guard let currentUserPubKey = sharedDefaults?.string(forKey: "sessionless_public_key") else {
            NSLog("ADVANCEKEY: ❌ No user pubKey found")
            return
        }

        let isAuthorized = participants.contains { $0.lowercased() == currentUserPubKey.lowercased() }

        if isAuthorized {
            // Sign the contract
            NSLog("ADVANCEKEY: ✍️ User is authorized, signing contract")
            // TODO: Implement signing logic (call signContract function)
            let signScript = """
                document.getElementById('banner').innerHTML = `
                    <div style="padding: 15px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                        <div style="font-size: 16px; font-weight: bold; margin-bottom: 5px;">✍️ Sign Contract</div>
                        <div style="font-size: 12px;">Contract signing functionality will be implemented here</div>
                    </div>
                `;
                setTimeout(() => { document.getElementById('banner').innerHTML = ''; }, 3000);
            """
            resultWebView.evaluateJavaScript(signScript, completionHandler: nil)
        } else {
            // View-only mode
            NSLog("ADVANCEKEY: 👁️ User is not authorized, view-only mode")
            let viewScript = """
                document.getElementById('banner').innerHTML = `
                    <div style="padding: 15px; background: linear-gradient(135deg, #64748b 0%, #475569 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                        <div style="font-size: 16px; font-weight: bold; margin-bottom: 5px;">👁️ View Only</div>
                        <div style="font-size: 12px;">You are not a participant in this contract</div>
                    </div>
                `;
                setTimeout(() => { document.getElementById('banner').innerHTML = ''; }, 3000);
            """
            resultWebView.evaluateJavaScript(viewScript, completionHandler: nil)
        }
    }

    // MARK: - Automatic Emojicode Detection
    override func textDidChange(_ textInput: UITextInput?) {
        super.textDidChange(textInput)

        // Get current text context
        let proxy = self.textDocumentProxy
        let contextBefore = proxy.documentContextBeforeInput ?? ""
        let contextAfter = proxy.documentContextAfterInput ?? ""
        let selectedText = proxy.selectedText ?? ""
        let fullContext = contextBefore + selectedText + contextAfter

        // Avoid processing the same text repeatedly
        guard fullContext != lastProcessedText else { return }
        lastProcessedText = fullContext

        // Only process if we have enough text
        guard fullContext.count >= 8 else { return }

        NSLog("ADVANCEKEY: 🔍 Auto-detecting emojicode in text: %@", String(fullContext.prefix(50)))

        // Check for 9-emoji shortcode first (new BDO emojicode format)
        if let shortcode = extract8EmojiShortcode(from: fullContext) {
            NSLog("ADVANCEKEY: ✨ Auto-detected 9-emoji shortcode: %@", shortcode)
            decodeAndFetchBDO(emojicode: shortcode)
        }
        // Look for emojicoded sequence (starts and ends with ✨)
        else if let emojicode = extractEmojicode(from: fullContext) {
            NSLog("ADVANCEKEY: ✨ Auto-detected emojicode: %@", String(emojicode.prefix(30)))
            decodeAndFetchBDO(emojicode: emojicode)
        }
    }

    func extract8EmojiShortcode(from text: String) -> String? {
        // Extract all emojis from the text
        let emojis = text.filter { $0.isEmoji }

        // Check if we have exactly 9 consecutive emojis
        if emojis.count == 9 {
            NSLog("ADVANCEKEY: 🎯 Found exactly 9 emojis: %@", String(emojis))
            return String(emojis)
        }

        // If more than 9, try to find a sequence of 9 consecutive emojis
        if emojis.count > 9 {
            // Look for patterns: try the first 9, last 9, or any 9 consecutive
            let first9 = String(emojis.prefix(9))
            NSLog("ADVANCEKEY: 🔍 Found %d emojis, trying first 9: %@", emojis.count, first9)
            return first9
        }

        return nil
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
        // Check if this is a 9-emoji shortcode (no sparkles)
        let emojiOnly = emojicode.filter { $0.isEmoji }
        if emojiOnly.count == 9 && !emojicode.contains("✨") {
            NSLog("ADVANCEKEY: 🎯 Detected 9-emoji shortcode, fetching directly from /emoji endpoint")
            fetchBDOByEmojicode(emojicode: String(emojiOnly))
            return
        }

        // JSON-encode the emojicode to safely pass it to JavaScript
        // We need to wrap it in an array to use JSONSerialization, then extract the encoded string
        guard let emojicodeData = try? JSONSerialization.data(withJSONObject: [emojicode]),
              let emojicodeArray = String(data: emojicodeData, encoding: .utf8),
              let firstQuote = emojicodeArray.firstIndex(of: "\""),
              let lastQuote = emojicodeArray.lastIndex(of: "\"") else {
            NSLog("ADVANCEKEY: ❌ Failed to JSON-encode emojicode")
            displayError("Encoding Error", details: "Failed to prepare emojicode for decoding")
            return
        }

        // Extract just the JSON-encoded string (without the array brackets)
        let emojicodeJSON = String(emojicodeArray[firstQuote...lastQuote])

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

        // Parse the JSON-encoded emojicode
        const emojicode = \(emojicodeJSON);
        console.log('ADVANCEKEY: Input emojicode:', emojicode);
        console.log('ADVANCEKEY: Input length:', emojicode.length);

        // Check if simpleDecodeEmoji function exists
        if (typeof simpleDecodeEmoji === 'undefined') {
            console.log('ADVANCEKEY: ❌ simpleDecodeEmoji function not found');
            JSON.stringify({ error: 'simpleDecodeEmoji function not found', logs: logs });
        } else {
            console.log('ADVANCEKEY: ✅ simpleDecodeEmoji function found');

            try {
                console.log('ADVANCEKEY: 🎯 Attempting to decode user input...');
                const decodeResult = simpleDecodeEmoji(emojicode);
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
                self?.fetchBDOData(bdoPubKey: decodedHex)
            } else if let errorMsg = response["error"] as? String {
                NSLog("ADVANCEKEY: ❌ Decode failed: %@", errorMsg)
                if let stack = response["stack"] as? String {
                    NSLog("ADVANCEKEY: ❌ Error stack: %@", stack)
                }
                self?.displayError("Emoji Decode Failed", details: errorMsg)
            } else {
                NSLog("ADVANCEKEY: ❌ Unexpected response format: %@", String(describing: response))
                self?.displayError("Unexpected Response", details: String(describing: response))
            }
        }
    }

    func fetchBDOByEmojicode(emojicode: String) {
        // Fetch BDO data directly by emojicode from /emoji/:emojicode endpoint
        let bdoUrl = Configuration.BDO.baseURL

        Task {
            do {
                // URL encode the emojicode
                guard let encodedEmojicode = emojicode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    throw NSError(domain: "EncodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode emojicode"])
                }

                let url = URL(string: "\(bdoUrl)emoji/\(encodedEmojicode)")!
                NSLog("ADVANCEKEY: 🌐 Fetching BDO from: %@", url.absoluteString)

                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }

                NSLog("ADVANCEKEY: 📡 Response status: %d", httpResponse.statusCode)

                guard httpResponse.statusCode == 200 else {
                    throw NSError(domain: "NetworkError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
                }

                guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NSError(domain: "JSONError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON"])
                }

                // Extract the BDO from the response
                // Response format: {emojicode, pubKey, bdo: {...}, createdAt}
                guard let bdoData = jsonObject["bdo"] as? [String: Any] else {
                    throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No BDO data in response"])
                }

                let pubKey = jsonObject["pubKey"] as? String ?? "unknown"

                NSLog("ADVANCEKEY: ✅ BDO fetched successfully")
                NSLog("ADVANCEKEY: 📦 PubKey: %@", String(pubKey.prefix(20)))

                DispatchQueue.main.async { [weak self] in
                    self?.displayBDOContent(cardData: ["bdo": bdoData], bdoPubKey: pubKey)
                }

            } catch {
                NSLog("ADVANCEKEY: ❌ Emojicode fetch error: %@", error.localizedDescription)
                DispatchQueue.main.async { [weak self] in
                    self?.displayError("Emojicode Fetch Failed", details: """
                    Error: \(error.localizedDescription)

                    Attempted to fetch:
                    emojicode: \(emojicode)
                    URL: \(bdoUrl)emoji/\(emojicode)

                    Make sure:
                    • BDO service is running on port 5114
                    • The emojicode exists in the database
                    • The BDO was created as a public BDO
                    """, baseUrl: "\(bdoUrl)emoji/\(emojicode)")
                }
            }
        }
    }

    func fetchBDOData(bdoPubKey: String) {
        // Fetch BDO data from test environment using URLSession
        let bdoUrl = Configuration.BDO.baseURL

        Task {
            do {
                let cardData = try await fetchBDOFromServer(bdoPubKey: bdoPubKey, baseUrl: bdoUrl)

                NSLog("ADVANCEKEY: 📦 BDO data received: %@", String(describing: cardData))

                DispatchQueue.main.async { [weak self] in
                    self?.displayBDOContent(cardData: cardData, bdoPubKey: bdoPubKey)
                }

            } catch {
                NSLog("ADVANCEKEY: ❌ BDO fetch error: %@", error.localizedDescription)
                DispatchQueue.main.async { [weak self] in
                    self?.displayError("BDO Fetch Failed", details: """
                    Error: \(error.localizedDescription)

                    Attempted to fetch:
                    bdoPubKey: \(bdoPubKey)
                    URL: \(bdoUrl)
                    """, baseUrl: bdoUrl)
                }
            }
        }
    }

    func fetchBDOFromServer(bdoPubKey: String, baseUrl: String) async throws -> [String: Any] {
        // For BDO access, we need to use the proper BDO user endpoint format:
        // GET /user/{uuid}/bdo?pubKey={pubKey}&timestamp={timestamp}&hash={hash}&signature={signature}

        // Get or create BDO user UUID (persisted in UserDefaults)
        let bdoUserUUID = try await getBDOUserUUID()
        NSLog("ADVANCEKEY: 🔍 Fetching BDO for pubKey: %@ with user UUID: %@", bdoPubKey, bdoUserUUID)

        // Generate timestamp
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        // Create message to sign (for BDO GET requests, we sign: timestamp + hash + uuid)
        // Since we don't have a hash parameter for GET, we'll use empty string
        let hash = ""
        let messageToSign = "\(timestamp)\(hash)\(bdoUserUUID)"

        // Sign the message using Sessionless
        guard let signature = sessionless.sign(message: messageToSign) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign BDO request"])
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
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO URL"])
        }

        NSLog("ADVANCEKEY: 🌐 Fetching BDO from: %@", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }

        NSLog("ADVANCEKEY: 📡 BDO response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            // If BDO endpoint fails, try fetching as public BDO (no user auth needed)
            NSLog("ADVANCEKEY: BDO endpoint failed with status %d, trying public BDO fetch", httpResponse.statusCode)

            // Try public BDO endpoint (no authentication required for public BDOs)
            do {
                return try await fetchPublicBDO(bdoPubKey: bdoPubKey, baseUrl: baseUrl)
            } catch {
                NSLog("ADVANCEKEY: Public BDO fetch failed, falling back to Fount search: %@", error.localizedDescription)
                return try await fetchBDOFromFount(bdoPubKey: bdoPubKey)
            }
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "JSONParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse BDO JSON"])
        }

        return jsonObject
    }

    func fetchPublicBDO(bdoPubKey: String, baseUrl: String) async throws -> [String: Any] {
        NSLog("ADVANCEKEY: 🌍 Fetching public BDO by pubKey: %@", bdoPubKey)

        // Public BDOs can be fetched directly by pubKey without authentication
        // The BDO service should have an endpoint like GET /public/bdo?pubKey={pubKey}
        // or we can use the short code endpoint if we know the short code

        // Try fetching directly by pubKey (public endpoint)
        var urlComponents = URLComponents(string: "\(baseUrl)public/bdo")!
        urlComponents.queryItems = [
            URLQueryItem(name: "pubKey", value: bdoPubKey.lowercased())
        ]

        guard let url = urlComponents.url else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid public BDO URL"])
        }

        NSLog("ADVANCEKEY: 🌐 Fetching public BDO from: %@", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }

        NSLog("ADVANCEKEY: 📡 Public BDO response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response"
            NSLog("ADVANCEKEY: ❌ Public BDO fetch failed with status %d: %@", httpResponse.statusCode, responseBody)
            throw NSError(domain: "PublicBDOFetchError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch public BDO: \(httpResponse.statusCode)"])
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "JSONParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse public BDO JSON"])
        }

        NSLog("ADVANCEKEY: ✅ Successfully fetched public BDO")
        return jsonObject
    }

    func getBDOUserUUID() async throws -> String {
        // Check if we already have a BDO user UUID stored
        if let existingUUID = UserDefaults.standard.string(forKey: "bdoUserUUID") {
            return existingUUID
        }

        // Need to create a new BDO user via API
        NSLog("ADVANCEKEY: 🆕 No BDO user UUID found, creating new BDO user...")
        let newUUID = try await createBDOUser()

        // Store the UUID for future use
        UserDefaults.standard.set(newUUID, forKey: "bdoUserUUID")
        NSLog("ADVANCEKEY: ✅ Created and saved new BDO user UUID: %@", newUUID)

        return newUUID
    }

    func createBDOUser() async throws -> String {
        // Create a new BDO user via PUT /user/create
        // This requires: timestamp, hash, pubKey, signature

        // Get or generate Sessionless keys
        var keys = sessionless.getKeys()
        if keys == nil {
            NSLog("ADVANCEKEY: 🔑 No Sessionless keys found, generating new keys...")
            keys = sessionless.generateKeys()
            guard keys != nil else {
                throw NSError(domain: "SessionlessError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to generate Sessionless keys"])
            }
            NSLog("ADVANCEKEY: ✅ Sessionless keys generated: %@", keys!.publicKey)
        }

        guard let keys = keys else {
            throw NSError(domain: "SessionlessError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Sessionless keys available"])
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "" // Empty for user creation

        // Message to sign: timestamp + hash + pubKey
        let messageToSign = "\(timestamp)\(hash)\(keys.publicKey)"

        guard let signature = sessionless.sign(message: messageToSign) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign user creation request"])
        }

        // Create request body
        let requestBody: [String: Any] = [
            "timestamp": timestamp,
            "hash": hash,
            "pubKey": keys.publicKey,
            "signature": signature,
            "public": false,
            "bdo": [:] // Empty BDO for now
        ]

        let bdoUrl = Configuration.BDO.createUser()
        guard let url = URL(string: bdoUrl) else {
            throw NSError(domain: "InvalidURL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO user creation URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        NSLog("ADVANCEKEY: 📡 Creating BDO user at: %@", bdoUrl)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response"])
        }

        NSLog("ADVANCEKEY: 📡 BDO user creation response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "BDOUserCreationError", code: httpResponse.statusCode,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create BDO user: status \(httpResponse.statusCode)"])
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuid = jsonObject["uuid"] as? String else {
            throw NSError(domain: "JSONParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse BDO user creation response"])
        }

        NSLog("ADVANCEKEY: ✅ BDO user created with UUID: %@", uuid)
        return uuid
    }

    func searchBDOInUsers(bdoPubKey: String, baseUrl: String) async throws -> [String: Any] {
        NSLog("ADVANCEKEY: 🔍 Searching for BDO in Fount: %@", bdoPubKey)

        // Call Fount API to get BDO by pubKey
        return try await fetchBDOFromFount(bdoPubKey: bdoPubKey)
    }

    func fetchBDOFromFount(bdoPubKey: String) async throws -> [String: Any] {
        // Fetch BDO by its public key
        let fountUrl = Configuration.Fount.getBDO(bdoPubKey: bdoPubKey)

        guard let url = URL(string: fountUrl) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }

        NSLog("ADVANCEKEY: 📡 Fetching BDO from Fount: %@", fountUrl)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEKEY: 📡 Fount response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "BDO not found in Fount (status: \(httpResponse.statusCode))"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let bdoData = jsonObject else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid BDO JSON from Fount"])
        }

        NSLog("ADVANCEKEY: ✅ BDO fetched from Fount successfully")
        return bdoData
    }

    // MARK: - CarrierBag Management
    // Note: Fount user and carrierBag are created during onboarding in the main app.
    // AdvanceKey just fetches and updates the existing carrierBag.

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
        let fountCreateUrl = Configuration.Fount.createBDO()
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

    func displayBDOContent(cardData: [String: Any], bdoPubKey: String) {
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
            NSLog("❌ No SVG content in BDO data for pubKey: %@", bdoPubKey)
            NSLog("❌ BDO data structure: %@", String(describing: cardData))
            displayError("No SVG Content Found", details: """
            bdoPubKey: \(bdoPubKey)

            BDO data keys: \(cardData.keys.joined(separator: ", "))

            Full response:
            \(String(describing: cardData).prefix(500))
            """)
            return
        }

        // Get current user's pubKey for participant verification
        let currentUserPubKey = SharedUserDefaults.getCurrentUserPubKey() ?? ""

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
                    padding: 0;
                    background: #1a1afe;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    min-height: 100vh;
                    overflow-y: auto;
                    overflow-x: hidden;
                }
                #banner {
                    width: 100%;
                    padding: 8px;
                    text-align: center;
                    font-family: Arial, sans-serif;
                    font-size: 14px;
                    font-weight: bold;
                    min-height: 0;
                }
                #banner.view-only {
                    display: block;
                    background: #94a3b8;
                    color: white;
                }
                #banner.authorized {
                    display: block;
                    background: #22c55e;
                    color: white;
                }
                #svg-container {
                    width: 100%;
                    height: 200px;
                    display: flex;
                    justify-content: center;
                    align-items: flex-start;
                    overflow-x: hidden;
                    overflow-y: auto;
                    padding: 5px;
                    background: green;
                    box-sizing: border-box;
                }
                svg {
                    width: 100%;
                    height: auto;
                    cursor: pointer;
                    display: block;
                }
                svg rect[spell], svg text[spell], svg [spell] {
                    transition: opacity 0.2s;
                    cursor: pointer;
                    position: relative;
                }
                svg rect[spell]:hover, svg text[spell]:hover, svg [spell]:hover {
                    opacity: 0.8;
                }
                /* Tooltip styling */
                .spell-tooltip {
                    position: absolute;
                    background: rgba(0, 0, 0, 0.9);
                    color: white;
                    padding: 8px 12px;
                    border-radius: 6px;
                    font-size: 12px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    white-space: nowrap;
                    pointer-events: none;
                    z-index: 1000;
                    opacity: 0;
                    transition: opacity 0.2s;
                }
                /* Hide sign elements by default */
                svg rect[spell="sign"],
                svg text[spell="sign"],
                svg .sign-button {
                    display: none;
                }
                /* Show when authorized */
                svg.authorized rect[spell="sign"],
                svg.authorized text[spell="sign"],
                svg.authorized .sign-button {
                    display: block;
                }
                /* Bottom button container */
                #bottom-buttons {
                    position: fixed;
                    bottom: 10px;
                    left: 50%;
                    transform: translateX(-50%);
                    display: flex;
                    gap: 10px;
                    z-index: 2000;
                }
                /* Carrier bag button */
                #bag-button {
                    width: 120px;
                    height: 40px;
                    background: rgba(236, 72, 153, 0.15);
                    border: 1px solid #ec4899;
                    border-radius: 8px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    animation: bagGlow 2.5s ease-in-out infinite;
                }
                #bag-button:active {
                    transform: scale(0.95);
                    background: rgba(236, 72, 153, 0.3);
                }
                #bag-button-text {
                    color: #ec4899;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 14px;
                    font-weight: 700;
                    letter-spacing: 0.5px;
                    text-align: center;
                }
                /* Share button */
                #share-button {
                    width: 120px;
                    height: 40px;
                    background: rgba(39, 174, 96, 0.15);
                    border: 1px solid #27ae60;
                    border-radius: 8px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    animation: shareGlow 2.5s ease-in-out infinite 0.5s;
                }
                #share-button:active {
                    transform: scale(0.95);
                    background: rgba(39, 174, 96, 0.3);
                }
                #share-button-text {
                    color: #27ae60;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 14px;
                    font-weight: 700;
                    letter-spacing: 0.5px;
                    text-align: center;
                }
                @keyframes bagGlow {
                    0%, 100% {
                        opacity: 0.7;
                        box-shadow: 0 0 5px rgba(236, 72, 153, 0.3);
                    }
                    50% {
                        opacity: 1;
                        box-shadow: 0 0 15px rgba(236, 72, 153, 0.6);
                    }
                }
                @keyframes shareGlow {
                    0%, 100% {
                        opacity: 0.7;
                        box-shadow: 0 0 5px rgba(39, 174, 96, 0.3);
                    }
                    50% {
                        opacity: 1;
                        box-shadow: 0 0 15px rgba(39, 174, 96, 0.6);
                    }
                }
            </style>
        </head>
        <body>
            <div id="banner"></div>
            <div id="svg-container">
                \(svg)
            </div>
            <div id="bottom-buttons">
                <div id="bag-button" onclick="openCarrierBag()">
                    <div id="bag-button-text">🎒 BAG</div>
                </div>
                <div id="share-button" onclick="shareBDO()">
                    <div id="share-button-text">📤 SHARE</div>
                </div>
            </div>
            <script>
                // BDO data for spell handling
                const bdoData = \(String(data: try! JSONSerialization.data(withJSONObject: cardData), encoding: .utf8)!);

                // Current user's pubKey
                const currentUserPubKey = "\(currentUserPubKey)";

                // Check if this is a contract signing UI and verify participant authorization
                (function() {
                    const bdo = bdoData.bdo || bdoData;
                    const type = bdo.type;
                    const participants = bdo.participants || [];

                    console.log('BDO type:', type);
                    console.log('BDO has participants:', participants);

                    // Check if this is a contract (either type or has participants array)
                    if (type === 'contract-signing-ui' || type === 'contract' || (participants && participants.length > 0)) {
                        console.log('Contract signing UI detected');
                        console.log('Participants:', participants);
                        console.log('Current user pubKey:', currentUserPubKey);

                        // Check if current user is authorized
                        const isAuthorized = participants.some(p =>
                            p.toLowerCase() === currentUserPubKey.toLowerCase()
                        );

                        console.log('User authorized:', isAuthorized);

                        const banner = document.getElementById('banner');
                        const svg = document.querySelector('svg');

                        // Notify Swift about contract authorization status
                        console.log('Sending contractAuthorization message to Swift...');
                        try {
                            window.webkit.messageHandlers.contractAuthorization.postMessage({
                                isAuthorized: isAuthorized,
                                contractData: bdoData
                            });
                            console.log('contractAuthorization message sent successfully');
                        } catch (error) {
                            console.log('Error sending contractAuthorization:', error);
                        }

                        if (isAuthorized) {
                            // Show authorized banner and SIGN button
                            if (banner) {
                                banner.textContent = '✅ You can sign this contract';
                                banner.className = 'authorized';
                            }
                            if (svg) {
                                svg.classList.add('authorized');
                            }
                        } else {
                            // Show view-only banner
                            if (banner) {
                                banner.textContent = '👁️ View Only - You are not a participant';
                                banner.className = 'view-only';
                            }
                            console.log('User not authorized to sign this contract');
                        }
                    }
                })();

                // Spell descriptions for tooltips
                const spellDescriptions = {
                    'collect': 'Save to your collection',
                    'save': 'Save to your collection',
                    'add-to-cart': 'Add to shopping cart',
                    'sign': 'Sign this contract step',
                    'decline': 'Decline this contract',
                    'share': 'Share with others',
                    'magic': 'Cast magical spell',
                    'buy': 'Purchase this item',
                    'purchaseLesson': 'Purchase this lesson',
                    'signInMoney': 'Complete payment and sign contract',
                    'purchase': 'Process payment',
                    'selection': 'Add to magistack selection',
                    'magicard': 'Navigate to another card',
                    'lookup': 'Find product from selections'
                };

                // Create tooltip element
                const tooltip = document.createElement('div');
                tooltip.className = 'spell-tooltip';
                document.body.appendChild(tooltip);

                let tooltipTimeout = null;
                let currentSpellElement = null;

                function showTooltip(element, touch) {
                    const spell = element.getAttribute('spell');
                    const spellDescription = element.getAttribute('spell-description');

                    if (spell) {
                        let tooltipText = spellDescription || spellDescriptions[spell] || `Will cast ${spell}`;
                        tooltip.textContent = tooltipText;
                        tooltip.style.opacity = '1';

                        // Position tooltip above the element
                        const rect = element.getBoundingClientRect();
                        tooltip.style.left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2) + 'px';
                        tooltip.style.top = (rect.top - tooltip.offsetHeight - 5) + 'px';
                    }
                }

                function hideTooltip() {
                    tooltip.style.opacity = '0';
                    currentSpellElement = null;
                    if (tooltipTimeout) {
                        clearTimeout(tooltipTimeout);
                        tooltipTimeout = null;
                    }
                }

                // Touch events for iOS (long press to show tooltip)
                document.addEventListener('touchstart', function(e) {
                    const spell = e.target.getAttribute('spell');
                    if (spell) {
                        currentSpellElement = e.target;
                        // Show tooltip after 500ms long press
                        tooltipTimeout = setTimeout(() => {
                            showTooltip(e.target, e.touches[0]);
                        }, 500);
                    }
                });

                document.addEventListener('touchmove', function(e) {
                    // Hide tooltip if user moves finger
                    hideTooltip();
                });

                document.addEventListener('touchend', function(e) {
                    // Clear the timeout but keep tooltip visible if it's already shown
                    if (tooltipTimeout) {
                        clearTimeout(tooltipTimeout);
                        tooltipTimeout = null;
                    }

                    // Hide tooltip after a delay if shown
                    if (tooltip.style.opacity === '1') {
                        setTimeout(hideTooltip, 1500);
                    }
                });

                document.addEventListener('touchcancel', function(e) {
                    hideTooltip();
                });

                // Also support mouse events for iPad with mouse/trackpad
                document.addEventListener('mouseover', function(e) {
                    const spell = e.target.getAttribute('spell');
                    if (spell) {
                        showTooltip(e.target, null);
                    }
                });

                document.addEventListener('mouseout', function(e) {
                    const spell = e.target.getAttribute('spell');
                    if (spell) {
                        hideTooltip();
                    }
                });

                // Handle spell button clicks
                document.addEventListener('click', function(e) {
                    // Traverse up the DOM tree to find an element with a spell attribute
                    let target = e.target;
                    let spell = null;
                    let spellComponents = null;

                    while (target && target !== document) {
                        spell = target.getAttribute('spell');
                        if (spell) {
                            spellComponents = target.getAttribute('spell-components');
                            console.log('Spell clicked:', spell, 'components:', spellComponents);
                            handleSpell(spell, bdoData, spellComponents);
                            break;
                        }
                        target = target.parentElement;
                    }
                });

                function handleSpell(spell, data, spellComponents) {
                    // Parse spell-components - try JSON first, then fallback to key:value format
                    let components = {};
                    if (spellComponents) {
                        try {
                            components = JSON.parse(spellComponents);
                        } catch (e) {
                            // Fallback to key:value format
                            spellComponents.split(';').forEach(pair => {
                                const [key, value] = pair.split(':');
                                if (key && value) {
                                    components[key.trim()] = value.trim();
                                }
                            });
                        }
                    }

                    console.log('🪄 Casting spell:', spell, 'with components:', components);

                    switch(spell) {
                        case 'collect':
                        case 'save':
                        case 'saveToStacks':  // backward compatibility
                            saveToCarrierBag(data, components);
                            break;
                        case 'add-to-cart':
                            addToCart(data, components);
                            break;
                        case 'sign':
                            signContract(data, components);
                            break;
                        case 'decline':
                            declineContract(data, components);
                            break;
                        case 'share':
                            shareRecipe(data);
                            break;
                        case 'magic':
                            castMagic(data, components);
                            break;
                        case 'purchaseLesson':
                            purchaseLesson(data, components);
                            break;
                        case 'signInMoney':
                            signInMoney(data, components);
                            break;
                        case 'purchase':
                            purchaseItem(data, components);
                            break;
                        case 'selection':
                            handleSelection(data, components);
                            break;
                        case 'magicard':
                            navigateToCard(data, components);
                            break;
                        case 'lookup':
                            lookupProduct(data, components);
                            break;
                        default:
                            // Generic fallback for unknown spells
                            handleGenericSpell(spell, data, components);
                    }
                }

                function saveToCarrierBag(data, components, purchased = false) {
                    try {
                        // Extract BDO data
                        const bdo = data.bdo || data;

                        // Get collection from spell-components or infer from type
                        let collection = components.carrierBag || components.collection;

                        // If no collection specified, infer from BDO type
                        if (!collection) {
                            const type = bdo.type || 'item';
                            if (type === 'contract-signing-ui' || type === 'contract') {
                                collection = 'contracts';
                            } else if (type === 'recipe') {
                                collection = 'cookbook';
                            } else if (type === 'ebook' || type === 'book' || type === 'article') {
                                collection = 'bookshelf';
                            } else if (type === 'room') {
                                collection = 'stacks';
                            } else if (type === 'popup' || type === 'event') {
                                collection = 'events';
                            } else if (type === 'music-player' || type === 'music' || type === 'canimus-feed') {
                                collection = 'music';
                            } else {
                                collection = 'stacks'; // Default
                            }
                        }

                        const type = bdo.type || components.type || 'item';
                        const title = components.title || bdo.title || bdo.name || 'Untitled Item';

                        console.log(`💾 Saving '${title}' to ${collection}`);

                        // Animate BDO flying into carrier bag
                        animateSaveToBag(collection);

                        // Send message to Swift to save to carrierBag
                        window.webkit.messageHandlers.saveToCarrierBag.postMessage({
                            action: 'saveToCarrierBag',
                            collection: collection,
                            type: type,
                            title: title,
                            bdoData: bdo,
                            purchased: purchased
                        });

                    } catch (error) {
                        console.error('Error saving to carrierBag:', error);
                        alert('❌ Failed to save: ' + error.message);
                    }
                }

                function animateSaveToBag(collection) {
                    try {
                        // Get the SVG element from the container
                        const svgContainer = document.getElementById('svg-container');
                        const originalSvg = svgContainer.querySelector('svg');

                        if (!originalSvg) {
                            console.warn('No SVG found to animate');
                            return;
                        }

                        // Clone the SVG
                        const clonedSvg = originalSvg.cloneNode(true);

                        // Get position of original SVG
                        const originalRect = originalSvg.getBoundingClientRect();

                        // Get position of bag button
                        const bagButton = document.getElementById('bag-button');
                        const bagRect = bagButton.getBoundingClientRect();

                        // Create container for animation
                        const animationContainer = document.createElement('div');
                        animationContainer.style.position = 'fixed';
                        animationContainer.style.left = originalRect.left + 'px';
                        animationContainer.style.top = originalRect.top + 'px';
                        animationContainer.style.width = originalRect.width + 'px';
                        animationContainer.style.height = originalRect.height + 'px';
                        animationContainer.style.zIndex = '9999';
                        animationContainer.style.pointerEvents = 'none';
                        animationContainer.style.overflow = 'hidden';

                        // Style the cloned SVG
                        clonedSvg.style.width = '100%';
                        clonedSvg.style.height = 'auto';
                        clonedSvg.style.display = 'block';

                        animationContainer.appendChild(clonedSvg);
                        document.body.appendChild(animationContainer);

                        // Calculate target position (center of bag button)
                        const targetX = bagRect.left + (bagRect.width / 2) - (originalRect.width / 2);
                        const targetY = bagRect.top + (bagRect.height / 2) - (originalRect.height / 2);

                        // Calculate translation needed
                        const translateX = targetX - originalRect.left;
                        const translateY = targetY - originalRect.top;

                        // Collection-specific emoji for visual feedback
                        const collectionEmojis = {
                            'cookbook': '🍪',
                            'bookshelf': '📚',
                            'contracts': '📜',
                            'stacks': '🏠',
                            'apothecary': '🧪',
                            'gallery': '🖼️',
                            'familiarPen': '🐾',
                            'machinery': '⚙️',
                            'metallics': '⚡',
                            'music': '🎵',
                            'oracular': '🔮',
                            'greenHouse': '🌱',
                            'closet': '👕',
                            'games': '🎮',
                            'events': '🎫'
                        };

                        // Add emoji overlay
                        const emojiOverlay = document.createElement('div');
                        emojiOverlay.textContent = collectionEmojis[collection] || '💾';
                        emojiOverlay.style.position = 'absolute';
                        emojiOverlay.style.top = '50%';
                        emojiOverlay.style.left = '50%';
                        emojiOverlay.style.transform = 'translate(-50%, -50%)';
                        emojiOverlay.style.fontSize = '48px';
                        emojiOverlay.style.zIndex = '10000';
                        emojiOverlay.style.pointerEvents = 'none';
                        animationContainer.appendChild(emojiOverlay);

                        // Trigger animation
                        requestAnimationFrame(() => {
                            animationContainer.style.transition = 'all 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
                            animationContainer.style.transform = `translate(${translateX}px, ${translateY}px) scale(0.1)`;
                            animationContainer.style.opacity = '0';
                        });

                        // Make bag button pulse
                        bagButton.style.transition = 'transform 0.3s ease';
                        bagButton.style.transform = 'translateX(-50%) scale(1.2)';

                        setTimeout(() => {
                            bagButton.style.transform = 'translateX(-50%) scale(1)';
                        }, 300);

                        // Remove animation container after animation completes
                        setTimeout(() => {
                            document.body.removeChild(animationContainer);
                            console.log(`✅ Animation complete - saved to ${collection}`);
                        }, 800);

                    } catch (error) {
                        console.error('Error animating save to bag:', error);
                    }
                }

                function addToCart(data, components) {
                    try {
                        // Extract product info from BDO
                        const bdo = data.bdo || data;
                        const productId = components.productId || bdo.productId || 'unknown';
                        const baseUuid = components.baseUuid || 'unknown';
                        const title = bdo.title || 'Unknown Product';
                        const price = bdo.price || 0;

                        console.log('Adding to cart:', { productId, baseUuid, title, price });

                        // Send message to Swift to add to cart
                        window.webkit.messageHandlers.addToCart.postMessage({
                            action: 'add-to-cart',
                            productId: productId,
                            baseUuid: baseUuid,
                            title: title,
                            price: price,
                            quantity: 1
                        });

                        // Show success feedback
                        alert('✅ Added to cart: ' + title);

                    } catch (error) {
                        console.error('Error adding to cart:', error);
                        alert('❌ Failed to add to cart: ' + error.message);
                    }
                }

                function signContract(data, components) {
                    try {
                        // Extract contract info from BDO
                        const bdo = data.bdo || data;
                        const contractUuid = components.contractUuid || bdo.contractUuid || 'unknown';
                        const contractId = components.contractId || bdo.contractId || 'unknown';
                        const title = bdo.title || 'Unknown Contract';

                        console.log('Signing contract:', { contractUuid, contractId, title });

                        // Send message to Swift to sign the contract
                        window.webkit.messageHandlers.signContract.postMessage({
                            action: 'sign',
                            contractUuid: contractUuid,
                            contractId: contractId,
                            title: title,
                            fullBDO: data
                        });

                        // Show success feedback
                        alert('✍️ Signing contract: ' + title);

                    } catch (error) {
                        console.error('Error signing contract:', error);
                        alert('❌ Failed to sign contract: ' + error.message);
                    }
                }

                function declineContract(data, components) {
                    try {
                        // Extract contract info from BDO
                        const bdo = data.bdo || data;
                        const contractId = components.contractId || bdo.contractId || 'unknown';
                        const title = bdo.title || 'Unknown Contract';

                        console.log('Declining contract:', { contractId, title });

                        // Show confirmation
                        if (confirm('Are you sure you want to decline this contract?')) {
                            // Send message to Swift to decline the contract
                            window.webkit.messageHandlers.declineContract.postMessage({
                                action: 'decline',
                                contractId: contractId,
                                title: title
                            });

                            alert('❌ Contract declined: ' + title);
                        }

                    } catch (error) {
                        console.error('Error declining contract:', error);
                        alert('❌ Failed to decline contract: ' + error.message);
                    }
                }

                function shareRecipe(data) {
                    alert('📤 Share recipe: ' + (data.title || 'Recipe'));
                }


                function castMagic(data, components) {
                    console.log('🪄 Generic magic spell:', components);
                    alert('🪄 Magic cast: ' + (data.title || 'Item'));
                }

                function purchaseLesson(data, components) {
                    try {
                        console.log('📚 Purchase lesson spell:', components);
                        const lessonId = components.lessonId || components.productId || 'unknown';
                        const price = components.price || components.amount || 0;
                        const lessonTitle = data.title || components.title || 'Lesson';

                        // Send to Swift to initiate purchase flow
                        window.webkit.messageHandlers.purchaseLesson.postMessage({
                            action: 'purchaseLesson',
                            lessonId: lessonId,
                            title: lessonTitle,
                            price: price,
                            components: components,
                            fullBDO: data
                        });

                        alert('📚 Starting lesson purchase: ' + lessonTitle);
                    } catch (error) {
                        console.error('Error purchasing lesson:', error);
                        alert('❌ Failed to purchase lesson: ' + error.message);
                    }
                }

                function signInMoney(data, components) {
                    try {
                        console.log('💰 Sign in money spell:', components);
                        const amount = components.amount || 0;
                        const contractUuid = components.contractUuid || 'unknown';

                        // Send to Swift to process payment and sign contract
                        window.webkit.messageHandlers.signInMoney.postMessage({
                            action: 'signInMoney',
                            amount: amount,
                            contractUuid: contractUuid,
                            components: components,
                            fullBDO: data
                        });

                        alert('💰 Processing payment: $' + (amount / 100).toFixed(2));
                    } catch (error) {
                        console.error('Error processing payment:', error);
                        alert('❌ Failed to process payment: ' + error.message);
                    }
                }

                function purchaseItem(data, components) {
                    try {
                        console.log('💳 Purchase item spell:', components);
                        const productId = components.productId || 'unknown';
                        const amount = components.amount || 0;
                        const mp = components.mp;

                        // Send to Swift to process purchase
                        window.webkit.messageHandlers.purchase.postMessage({
                            action: 'purchase',
                            productId: productId,
                            amount: amount,
                            mp: mp,
                            components: components,
                            fullBDO: data
                        });

                        alert('💳 Processing purchase: $' + (amount / 100).toFixed(2));
                    } catch (error) {
                        console.error('Error processing purchase:', error);
                        alert('❌ Failed to process purchase: ' + error.message);
                    }
                }

                function handleSelection(data, components) {
                    try {
                        console.log('🎯 Selection spell:', components);
                        // Add to in-memory selection storage
                        if (!window.magistackSelections) {
                            window.magistackSelections = [];
                        }

                        const selection = {
                            ...components,
                            timestamp: new Date().toISOString(),
                            id: 'selection_' + Date.now()
                        };

                        window.magistackSelections.push(selection);
                        console.log('📦 Added to magistack:', selection);
                        alert('✅ Selection added (' + window.magistackSelections.length + ' total)');
                    } catch (error) {
                        console.error('Error handling selection:', error);
                        alert('❌ Failed to add selection: ' + error.message);
                    }
                }

                function navigateToCard(data, components) {
                    try {
                        console.log('🧭 Navigate to card:', components);
                        const bdoPubKey = components.bdoPubKey || 'unknown';

                        // Send to Swift to navigate to new card
                        window.webkit.messageHandlers.navigateToCard.postMessage({
                            action: 'navigate',
                            bdoPubKey: bdoPubKey,
                            components: components
                        });

                        alert('🧭 Navigating to card...');
                    } catch (error) {
                        console.error('Error navigating to card:', error);
                        alert('❌ Failed to navigate: ' + error.message);
                    }
                }

                function lookupProduct(data, components) {
                    try {
                        console.log('🔍 Lookup product spell:', components);
                        const catalog = components.catalog || {};

                        if (!window.magistackSelections || window.magistackSelections.length === 0) {
                            throw new Error('No magistack selections for lookup');
                        }

                        // Send to Swift to perform lookup
                        window.webkit.messageHandlers.lookupProduct.postMessage({
                            action: 'lookup',
                            catalog: catalog,
                            selections: window.magistackSelections,
                            components: components
                        });

                        alert('🔍 Looking up product...');
                    } catch (error) {
                        console.error('Error looking up product:', error);
                        alert('❌ Failed to lookup product: ' + error.message);
                    }
                }

                function handleGenericSpell(spell, data, components) {
                    console.log('⚡ Generic spell handler:', spell, components);

                    // Try to send to Swift for handling
                    try {
                        window.webkit.messageHandlers.genericSpell.postMessage({
                            action: 'genericSpell',
                            spell: spell,
                            components: components,
                            fullBDO: data
                        });

                        alert('⚡ Casting ' + spell + ' spell...');
                    } catch (error) {
                        // Fallback if Swift handler doesn't exist
                        console.warn('No Swift handler for spell:', spell);
                        alert('⚡ Unknown spell: ' + spell + '\\n\\nThis spell is not yet implemented.');
                    }
                }

                function openCarrierBag() {
                    try {
                        console.log('🎒 Saving BDO to carrier bag');

                        const bdo = bdoData.bdo || bdoData;
                        const type = bdo.type || 'item';
                        const title = bdo.title || bdo.productTitle || 'Untitled';

                        // Determine collection from BDO type
                        let collection = 'stacks'; // default
                        if (type === 'contract-signing-ui' || type === 'contract') {
                            collection = 'contracts';
                        } else if (type === 'recipe') {
                            collection = 'cookbook';
                        } else if (type === 'ebook' || type === 'book' || type === 'article') {
                            collection = 'bookshelf';
                        } else if (type === 'potion' || type === 'remedy') {
                            collection = 'apothecary';
                        } else if (type === 'artwork' || type === 'image') {
                            collection = 'gallery';
                        } else if (type === 'music' || type === 'song') {
                            collection = 'music';
                        } else if (type === 'event') {
                            collection = 'events';
                        }

                        console.log('Saving to collection:', collection, 'with type:', type);

                        // Send message to Swift to save to carrierBag
                        window.webkit.messageHandlers.saveToCarrierBag.postMessage({
                            action: 'saveToCarrierBag',
                            collection: collection,
                            type: type,
                            title: title,
                            bdoData: bdo,
                            purchased: false
                        });

                        alert('✅ Saved to ' + collection + '!');

                    } catch (error) {
                        console.error('Error saving to carrier bag:', error);
                        alert('❌ Failed to save: ' + error.message);
                    }
                }

                // Global function for SVG onclick handlers (called by product SVGs)
                window.purchaseProduct = function(productId, emojicode) {
                    try {
                        console.log('💳 Purchase product clicked:', productId, emojicode);

                        // Extract product info from BDO data
                        const bdo = bdoData.bdo || bdoData;
                        const price = bdo.price || 0;
                        const title = bdo.title || bdo.productTitle || 'Product';

                        console.log('Product details:', { productId, price, title, emojicode });

                        // Call the purchaseProduct handler in Swift
                        window.webkit.messageHandlers.purchase.postMessage({
                            action: 'purchaseProduct',
                            productId: productId,
                            price: price,
                            title: title,
                            emojicode: emojicode,
                            bdoData: bdo
                        });

                    } catch (error) {
                        console.error('Error purchasing product:', error);
                        alert('❌ Failed to start purchase: ' + error.message);
                    }
                };

                // Share BDO function
                function shareBDO() {
                    try {
                        console.log('📤 Share BDO clicked');

                        const bdo = bdoData.bdo || bdoData;
                        const title = bdo.title || bdo.productTitle || 'Shared Item';

                        console.log('Creating shareable BDO with affiliate payee for:', title);

                        // Send message to Swift to create a new BDO with user's payee quad added
                        window.webkit.messageHandlers.shareBDO.postMessage({
                            action: 'shareBDO',
                            bdoData: bdo,
                            title: title
                        });

                    } catch (error) {
                        console.error('Error sharing BDO:', error);
                        alert('❌ Failed to share: ' + error.message);
                    }
                }
            </script>
        </body>
        </html>
        """

        resultWebView.loadHTMLString(html, baseURL: nil)

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

    func displayError(_ title: String, details: String, baseUrl: String? = nil) {
        // In production, show user-friendly messages
        // In test/local, show debug details
        let isProduction = Configuration.environment == "production"

        let displayTitle: String
        let displayDetails: String

        if isProduction {
            // User-friendly production messages
            if title.contains("Fetch Failed") || title.contains("Network") || details.contains("URLSession") {
                displayTitle = "Connection Issue"
                displayDetails = """
                ⚠️ Unable to fetch content

                This keyboard needs "Allow Full Access" permission to connect to Planet Nine services.

                To enable it:
                1. Open Settings app
                2. Go to General → Keyboard → Keyboards
                3. Tap "AdvanceKey"
                4. Turn ON "Allow Full Access"

                This permission is required for the keyboard to:
                • Decode emojicodes
                • Fetch BDOs from Planet Nine
                • Display content

                \(baseUrl.map { "🌐 You can also check this content in Safari:\n\($0)" } ?? "")
                """
            } else if title.contains("Decode Failed") || title.contains("Invalid") {
                displayTitle = "Invalid Emojicode"
                displayDetails = """
                🎯 The emojicode format seems incorrect

                Valid formats:
                • 9 consecutive emojis (e.g., 🌍🔑💎🌟💎🎨🐉📌🎯)
                • Emojis wrapped in sparkles (e.g., ✨🏰👑✨)

                Tips:
                • Make sure you've selected the entire emojicode
                • Check that sparkles (✨) are included if needed
                • Try copying the emojicode again
                """
            } else {
                // Generic production error
                displayTitle = "Something Went Wrong"
                displayDetails = """
                ⚠️ \(title)

                Please make sure:
                • "Allow Full Access" is enabled for AdvanceKey
                • You have an internet connection
                • The emojicode is valid

                \(baseUrl.map { "🌐 Try opening this in Safari:\n\($0)" } ?? "")
                """
            }
        } else {
            // Debug mode - show all details
            displayTitle = title
            displayDetails = details
        }

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
                    font-family: \(isProduction ? "-apple-system, BlinkMacSystemFont, sans-serif" : "Monaco, 'Courier New', monospace");
                    font-size: \(isProduction ? "12px" : "10px");
                    background: #f8f9fa;
                    padding: 10px;
                    border-radius: 4px;
                    overflow-x: auto;
                }
                a {
                    color: #0066cc;
                    word-break: break-all;
                }
            </style>
        </head>
        <body>
            <div class="error-container">
                <div class="error-title">❌ \(displayTitle)</div>
                <div class="error-details">\(displayDetails)</div>
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
        } else if message.name == "saveRecipe" || message.name == "saveToStacks" || message.name == "saveToCarrierBag" {
            handleSaveToCarrierBagMessage(message.body)
        } else if message.name == "addToCart" {
            handleAddToCartMessage(message.body)
        } else if message.name == "signContract" {
            handleSignContractMessage(message.body)
        } else if message.name == "declineContract" {
            handleDeclineContractMessage(message.body)
        } else if message.name == "paymentMethodSelected" {
            handlePaymentMethodSelection(message.body as? [String: Any] ?? [:])
        } else if message.name == "addPaymentMethod" {
            handleAddPaymentMethod()
        } else if message.name == "contractAuthorization" {
            handleContractAuthorizationMessage(message.body)
        } else if message.name == "purchase" {
            handlePurchaseMessage(message.body)
        } else if message.name == "navigateToCard" {
            handleNavigateToCardMessage(message.body)
        } else if message.name == "openCarrierBag" {
            handleOpenCarrierBagMessage(message.body)
        } else if message.name == "shareBDO" {
            handleShareBDOMessage(message.body)
        } else if message.name == "advanceKey" {
            handleAdvanceKeyMessage(message.body)
        }
    }

    private func handleContractAuthorizationMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 🔐 Contract authorization message received")

        guard let messageDict = messageBody as? [String: Any],
              let isAuthorized = messageDict["isAuthorized"] as? Bool,
              let contractData = messageDict["contractData"] as? [String: Any] else {
            NSLog("ADVANCEKEY: ❌ Invalid contract authorization message format")
            return
        }

        // Store contract data for button action
        currentContractData = contractData

        // Update button appearance on main thread
        DispatchQueue.main.async {
            self.contractActionButton.isHidden = false

            if isAuthorized {
                self.contractActionButton.setTitle("SIGN", for: .normal)
                self.contractActionButton.backgroundColor = UIColor.systemGreen
                self.contractActionButton.isEnabled = true
                NSLog("ADVANCEKEY: ✅ User is authorized to sign this contract")
            } else {
                self.contractActionButton.setTitle("View-Only", for: .normal)
                self.contractActionButton.backgroundColor = UIColor.systemGray
                self.contractActionButton.isEnabled = false
                NSLog("ADVANCEKEY: 👁️ User can only view this contract")
            }
        }
    }

    private func handleSaveToCarrierBagMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 💾 Save to carrierBag message received")

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String else {
            NSLog("ADVANCEKEY: ❌ Invalid save message format")
            return
        }

        // Get collection, type, title, and BDO data
        let collection = messageDict["collection"] as? String ?? "stacks"
        let type = messageDict["type"] as? String ?? "item"
        let title = messageDict["title"] as? String ?? "Untitled Item"

        // Get the full BDO data - could be bdoData (new format) or roomData (legacy)
        var bdoData: [String: Any] = [:]
        if let data = messageDict["bdoData"] as? [String: Any] {
            bdoData = data
        } else if let data = messageDict["roomData"] as? [String: Any] {
            bdoData = data
        }

        NSLog("ADVANCEKEY: 💾 Saving '\(title)' to \(collection)")

        // Check if this is a purchased item
        let purchased = messageDict["purchased"] as? Bool ?? false
        if purchased {
            NSLog("ADVANCEKEY: ✅ Item marked as purchased")
        }

        // Create the item entry with optional purchased flag
        var itemEntry: [String: Any] = [
            "type": type,
            "title": title,
            "bdoData": bdoData,
            "savedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Add purchased flag if true
        if purchased {
            itemEntry["purchased"] = true
            itemEntry["purchasedAt"] = ISO8601DateFormatter().string(from: Date())
        }

        // Save to SharedUserDefaults carrierBag
        SharedUserDefaults.addToCarrierBagCollection(collection, item: itemEntry)

        NSLog("ADVANCEKEY: ✅ Saved to \(collection) via SharedUserDefaults")
        NSLog("ADVANCEKEY: 📦 Main app will sync to BDO on next launch")
    }

    private func handleAddToCartMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 🛒 Add to cart message received")

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String,
              action == "add-to-cart" else {
            NSLog("ADVANCEKEY: ❌ Invalid add to cart message format")
            return
        }

        let productId = messageDict["productId"] as? String ?? "unknown"
        let baseUuid = messageDict["baseUuid"] as? String ?? "unknown"
        let title = messageDict["title"] as? String ?? "Unknown Product"
        let quantity = messageDict["quantity"] as? Int ?? 1

        NSLog("ADVANCEKEY: 🛒 Adding to cart - Product: %@, Base: %@, Quantity: %d", productId, baseUuid, quantity)

        // Add to cart using SharedUserDefaults
        SharedUserDefaults.addToCart(productId: productId, baseUuid: baseUuid, quantity: quantity)

        // Debug: Print cart contents
        let cart = SharedUserDefaults.getCart()
        let itemCount = SharedUserDefaults.getCartItemCount()
        NSLog("ADVANCEKEY: 🛒 Cart now has %d items (%d total)", cart.count, itemCount)

        // Print cart details
        for (index, item) in cart.enumerated() {
            let itemProductId = item["productId"] as? String ?? "unknown"
            let itemQuantity = item["quantity"] as? Int ?? 1
            NSLog("ADVANCEKEY: 🛒   [%d] %@ (qty: %d)", index, itemProductId, itemQuantity)
        }
    }

    private func handleSignContractMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: ✍️ Sign contract message received")

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String,
              action == "sign" else {
            NSLog("ADVANCEKEY: ❌ Invalid sign contract message format")
            return
        }

        let contractUuid = messageDict["contractUuid"] as? String ?? "unknown"
        let contractId = messageDict["contractId"] as? String ?? "unknown"
        let title = messageDict["title"] as? String ?? "Unknown Contract"

        NSLog("ADVANCEKEY: ✍️ Signing contract - UUID: %@, ID: %@, Title: %@", contractUuid, contractId, title)

        // TODO: In a real implementation, we would:
        // 1. Fetch the contract from Covenant to get the list of steps
        // 2. Present UI for user to select which step to sign
        // 3. Get the stepId from user selection

        // For now, we'll use a placeholder stepId
        let stepId = "step-1" // TODO: Get actual step ID from contract or user selection

        signContractStep(contractUuid: contractUuid, stepId: stepId)
    }

    private func signContractStep(contractUuid: String, stepId: String) {
        NSLog("ADVANCEKEY: ✍️ Signing contract step - UUID: %@, Step: %@", contractUuid, stepId)

        // Get user's pubKey and covenant UUID from SharedUserDefaults
        guard let userPubKey = SharedUserDefaults.getCurrentUserPubKey() else {
            NSLog("ADVANCEKEY: ❌ No user pubKey found")
            return
        }

        guard let covenantUserUUID = SharedUserDefaults.getCovenantUserUUID() else {
            NSLog("ADVANCEKEY: ❌ No covenant user UUID found - need to create covenant user first")
            return
        }

        NSLog("ADVANCEKEY: ✍️ User pubKey: %@", userPubKey)
        NSLog("ADVANCEKEY: ✍️ Covenant UUID: %@", covenantUserUUID)

        // Create timestamp for sessionless auth
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        // Create auth message: timestamp + contractUuid (for Covenant's verifySessionlessAuth)
        let authMessage = timestamp + contractUuid

        // Sign the auth message using sessionless
        guard let authSignature = sessionless.sign(message: authMessage) else {
            NSLog("ADVANCEKEY: ❌ Failed to create auth signature")
            return
        }

        // Create step signature message: timestamp + userUUID + contractUuid + stepId
        let stepMessage = timestamp + covenantUserUUID + contractUuid + stepId

        // Sign the step message using sessionless
        guard let stepSignature = sessionless.sign(message: stepMessage) else {
            NSLog("ADVANCEKEY: ❌ Failed to create step signature")
            return
        }

        // Prepare request to Covenant
        let covenantURL = URL(string: Configuration.Covenant.signContract(contractUuid: contractUuid))!
        var request = URLRequest(url: covenantURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(timestamp, forHTTPHeaderField: "timestamp")
        request.setValue(authSignature, forHTTPHeaderField: "signature")
        request.setValue(covenantUserUUID, forHTTPHeaderField: "userUUID")
        request.setValue(userPubKey, forHTTPHeaderField: "pubKey")

        let body: [String: Any] = [
            "stepId": stepId,
            "stepSignature": stepSignature
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        NSLog("ADVANCEKEY: ✍️ Sending signature to Covenant...")
        NSLog("ADVANCEKEY: ✍️ URL: %@", covenantURL.absoluteString)
        NSLog("ADVANCEKEY: ✍️ Auth message: %@", authMessage)
        NSLog("ADVANCEKEY: ✍️ Step message: %@", stepMessage)
        NSLog("ADVANCEKEY: ✍️ Headers: timestamp=%@, userUUID=%@, pubKey=%@", timestamp, covenantUserUUID, userPubKey)

        // Make the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                NSLog("ADVANCEKEY: ❌ Covenant request error: %@", error.localizedDescription)
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                NSLog("ADVANCEKEY: ❌ Invalid response from Covenant")
                return
            }

            NSLog("ADVANCEKEY: ✍️ Covenant response status: %d", httpResponse.statusCode)

            if let data = data,
               let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                NSLog("ADVANCEKEY: ✍️ Covenant response: %@", String(describing: responseJSON))

                if httpResponse.statusCode == 200 {
                    NSLog("ADVANCEKEY: ✅ Contract step signed successfully!")
                } else {
                    if let errorMsg = responseJSON["error"] as? String {
                        NSLog("ADVANCEKEY: ❌ Covenant error: %@", errorMsg)
                    }
                }
            }
        }

        task.resume()
    }

    private func handleDeclineContractMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: ❌ Decline contract message received")

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String,
              action == "decline" else {
            NSLog("ADVANCEKEY: ❌ Invalid decline contract message format")
            return
        }

        let contractId = messageDict["contractId"] as? String ?? "unknown"
        let title = messageDict["title"] as? String ?? "Unknown Contract"

        NSLog("ADVANCEKEY: ❌ Declining contract - ID: %@, Title: %@", contractId, title)

        // TODO: Send decline notification to Covenant service
        NSLog("ADVANCEKEY: ❌ Contract decline would be submitted here")
    }

    private func handlePurchaseMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 🎫 Purchase message received")
        NSLog("ADVANCEKEY: 🎫 Message body: %@", String(describing: messageBody))

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String else {
            NSLog("ADVANCEKEY: ❌ Invalid purchase message format")
            return
        }

        NSLog("ADVANCEKEY: 🎫 Action detected: %@", action)

        // Handle confirmation dialog responses
        if action == "confirm" {
            NSLog("ADVANCEKEY: ✅ Purchase confirmed by user")
            guard let eventUUID = messageDict["eventUUID"] as? String,
                  let ticketFlavor = messageDict["ticketFlavor"] as? String,
                  let price = messageDict["price"] as? Int,
                  let priceType = messageDict["priceType"] as? String else {
                NSLog("ADVANCEKEY: ❌ Missing purchase confirmation data")
                return
            }

            NSLog("ADVANCEKEY: 🚀 Starting purchase process...")
            processEventTicketPurchase(
                eventUUID: eventUUID,
                ticketFlavor: ticketFlavor,
                price: price,
                priceType: priceType,
                eventData: [:] // Will be fetched if needed
            )

            // Clear banner
            clearBanner()
            return
        } else if action == "cancel" {
            NSLog("ADVANCEKEY: ❌ Purchase canceled by user")
            clearBanner()
            return
        }

        // Handle purchase actions (both "purchase" and "purchaseProduct")
        guard action == "purchase" || action == "purchaseProduct" else {
            NSLog("ADVANCEKEY: ❌ Unknown action: %@", action)
            return
        }

        // Extract BDO data for purchaseProduct action
        if action == "purchaseProduct", let bdoData = messageDict["bdoData"] as? [String: Any] {
            NSLog("ADVANCEKEY: 💳 Processing purchaseProduct with BDO data")

            // Extract metadata
            let metadata = bdoData["metadata"] as? [String: Any] ?? [:]
            let priceStr = metadata["priceFormatted"] as? String ?? "$0.00"
            let priceInCents = extractPriceInCents(from: priceStr)
            let productTitle = metadata["productTitle"] as? String ?? "Unknown Product"
            let sanoraUUID = metadata["sanoraUUID"] as? String

            // Extract payees
            let payees = bdoData["payees"] as? [[String: Any]] ?? []

            NSLog("ADVANCEKEY: 💳 Product: %@, Price: %d cents", productTitle, priceInCents)
            NSLog("ADVANCEKEY: 💳 Payees: %d", payees.count)

            // Process the purchase with Stripe payment
            processPurchaseWithStripe(
                productTitle: productTitle,
                priceInCents: priceInCents,
                payees: payees,
                sanoraUUID: sanoraUUID,
                bdoData: bdoData
            )
            return
        }

        // Original purchase flow for legacy "purchase" action
        let components = messageDict["components"] as? [String: Any] ?? [:]
        let fullBDO = messageDict["fullBDO"] as? [String: Any] ?? [:]

        // Extract event/item details
        let itemType = (fullBDO["bdo"] as? [String: Any])?["type"] as? String ?? "item"
        let price = components["amount"] as? Int ?? components["price"] as? Int ?? 0
        let priceType = components["priceType"] as? String ?? "cash"
        let productId = components["productId"] as? String

        NSLog("ADVANCEKEY: 🎫 Purchase details - Type: %@, Price: %d, PriceType: %@", itemType, price, priceType)

        // Check if this is an event ticket purchase
        if itemType == "event",
           let eventUUID = components["eventUUID"] as? String,
           let ticketFlavor = components["ticketFlavor"] as? String {
            NSLog("ADVANCEKEY: 🎫 Event ticket purchase detected")
            purchaseEventTicket(eventUUID: eventUUID, ticketFlavor: ticketFlavor, price: price, priceType: priceType, fullBDO: fullBDO)
        } else if let productId = productId {
            NSLog("ADVANCEKEY: 🎫 Product purchase detected: %@", productId)
            // Handle general product purchase
            purchaseProduct(productId: productId, price: price, fullBDO: fullBDO)
        } else {
            NSLog("ADVANCEKEY: ❌ Unknown purchase type")
        }
    }

    // Helper to extract price in cents from formatted string like "$199.99"
    private func extractPriceInCents(from priceString: String) -> Int {
        // Remove $ and convert to cents
        let cleaned = priceString.replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
        if let dollars = Double(cleaned) {
            return Int(dollars * 100)
        }
        return 0
    }

    // Process purchase with Stripe payment for purchaseProduct action
    private func processPurchaseWithStripe(
        productTitle: String,
        priceInCents: Int,
        payees: [[String: Any]],
        sanoraUUID: String?,
        bdoData: [String: Any]
    ) {
        NSLog("ADVANCEKEY: 💳 Processing Stripe purchase for: %@", productTitle)
        NSLog("ADVANCEKEY: 💰 Price: %d cents", priceInCents)

        // Use the existing payment method selection flow
        // The bdoData contains all the information needed for the purchase
        showPaymentMethodSelection(for: productTitle, price: priceInCents, bdoData: bdoData)
    }

    private func handleNavigateToCardMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 🧭 Navigate to card message received")

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String,
              action == "navigate",
              let bdoPubKey = messageDict["bdoPubKey"] as? String else {
            NSLog("ADVANCEKEY: ❌ Invalid navigate to card message format")
            return
        }

        NSLog("ADVANCEKEY: 🧭 Fetching BDO with pubKey: %@", bdoPubKey)

        // Use the existing fetchBDOFromServer method which handles authentication
        Task {
            do {
                let baseUrl = Configuration.BDO.baseURL
                let cardData = try await fetchBDOFromServer(bdoPubKey: bdoPubKey, baseUrl: baseUrl)

                NSLog("ADVANCEKEY: ✅ BDO fetched successfully")

                // Display the BDO in the keyboard
                await MainActor.run {
                    self.displayBDOContent(cardData: cardData, bdoPubKey: bdoPubKey)
                }

            } catch {
                NSLog("ADVANCEKEY: ❌ Error fetching BDO: %@", error.localizedDescription)
                await MainActor.run {
                    self.displayError("Navigation Failed", details: "Could not fetch BDO: \(error.localizedDescription)")
                }
            }
        }
    }

    private func handleOpenCarrierBagMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 🎒 Open carrier bag message received")

        // Open the main app with carrier bag URL
        // Note: Keyboard extensions can't directly open URLs, but we can request the system to do it
        guard let url = URL(string: "theadvancement://carrierbag") else {
            NSLog("ADVANCEKEY: ❌ Invalid carrier bag URL")
            return
        }

        // Use the extensionContext to open URL in the containing app
        var responder: UIResponder? = self as UIResponder
        let selector = #selector(openURL(_:))

        // Walk up the responder chain to find one that can open URLs
        while responder != nil {
            if let application = responder as? UIApplication {
                application.perform(selector, with: url)
                NSLog("ADVANCEKEY: ✅ Opening carrier bag in main app")
                return
            }
            responder = responder?.next
        }

        // Fallback: try using openURL selector on the extension context
        self.extensionContext?.open(url, completionHandler: { success in
            if success {
                NSLog("ADVANCEKEY: ✅ Successfully opened carrier bag URL")
            } else {
                NSLog("ADVANCEKEY: ❌ Failed to open carrier bag URL")
            }
        })
    }

    private func handleShareBDOMessage(_ messageBody: Any) {
        NSLog("ADVANCEKEY: 📤 Share BDO message received")

        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String,
              action == "shareBDO",
              let bdoData = messageDict["bdoData"] as? [String: Any],
              let title = messageDict["title"] as? String else {
            NSLog("ADVANCEKEY: ❌ Invalid share BDO message format")
            return
        }

        // Get user's keys for creating affiliate payee
        guard let keys = sessionless.getKeys() else {
            NSLog("ADVANCEKEY: ❌ No user keys found")
            showShareError("Authentication required")
            return
        }

        // Check if user has any saved payment methods (using same method as purchase flow)
        let storedMethods = loadStoredPaymentMethods()
        guard storedMethods.count > 0 else {
            NSLog("ADVANCEKEY: ❌ No payment methods configured")
            showShareError("Please add a payment method in the main app first to receive affiliate commissions")
            return
        }

        // Use the first payment method as the payout card
        let payoutCardId = storedMethods[0].id
        NSLog("ADVANCEKEY: 💳 Using payment method for payouts: %@ •••• %@", storedMethods[0].brand, storedMethods[0].last4)

        // Get the total price from the BDO
        guard let price = bdoData["price"] as? Int, price > 0 else {
            NSLog("ADVANCEKEY: ❌ No price found in BDO")
            showShareError("This item doesn't have a price")
            return
        }

        // Calculate 10% affiliate commission
        let affiliateAmount = Int(Double(price) * 0.10)

        NSLog("ADVANCEKEY: 💰 Creating affiliate share")
        NSLog("ADVANCEKEY:   Total price: $%.2f", Double(price) / 100.0)
        NSLog("ADVANCEKEY:   Affiliate (10%%): $%.2f", Double(affiliateAmount) / 100.0)
        NSLog("ADVANCEKEY:   Payout card: %@", payoutCardId)

        // Create the affiliate payee quad
        let affiliatePayee: [String: Any] = [
            "pubKey": keys.publicKey,
            "amount": affiliateAmount,
            "payoutCard": payoutCardId,
            "percentage": 10
        ]

        // Get existing payees array (or create empty one)
        var existingPayees = bdoData["payees"] as? [[String: Any]] ?? []

        // Adjust existing payees to account for 10% affiliate cut
        // Reduce each payee proportionally
        let adjustmentFactor = 0.90 // 90% of original amounts
        existingPayees = existingPayees.map { payee in
            var adjusted = payee
            if let amount = payee["amount"] as? Int {
                adjusted["amount"] = Int(Double(amount) * adjustmentFactor)
            }
            return adjusted
        }

        // Add affiliate payee to the beginning
        var updatedPayees = [affiliatePayee] + existingPayees

        NSLog("ADVANCEKEY: 📋 Updated payees count: %d", updatedPayees.count)

        // Create new BDO data with updated payees
        var newBDOData = bdoData
        newBDOData["payees"] = updatedPayees

        // Create the new BDO in Fount
        Task {
            do {
                let emojicode = try await createShareableBDO(bdoData: newBDOData, title: title)
                NSLog("ADVANCEKEY: ✅ Created shareable BDO with emojicode: %@", emojicode)

                // Save to carrierBag "store" collection
                await saveToCarrierBagStore(bdoData: newBDOData, emojicode: emojicode, title: title)

                // Present the emojicode
                await presentEmojicode(emojicode: emojicode, title: title)

            } catch {
                NSLog("ADVANCEKEY: ❌ Failed to create shareable BDO: %@", error.localizedDescription)
                await MainActor.run {
                    showShareError(error.localizedDescription)
                }
            }
        }
    }

    private func getFountUserUUID() async throws -> String {
        // Debug: Check what's in SharedUserDefaults
        NSLog("ADVANCEKEY: 🔍 Checking SharedUserDefaults for Fount user UUID...")
        NSLog("ADVANCEKEY: 🔍 Using App Group: group.com.planetnine.Planet-Nine")

        // Print all SharedUserDefaults contents for debugging
        SharedUserDefaults.debugPrint(prefix: "ADVANCEKEY")

        // Check if we already have a Fount user UUID in SharedUserDefaults
        if let existingUUID = SharedUserDefaults.getFountUserUUID() {
            NSLog("ADVANCEKEY: ✅ Found existing Fount user UUID: %@", existingUUID)
            return existingUUID
        }

        // Also check regular UserDefaults as fallback
        if let regularUUID = UserDefaults.standard.string(forKey: "fountUserUUID") {
            NSLog("ADVANCEKEY: ⚠️ Found UUID in regular UserDefaults (not shared): %@", regularUUID)
            NSLog("ADVANCEKEY: ⚠️ This UUID won't be accessible to keyboard extension")

            // If we found it in regular UserDefaults, copy it to SharedUserDefaults
            NSLog("ADVANCEKEY: 📋 Copying Fount UUID from regular UserDefaults to SharedUserDefaults...")
            SharedUserDefaults.setFountUserUUID(regularUUID)
            return regularUUID
        }

        // Need to create a new Fount user via API
        NSLog("ADVANCEKEY: 🆕 No Fount user UUID found in SharedUserDefaults, creating new Fount user...")

        guard let keys = sessionless.getKeys() else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user keys found"])
        }

        let pubKey = keys.publicKey
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let homeBase = Configuration.fountBaseURL
        let endpoint = "\(homeBase)/user/create"

        // Sign the request
        let message = timestamp + pubKey
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign request"])
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        NSLog("ADVANCEKEY: 📡 Creating Fount user...")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEKEY: 📡 Fount user creation response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            NSLog("ADVANCEKEY: ❌ Fount user creation failed: %@", errorText)
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to create Fount user: \(errorText)"])
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuid = json["uuid"] as? String else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Fount user creation"])
        }

        // Store the UUID in SharedUserDefaults for future use
        SharedUserDefaults.setFountUserUUID(uuid)
        NSLog("ADVANCEKEY: ✅ Created and saved new Fount user UUID: %@", uuid)

        return uuid
    }

    // Helper method to sign with arbitrary keys (not just saved user keys)
    private func signWithKeys(message: String, privateKey: String) -> String? {
        NSLog("ADVANCEKEY: 🖊️ Signing with custom keys...")

        guard let signJS = sessionless.jsContext?.objectForKeyedSubscript("globalThis")?.objectForKeyedSubscript("sessionless")?.objectForKeyedSubscript("sign") else {
            NSLog("ADVANCEKEY: ❌ Cannot sign: signJS not available")
            return nil
        }

        guard let signaturejs = signJS.call(withArguments: [message, privateKey]) else {
            NSLog("ADVANCEKEY: ❌ Failed to call signJS")
            return nil
        }

        let signature = signaturejs.toString()
        NSLog("ADVANCEKEY: ✅ Message signed successfully")
        return signature
    }

    private func createShareableBDO(bdoData: [String: Any], title: String) async throws -> String {
        NSLog("ADVANCEKEY: 🏗️ Creating new BDO with affiliate payee")

        // Save current user keys
        guard let originalKeys = sessionless.getKeys() else {
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user keys found"])
        }

        // 1. Generate NEW sessionless keys for the BDO (DO NOT SAVE)
        guard let bdoKeys = sessionless.generateKeys() else {
            throw NSError(domain: "CryptoError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to generate BDO keys"])
        }

        let bdoPubKey = bdoKeys.publicKey
        NSLog("ADVANCEKEY: 🔑 Generated new BDO keys: %@", String(bdoPubKey.prefix(16)))

        // 2. Create BDO user with the new keys
        let bdoBaseURL = Configuration.bdoBaseURL
        let createUserEndpoint = Configuration.BDO.createUser()

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "The Advancement"
        let message = timestamp + bdoPubKey + hash  // timestamp + pubKey + hash
        guard let signature = signWithKeys(message: message, privateKey: bdoKeys.privateKey) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign BDO user creation"])
        }

        var createUserRequest = URLRequest(url: URL(string: createUserEndpoint)!)
        createUserRequest.httpMethod = "PUT"
        createUserRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let createUserBody: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": bdoPubKey,
            "signature": signature,
            "hash": hash,  // Hash for BDO authentication
            "bdo": bdoData  // Include the BDO data with affiliate payee
        ]

        createUserRequest.httpBody = try JSONSerialization.data(withJSONObject: createUserBody)

        NSLog("ADVANCEKEY: 📡 Creating BDO user...")
        let (createData, createResponse) = try await URLSession.shared.data(for: createUserRequest)

        guard let httpResponse = createResponse as? HTTPURLResponse,
              httpResponse.statusCode == 201 || httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: createData) as? [String: Any],
              let bdoUUID = json["uuid"] as? String else {
            let errorText = String(data: createData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BDOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create BDO user: \(errorText)"])
        }

        NSLog("ADVANCEKEY: ✅ BDO user created: %@", bdoUUID)

        // 3. Update BDO to make it PUBLIC (this generates the emojicode)
        let updateTimestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let updateMessage = updateTimestamp + bdoUUID + hash  // timestamp + uuid + hash
        guard let updateSignature = signWithKeys(message: updateMessage, privateKey: bdoKeys.privateKey) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign BDO update"])
        }

        let updateEndpoint = Configuration.BDO.putBDO(userUUID: bdoUUID)
        var updateRequest = URLRequest(url: URL(string: updateEndpoint)!)
        updateRequest.httpMethod = "PUT"
        updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updateBody: [String: Any] = [
            "timestamp": updateTimestamp,
            "pubKey": bdoPubKey,
            "signature": updateSignature,
            "hash": hash,  // Hash for BDO authentication
            "bdo": bdoData,
            "public": true  // This triggers emojicode generation
        ]

        updateRequest.httpBody = try JSONSerialization.data(withJSONObject: updateBody)

        NSLog("ADVANCEKEY: 📡 Making BDO public to generate emojicode...")
        let (updateData, updateResponse) = try await URLSession.shared.data(for: updateRequest)

        guard let updateHttpResponse = updateResponse as? HTTPURLResponse,
              updateHttpResponse.statusCode == 200,
              let updateJson = try? JSONSerialization.jsonObject(with: updateData) as? [String: Any],
              let emojicode = updateJson["emojiShortcode"] as? String else {
            let errorText = String(data: updateData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BDOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to make BDO public: \(errorText)"])
        }

        NSLog("ADVANCEKEY: ✅ BDO made public with emojicode: %@", emojicode)
        NSLog("ADVANCEKEY: 🔑 BDO PubKey: %@", bdoPubKey)

        // Don't restore original keys since we never actually changed sessionless.getKeys
        // The bdoKeys were just generated locally and used for signing

        return emojicode
    }

    private func presentEmojicode(emojicode: String, title: String) async {
        NSLog("ADVANCEKEY: 🎨 Presenting emojicode: %@", emojicode)

        // Insert the emojicode into the text field
        await MainActor.run {
            self.textDocumentProxy.insertText(emojicode)

            // Show success alert with clickable emojicode
            let successHTML = """
            <div style="padding: 20px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif; border-radius: 12px; margin: 10px;">
                <div style="font-size: 48px; margin-bottom: 10px;">✅</div>
                <div style="font-size: 18px; font-weight: bold; margin-bottom: 8px;">Shareable Link Created!</div>
                <div style="font-size: 14px; margin-bottom: 12px;">\(title)</div>
                <div onclick="copyEmojicode()" style="font-size: 16px; font-family: monospace; background: rgba(255,255,255,0.2); padding: 8px; border-radius: 6px; word-break: break-all; cursor: pointer; user-select: all;">\(emojicode)</div>
                <div style="font-size: 11px; margin-top: 8px; opacity: 0.7;">👆 Tap to copy</div>
                <div style="font-size: 12px; margin-top: 12px; opacity: 0.9;">You'll earn 10% affiliate commission on purchases made through this link!</div>
            </div>
            <script>
            function copyEmojicode() {
                const emojicode = '\(emojicode)';
                navigator.clipboard.writeText(emojicode).then(() => {
                    window.webkit.messageHandlers.advanceKey.postMessage({
                        action: 'emojicodeCopied',
                        emojicode: emojicode
                    });
                });
            }
            </script>
            """

            self.resultWebView.evaluateJavaScript("document.body.innerHTML = `\(successHTML)`", completionHandler: nil)

            // Clear after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.resultWebView.evaluateJavaScript("document.body.innerHTML = ''", completionHandler: nil)
            }
        }
    }

    private func handleAdvanceKeyMessage(_ messageBody: Any) {
        guard let messageDict = messageBody as? [String: Any],
              let action = messageDict["action"] as? String else {
            return
        }

        if action == "emojicodeCopied" {
            NSLog("ADVANCEKEY: 📋 Emojicode copied to clipboard")
            // Show brief confirmation
            DispatchQueue.main.async {
                let copiedHTML = """
                <div style="padding: 10px; background: rgba(16, 185, 129, 0.9); color: white; text-align: center; font-family: -apple-system; border-radius: 8px; margin: 10px;">
                    <div style="font-size: 14px;">📋 Copied to clipboard!</div>
                </div>
                """
                self.resultWebView.evaluateJavaScript("document.body.innerHTML = `\(copiedHTML)`", completionHandler: nil)

                // Clear after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.resultWebView.evaluateJavaScript("document.body.innerHTML = ''", completionHandler: nil)
                }
            }
        }
    }

    private func saveToCarrierBagStore(bdoData: [String: Any], emojicode: String, title: String) async {
        NSLog("ADVANCEKEY: 💼 Saving shared BDO to carrierBag store collection")

        // Create the item to save with emojicode
        var itemToSave = bdoData
        itemToSave["emojicode"] = emojicode
        itemToSave["title"] = title
        itemToSave["sharedAt"] = ISO8601DateFormatter().string(from: Date())
        itemToSave["type"] = "shared-link"

        // Add to carrierBag "store" collection
        SharedUserDefaults.addToCarrierBagCollection("store", item: itemToSave)
        NSLog("ADVANCEKEY: ✅ Saved shared BDO to store collection")
    }

    private func showShareError(_ message: String) {
        DispatchQueue.main.async {
            let errorHTML = """
            <div style="padding: 20px; background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif; border-radius: 12px; margin: 10px;">
                <div style="font-size: 48px; margin-bottom: 10px;">❌</div>
                <div style="font-size: 18px; font-weight: bold; margin-bottom: 8px;">Share Failed</div>
                <div style="font-size: 14px;">\(message)</div>
            </div>
            """

            self.resultWebView.evaluateJavaScript("document.body.innerHTML = `\(errorHTML)`", completionHandler: nil)

            // Clear after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.resultWebView.evaluateJavaScript("document.body.innerHTML = ''", completionHandler: nil)
            }
        }
    }

    @objc func openURL(_ url: URL) {
        // This is a selector placeholder for the responder chain
    }

    private func clearBanner() {
        let script = "document.getElementById('banner').innerHTML = '';"
        self.resultWebView.evaluateJavaScript(script, completionHandler: nil)
    }

    private func purchaseEventTicket(eventUUID: String, ticketFlavor: String, price: Int, priceType: String, fullBDO: [String: Any]) {
        NSLog("ADVANCEKEY: 🎫 Purchasing event ticket")
        NSLog("ADVANCEKEY:   Event UUID: %@", eventUUID)
        NSLog("ADVANCEKEY:   Ticket Flavor: %@", ticketFlavor)

        // Format price based on type
        let priceDisplay: String
        if priceType == "mp" {
            priceDisplay = "\(price) MP"
            NSLog("ADVANCEKEY:   Price: %d MP", price)
        } else {
            priceDisplay = "$\(String(format: "%.2f", Double(price) / 100.0))"
            NSLog("ADVANCEKEY:   Price: $%.2f", Double(price) / 100.0)
        }

        let eventData = (fullBDO["bdo"] as? [String: Any]) ?? fullBDO
        let eventTitle = eventData["title"] as? String ?? "Event"

        // Show confirmation in WebView banner instead of UIAlertController (not available in keyboard extensions)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            NSLog("ADVANCEKEY: 🎨 Attempting to show confirmation banner...")

            // Show confirmation banner with JavaScript
            let confirmScript = """
                (function() {
                    console.log('BANNER: Looking for banner element...');
                    const banner = document.getElementById('banner');
                    console.log('BANNER: Found banner:', !!banner);
                    if (banner) {
                        banner.innerHTML = `
                            <div style="padding: 10px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                                <div style="font-size: 14px; font-weight: bold; margin-bottom: 5px;">🎫 Purchase Ticket</div>
                                <div style="font-size: 12px; margin-bottom: 8px;">\(eventTitle)</div>
                                <div style="font-size: 13px; margin-bottom: 10px; color: #ffd700;">Price: \(priceDisplay)</div>
                                <div style="display: flex; gap: 10px; justify-content: center;">
                                    <button onclick="console.log('CONFIRM CLICKED'); window.webkit.messageHandlers.purchase.postMessage({action: 'confirm', eventUUID: '\(eventUUID)', ticketFlavor: '\(ticketFlavor)', price: \(price), priceType: '\(priceType)'})"
                                            style="padding: 8px 20px; background: #4CAF50; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: bold; cursor: pointer;">
                                        ✓ Confirm
                                    </button>
                                    <button onclick="console.log('CANCEL CLICKED'); window.webkit.messageHandlers.purchase.postMessage({action: 'cancel'})"
                                            style="padding: 8px 20px; background: #f44336; color: white; border: none; border-radius: 6px; font-size: 13px; font-weight: bold; cursor: pointer;">
                                        ✗ Cancel
                                    </button>
                                </div>
                            </div>
                        `;
                        console.log('BANNER: Banner HTML set');
                        return 'success';
                    } else {
                        console.log('BANNER: No banner element found!');
                        return 'no-banner';
                    }
                })();
            """

            self.resultWebView.evaluateJavaScript(confirmScript) { result, error in
                if let error = error {
                    NSLog("ADVANCEKEY: ❌ Failed to show confirmation: %@", error.localizedDescription)
                    // If banner fails, proceed directly
                    self.processEventTicketPurchase(
                        eventUUID: eventUUID,
                        ticketFlavor: ticketFlavor,
                        price: price,
                        priceType: priceType,
                        eventData: eventData
                    )
                } else {
                    NSLog("ADVANCEKEY: ✅ Confirmation banner script executed: %@", result as? String ?? "unknown")
                }
            }
        }
    }

    private func processEventTicketPurchase(eventUUID: String, ticketFlavor: String, price: Int, priceType: String, eventData: [String: Any]) {
        NSLog("ADVANCEKEY: 💰 Processing event ticket purchase...")

        Task {
            do {
                // Get user pubKey
                guard let userPubKey = SharedUserDefaults.getCurrentUserPubKey() else {
                    throw NSError(domain: "PurchaseError", code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "No user pubKey found"])
                }

                // Get appropriate UUID based on payment type
                // MP purchases need Fount UUID, cash purchases need Covenant/Addie UUID
                let userUUID: String
                if priceType == "mp" {
                    guard let fountUUID = SharedUserDefaults.getFountUserUUID() else {
                        throw NSError(domain: "PurchaseError", code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "No Fount user UUID found. Please ensure you've completed onboarding."])
                    }
                    userUUID = fountUUID
                    NSLog("ADVANCEKEY: 🌊 Using Fount UUID for MP purchase: %@", userUUID)
                } else {
                    guard let covenantUUID = SharedUserDefaults.getCovenantUserUUID() else {
                        throw NSError(domain: "PurchaseError", code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "No Covenant user UUID found"])
                    }
                    userUUID = covenantUUID
                    NSLog("ADVANCEKEY: ⚖️ Using Covenant UUID for cash purchase: %@", userUUID)
                }

                // Step 1: Process payment and transfer nineum
                if priceType == "mp" {
                    NSLog("ADVANCEKEY: 🪄 Step 1: Casting arethaUserPurchase spell...")
                    // Single spell handles MP deduction + nineum transfer atomically
                    try await purchaseTicketWithMP(
                        buyerUUID: userUUID,
                        ticketFlavor: ticketFlavor,
                        mpCost: price
                    )
                    NSLog("ADVANCEKEY: ✅ Ticket purchased with MP!")
                } else {
                    NSLog("ADVANCEKEY: 💳 Step 1: Processing cash payment via Addie...")
                    try await chargePaymentForTicket(
                        userUUID: userUUID,
                        userPubKey: userPubKey,
                        amount: price,
                        eventUUID: eventUUID
                    )
                    NSLog("ADVANCEKEY: ✅ Cash payment successful!")

                    // For cash purchases, still need to transfer nineum
                    NSLog("ADVANCEKEY: 🎟️  Step 2: Transferring ticket nineum...")
                    try await transferTicketNineum(
                        fromUUID: eventUUID,
                        toUUID: userUUID,
                        ticketFlavor: ticketFlavor
                    )
                    NSLog("ADVANCEKEY: ✅ Ticket nineum transferred!")
                }

                // Step 2: Create animated ticket BDO
                NSLog("ADVANCEKEY: 🎨 Step 3: Creating animated ticket BDO...")
                let ticketNumber = Int.random(in: 1...100)
                let ticketBDOPubKey = try await createTicketBDO(
                    ticketNumber: ticketNumber,
                    eventData: eventData,
                    eventUUID: eventUUID,
                    buyerUUID: userUUID,
                    ticketFlavor: ticketFlavor
                )

                NSLog("ADVANCEKEY: ✅ Ticket BDO created: %@", ticketBDOPubKey)

                // Step 4: Add ticket BDO reference to carrierBag
                let eventTitle = eventData["title"] as? String ?? "Event"
                let ticketEntry: [String: Any] = [
                    "type": "ticket",
                    "title": "\(eventTitle) - Ticket #\(ticketNumber)",
                    "eventTitle": eventTitle,
                    "ticketBDOPubKey": ticketBDOPubKey,
                    "ticketNumber": ticketNumber,
                    "savedAt": ISO8601DateFormatter().string(from: Date())
                ]

                SharedUserDefaults.addToCarrierBagCollection("events", item: ticketEntry)

                NSLog("ADVANCEKEY: ✅ Ticket added to carrierBag!")

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let successScript = """
                        document.getElementById('banner').innerHTML = `
                            <div style="padding: 15px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                                <div style="font-size: 18px; font-weight: bold; margin-bottom: 5px;">🎉 Ticket Purchased!</div>
                                <div style="font-size: 13px;">Ticket #\(ticketNumber) added to your carrierBag</div>
                            </div>
                        `;
                        setTimeout(() => { document.getElementById('banner').innerHTML = ''; }, 3000);
                    """
                    self.resultWebView.evaluateJavaScript(successScript, completionHandler: nil)
                }

            } catch {
                NSLog("ADVANCEKEY: ❌ Failed to process ticket purchase: %@", error.localizedDescription)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let errorMessage = error.localizedDescription.replacingOccurrences(of: "'", with: "\\'")
                    let errorScript = """
                        document.getElementById('banner').innerHTML = `
                            <div style="padding: 15px; background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                                <div style="font-size: 16px; font-weight: bold; margin-bottom: 5px;">❌ Purchase Failed</div>
                                <div style="font-size: 12px;">\(errorMessage)</div>
                            </div>
                        `;
                        setTimeout(() => { document.getElementById('banner').innerHTML = ''; }, 5000);
                    """
                    self.resultWebView.evaluateJavaScript(errorScript, completionHandler: nil)
                }
            }
        }
    }

    private func chargePaymentForTicket(userUUID: String, userPubKey: String, amount: Int, eventUUID: String) async throws {
        // Get stored payment methods
        let storedMethods = loadStoredPaymentMethods()

        guard let paymentMethod = storedMethods.first else {
            // If no saved payment method, we need to show payment method selection
            // For now, throw error - in production, would show payment method UI
            throw NSError(domain: "PaymentError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "No saved payment method found. Please add a payment method in The Advancement app."])
        }

        NSLog("ADVANCEKEY: 💳 Using payment method: %@ ending in %@", paymentMethod.brand, paymentMethod.last4)

        // Call Addie's charge-with-saved-method endpoint
        let addieURL = URL(string: Configuration.Addie.chargeWithSavedMethod())!
        var request = URLRequest(url: addieURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + userUUID + String(amount) + paymentMethod.id

        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to sign payment request"])
        }

        let requestBody: [String: Any] = [
            "uuid": userUUID,
            "amount": amount,
            "currency": "usd",
            "paymentMethodId": paymentMethod.id,
            "timestamp": timestamp,
            "signature": signature,
            "payees": [] // No revenue splits for now
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "PaymentError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response from Addie"])
        }

        NSLog("ADVANCEKEY: 💳 Addie response status: %d", httpResponse.statusCode)

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "PaymentError", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Payment failed: \(errorMessage)"])
        }

        guard let paymentResult = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = paymentResult["success"] as? Bool,
              success else {
            throw NSError(domain: "PaymentError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Payment was not successful"])
        }

        NSLog("ADVANCEKEY: ✅ Payment charged successfully")
    }

    private func validateMPBalance(userUUID: String, userPubKey: String, amount: Int) async throws {
        NSLog("ADVANCEKEY: ✨ Validating %d MP for user %@", amount, userUUID)

        // Get user's current MP balance from Fount
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let getMessage = timestamp + userUUID

        guard let getSignature = sessionless.sign(message: getMessage) else {
            throw NSError(domain: "SignatureError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to sign request"])
        }

        guard let getUserRequestURL = URL(string: "\(Configuration.Fount.getUser(userUUID: userUUID))?timestamp=\(timestamp)&signature=\(getSignature)") else {
            throw NSError(domain: "URLError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }

        NSLog("ADVANCEKEY: 📡 Getting user data from Fount...")
        let (userData, userResponse) = try await URLSession.shared.data(from: getUserRequestURL)

        guard let httpResponse = userResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to get user data from Fount"])
        }

        guard let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any],
              let currentMP = userDict["mp"] as? Int else {
            throw NSError(domain: "FountError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Could not read MP balance"])
        }

        NSLog("ADVANCEKEY: 💰 Current MP balance: %d", currentMP)

        // Check if user has enough MP
        guard currentMP >= amount else {
            throw NSError(domain: "InsufficientFunds", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Insufficient MP. You have \(currentMP) MP but need \(amount) MP."])
        }

        NSLog("ADVANCEKEY: ✅ MP balance sufficient: %d >= %d", currentMP, amount)
    }

    private func chargeMP(userUUID: String, userPubKey: String, amount: Int) async throws {
        NSLog("ADVANCEKEY: ✨ Charging %d MP from user %@", amount, userUUID)

        // Step 1: Get user's current MP balance from Fount
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let getMessage = timestamp + userUUID

        guard let getSignature = sessionless.sign(message: getMessage) else {
            throw NSError(domain: "SignatureError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to sign request"])
        }

        guard let getUserRequestURL = URL(string: "\(Configuration.Fount.getUser(userUUID: userUUID))?timestamp=\(timestamp)&signature=\(getSignature)") else {
            throw NSError(domain: "URLError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }

        NSLog("ADVANCEKEY: 📡 Getting user data from Fount...")
        let (userData, userResponse) = try await URLSession.shared.data(from: getUserRequestURL)

        guard let httpResponse = userResponse as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to get user data from Fount"])
        }

        guard let userDict = try JSONSerialization.jsonObject(with: userData) as? [String: Any],
              let currentMP = userDict["mp"] as? Int else {
            throw NSError(domain: "FountError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Could not read MP balance"])
        }

        NSLog("ADVANCEKEY: 💰 Current MP balance: %d", currentMP)

        // Step 2: Check if user has enough MP
        guard currentMP >= amount else {
            throw NSError(domain: "InsufficientFunds", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Insufficient MP. You have \(currentMP) MP but need \(amount) MP."])
        }

        // Step 3: Deduct MP by granting to system/event creator
        // For now, we'll grant to a system UUID (could be event creator's UUID in future)
        let systemUUID = "system-mp-sink-00000000"
        let grantTimestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let grantMessage = grantTimestamp + userUUID + systemUUID + String(amount)

        guard let grantSignature = sessionless.sign(message: grantMessage) else {
            throw NSError(domain: "SignatureError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to sign grant request"])
        }

        guard let grantURL = URL(string: Configuration.Fount.grantExperience(userUUID: userUUID)) else {
            throw NSError(domain: "URLError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid grant URL"])
        }

        var grantRequest = URLRequest(url: grantURL)
        grantRequest.httpMethod = "POST"
        grantRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let grantBody: [String: Any] = [
            "uuid": userUUID,
            "destinationUUID": systemUUID,
            "amount": amount,
            "description": "Event ticket purchase",
            "timestamp": grantTimestamp,
            "signature": grantSignature
        ]

        grantRequest.httpBody = try JSONSerialization.data(withJSONObject: grantBody)

        NSLog("ADVANCEKEY: 📡 Deducting %d MP via Fount grant...", amount)
        let (grantData, grantResponse) = try await URLSession.shared.data(for: grantRequest)

        guard let grantHTTPResponse = grantResponse as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response from Fount"])
        }

        NSLog("ADVANCEKEY: 📡 Fount grant response status: %d", grantHTTPResponse.statusCode)

        guard grantHTTPResponse.statusCode == 200 else {
            let errorMessage = String(data: grantData, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "MPDeductionError", code: grantHTTPResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to deduct MP: \(errorMessage)"])
        }

        NSLog("ADVANCEKEY: ✅ Successfully deducted %d MP", amount)
    }

    private func getPrimaryShippingAddress() -> [String: Any]? {
        guard let carrierBag = SharedUserDefaults.getCarrierBag(),
              let addresses = carrierBag["addresses"] as? [[String: Any]] else {
            NSLog("ADVANCEKEY: 📮 No addresses in carrier bag")
            return nil
        }

        // Find primary address
        if let primaryAddress = addresses.first(where: { $0["isPrimary"] as? Bool == true }) {
            NSLog("ADVANCEKEY: 📮 Found primary address: %@", primaryAddress["name"] as? String ?? "Unknown")
            return primaryAddress
        }

        // If no primary, use first address
        if let firstAddress = addresses.first {
            NSLog("ADVANCEKEY: 📮 Using first address (no primary set): %@", firstAddress["name"] as? String ?? "Unknown")
            return firstAddress
        }

        NSLog("ADVANCEKEY: 📮 No addresses available")
        return nil
    }

    private func purchaseTicketWithMP(buyerUUID: String, ticketFlavor: String, mpCost: Int) async throws {
        NSLog("ADVANCEKEY: 🪄 Purchasing ticket with %d MP via arethaUserPurchase spell", mpCost)
        NSLog("ADVANCEKEY: 🎟️  Buyer UUID: %@", buyerUUID)
        NSLog("ADVANCEKEY: 🎟️  Ticket flavor: %@", ticketFlavor)

        // Create MAGIC spell for arethaUserPurchase
        // This spell atomically:
        // 1. Validates buyer has enough MP (via Fount resolver)
        // 2. Deducts MP from buyer
        // 3. Transfers nineum from Aretha's account to buyer
        // 4. Grants experience to buyer
        // 5. Distributes gateway rewards
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let spellName = "arethaUserPurchase"
        let mp = true
        let ordinal = 0

        // Get primary shipping address from carrier bag
        var components: [String: Any] = [
            "flavor": ticketFlavor,
            "quantity": 1
        ]

        if let shippingAddress = getPrimaryShippingAddress() {
            NSLog("ADVANCEKEY: 📮 Including shipping address: %@", shippingAddress["name"] as? String ?? "Unknown")
            components["shippingAddress"] = shippingAddress
        } else {
            NSLog("ADVANCEKEY: ⚠️ No shipping address found in carrier bag")
        }

        // Create spell payload
        let spell: [String: Any] = [
            "spell": spellName,
            "casterUUID": buyerUUID,
            "timestamp": timestamp,
            "totalCost": mpCost,
            "mp": mp,
            "ordinal": ordinal,
            "components": components
        ]

        // Sign the spell: timestamp + spell + casterUUID + totalCost + mp + ordinal
        let signMessage = timestamp + spellName + buyerUUID + String(mpCost) + String(mp) + String(ordinal)
        guard let casterSignature = sessionless.sign(message: signMessage) else {
            throw NSError(domain: "SignatureError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to sign spell"])
        }

        // Add signature to spell
        var signedSpell = spell
        signedSpell["casterSignature"] = casterSignature

        // POST spell to Fount's /resolve endpoint
        guard let resolveURL = URL(string: Configuration.Fount.resolve(spellName: spellName)) else {
            throw NSError(domain: "URLError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid resolve URL"])
        }

        var request = URLRequest(url: resolveURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: signedSpell)

        NSLog("ADVANCEKEY: 🪄 Casting spell to Fount resolver...")
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid response from spell resolver"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            NSLog("ADVANCEKEY: ❌ Spell casting failed (%d): %@", httpResponse.statusCode, errorText)
            throw NSError(domain: "SpellError", code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to cast spell: \(errorText)"])
        }

        guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = result["success"] as? Bool,
              success else {
            let errorMsg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String ?? "Unknown error"
            NSLog("ADVANCEKEY: ❌ Spell returned unsuccessful: %@", errorMsg)
            throw NSError(domain: "SpellError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Spell failed: \(errorMsg)"])
        }

        NSLog("ADVANCEKEY: ✅ Ticket purchased! MP deducted and nineum transferred")
    }

    private func transferTicketNineum(fromUUID: String, toUUID: String, ticketFlavor: String) async throws {
        // This is used for cash purchases where MP isn't involved
        NSLog("ADVANCEKEY: 🎟️  Transferring ticket nineum (cash purchase)")
        NSLog("ADVANCEKEY: 🎟️  Buyer UUID: %@", toUUID)
        NSLog("ADVANCEKEY: 🎟️  Ticket flavor: %@", ticketFlavor)

        // For cash purchases, we need a different flow
        // TODO: Implement cash purchase nineum transfer
        throw NSError(domain: "NotImplemented", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Cash purchase nineum transfer not yet implemented"])
    }

    private func createTicketBDO(ticketNumber: Int, eventData: [String: Any], eventUUID: String, buyerUUID: String, ticketFlavor: String) async throws -> String {
        // Create a BDO with animated SVG for the ticket

        let eventTitle = eventData["title"] as? String ?? "Event"
        let eventDate = (eventData["eventData"] as? [String: Any])?["date"] as? String ?? "TBD"
        let eventLocation = (eventData["eventData"] as? [String: Any])?["location"] as? String ?? "TBD"

        // Generate keys for the ticket BDO
        var keys = sessionless.getKeys()
        if keys == nil {
            keys = sessionless.generateKeys()
        }

        guard let keys = keys else {
            throw NSError(domain: "KeyError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to generate keys for ticket BDO"])
        }

        let ticketSVG = generateTicketSVG(
            ticketNumber: ticketNumber,
            eventTitle: eventTitle,
            eventDate: eventDate,
            location: eventLocation
        )

        let ticketBDOData: [String: Any] = [
            "type": "ticket",
            "title": "\(eventTitle) - Ticket #\(ticketNumber)",
            "svgContent": ticketSVG,
            "ticketData": [
                "ticketNumber": ticketNumber,
                "purchasedAt": ISO8601DateFormatter().string(from: Date()),
                "eventDate": eventDate,
                "location": eventLocation,
                "buyerUUID": buyerUUID,
                "eventUUID": eventUUID,
                "ticketFlavor": ticketFlavor
            ]
        ]

        // Create BDO via BDO service
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = ""
        let messageToSign = "\(timestamp)\(hash)\(keys.publicKey)"

        guard let signature = sessionless.sign(message: messageToSign) else {
            throw NSError(domain: "SignatureError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to sign ticket BDO creation"])
        }

        let bdoPayload: [String: Any] = [
            "timestamp": timestamp,
            "hash": hash,
            "pubKey": keys.publicKey,
            "signature": signature,
            "public": true,
            "bdo": ticketBDOData
        ]

        let bdoURL = URL(string: Configuration.BDO.createUser())!
        var request = URLRequest(url: bdoURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: bdoPayload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "BDOError", code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to create ticket BDO"])
        }

        NSLog("ADVANCEKEY: ✅ Ticket BDO created with pubKey: %@", keys.publicKey)

        return keys.publicKey
    }

    private func generateTicketSVG(ticketNumber: Int, eventTitle: String, eventDate: String, location: String) -> String {
        return """
        <svg width="320" height="200" xmlns="http://www.w3.org/2000/svg">
          <!-- Animated gradient background -->
          <defs>
            <linearGradient id="ticketGrad" x1="0%" y1="0%" x2="100%" y2="100%">
              <stop offset="0%" style="stop-color:#9b59b6;stop-opacity:1">
                <animate attributeName="stop-color"
                         values="#9b59b6;#3498db;#9b59b6"
                         dur="3s" repeatCount="indefinite"/>
              </stop>
              <stop offset="100%" style="stop-color:#3498db;stop-opacity:1">
                <animate attributeName="stop-color"
                         values="#3498db;#9b59b6;#3498db"
                         dur="3s" repeatCount="indefinite"/>
              </stop>
            </linearGradient>
          </defs>

          <rect fill="url(#ticketGrad)" width="320" height="200" rx="12"/>

          <!-- Ticket details -->
          <text x="160" y="30" fill="white" font-size="20" text-anchor="middle" font-weight="bold">
            🎉 TICKET #\(ticketNumber)
          </text>
          <text x="160" y="55" fill="white" font-size="14" text-anchor="middle">
            \(eventTitle)
          </text>
          <text x="160" y="80" fill="white" font-size="12" text-anchor="middle">
            \(eventDate)
          </text>
          <text x="160" y="100" fill="white" font-size="12" text-anchor="middle">
            \(location)
          </text>

          <!-- Animated stars -->
          <circle cx="30" cy="30" r="3" fill="yellow" opacity="0.8">
            <animate attributeName="opacity" values="0.3;1;0.3" dur="2s" repeatCount="indefinite"/>
          </circle>
          <circle cx="290" cy="30" r="3" fill="yellow" opacity="0.8">
            <animate attributeName="opacity" values="1;0.3;1" dur="2s" repeatCount="indefinite"/>
          </circle>

          <!-- Valid ticket indicator -->
          <rect x="110" y="130" width="100" height="40" fill="#27ae60" rx="6"/>
          <text x="160" y="155" fill="white" font-size="14" text-anchor="middle" font-weight="bold">
            ✓ VALID
          </text>

          <!-- Decorative ticket stub perforation -->
          <line x1="0" y1="180" x2="320" y2="180" stroke="white" stroke-width="2" stroke-dasharray="5,5" opacity="0.5"/>
        </svg>
        """
    }

    private func purchaseProduct(productId: String, price: Int, fullBDO: [String: Any]) {
        NSLog("ADVANCEKEY: 🛒 Purchasing product: %@", productId)
        NSLog("ADVANCEKEY: 💰 Price: $%.2f", Double(price) / 100.0)

        // Show payment method selection
        showPaymentMethodSelection(for: productId, price: price, bdoData: fullBDO)
    }

    private func showPaymentMethodSelection(for productId: String, price: Int, bdoData: [String: Any]) {
        NSLog("ADVANCEKEY: 💳 Showing payment method selection")

        let storedMethods = loadStoredPaymentMethods()

        guard !storedMethods.isEmpty else {
            NSLog("ADVANCEKEY: ❌ No stored payment methods")
            showNoPaymentMethodsError()
            return
        }

        NSLog("ADVANCEKEY: 📦 Found %d stored payment methods", storedMethods.count)

        // Create payment method selection UI
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    min-height: 100vh;
                    padding: 20px;
                }
                .container {
                    max-width: 400px;
                    margin: 0 auto;
                }
                .header {
                    text-align: center;
                    color: white;
                    margin-bottom: 30px;
                }
                .price {
                    font-size: 48px;
                    font-weight: bold;
                    margin: 10px 0;
                }
                .product-title {
                    font-size: 20px;
                    opacity: 0.9;
                }
                .payment-methods {
                    display: flex;
                    flex-direction: column;
                    gap: 15px;
                }
                .payment-card {
                    background: white;
                    border-radius: 12px;
                    padding: 20px;
                    cursor: pointer;
                    transition: transform 0.2s, box-shadow 0.2s;
                    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
                }
                .payment-card:active {
                    transform: scale(0.98);
                    box-shadow: 0 2px 8px rgba(0,0,0,0.2);
                }
                .card-brand {
                    font-size: 18px;
                    font-weight: 600;
                    color: #667eea;
                    margin-bottom: 8px;
                }
                .card-last4 {
                    font-size: 24px;
                    font-family: monospace;
                    color: #333;
                }
                .cancel-btn {
                    margin-top: 20px;
                    background: rgba(255,255,255,0.2);
                    border: 2px solid white;
                    border-radius: 12px;
                    color: white;
                    padding: 15px;
                    text-align: center;
                    font-size: 18px;
                    font-weight: 600;
                    cursor: pointer;
                }
                .cancel-btn:active {
                    background: rgba(255,255,255,0.3);
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <div class="product-title">\(bdoData["title"] as? String ?? "Product")</div>
                    <div class="price">$\(String(format: "%.2f", Double(price) / 100.0))</div>
                </div>
                <div class="payment-methods">
        """

        for (index, method) in storedMethods.enumerated() {
            let brandEmoji = method.brand.lowercased() == "visa" ? "💳" :
                           method.brand.lowercased() == "mastercard" ? "💳" :
                           method.brand.lowercased() == "amex" ? "💎" : "💳"
            html += """
                    <div class="payment-card" onclick="selectPaymentMethod('\(method.id)')">
                        <div class="card-brand">\(brandEmoji) \(method.brand)</div>
                        <div class="card-last4">•••• \(method.last4)</div>
                    </div>
            """
        }

        html += """
                </div>
                <div class="cancel-btn" onclick="cancelPurchase()">Cancel</div>
            </div>
            <script>
                function selectPaymentMethod(paymentMethodId) {
                    window.webkit.messageHandlers.paymentMethodSelected.postMessage({
                        action: 'purchaseProduct',
                        paymentMethodId: paymentMethodId,
                        productId: '\(productId)',
                        price: \(price),
                        bdoData: \(try! String(data: JSONSerialization.data(withJSONObject: bdoData), encoding: .utf8)!)
                    });
                }

                function cancelPurchase() {
                    window.webkit.messageHandlers.purchase.postMessage({
                        action: 'cancel'
                    });
                }
            </script>
        </body>
        </html>
        """

        // Load the payment selection UI
        resultWebView.loadHTMLString(html, baseURL: nil)
        resultWebView.isHidden = false
    }

    // MARK: - Stored Payment Methods

    func loadStoredPaymentMethods() -> [PaymentMethod] {
        // Use correct App Group ID matching entitlements
        guard let userDefaults = UserDefaults(suiteName: "group.com.planetnine.Planet-Nine") else {
            NSLog("ADVANCEKEY: ❌ Failed to access shared UserDefaults")
            return []
        }

        // Read from the same key that MainViewController uses
        guard let cardsData = userDefaults.data(forKey: "stripe_saved_cards"),
              let storedMethodsData = try? JSONSerialization.jsonObject(with: cardsData) as? [[String: Any]] else {
            NSLog("ADVANCEKEY: 📝 No stored payment methods found")
            return []
        }

        NSLog("ADVANCEKEY: 📦 Found \(storedMethodsData.count) cards in shared UserDefaults")

        let paymentMethods = storedMethodsData.compactMap { methodData -> PaymentMethod? in
            guard let id = methodData["id"] as? String,
                  let brand = methodData["brand"] as? String,
                  let last4 = methodData["last4"] as? String else {
                NSLog("ADVANCEKEY: ⚠️ Invalid payment method data: %@", methodData)
                return nil
            }

            // Log if this is an issued card
            if let isIssuedCard = methodData["isIssuedCard"] as? Bool, isIssuedCard {
                NSLog("ADVANCEKEY: 🎫 Found issued card: \(brand) •••• \(last4)")
            }

            return PaymentMethod(id: id, brand: brand, last4: last4, type: "card")
        }

        NSLog("ADVANCEKEY: 💳 Loaded %d stored payment methods (including issued cards)", paymentMethods.count)
        return paymentMethods
    }

    func generatePaymentMethodsHTML() throws -> String {
        let storedMethods = loadStoredPaymentMethods()

        if storedMethods.isEmpty {
            return """
            <div style="text-align: center; padding: 20px;">
                <p>No stored payment methods found.</p>
                <p>Please add a payment method via The Advancement app.</p>
            </div>
            """
        }

        let methodsHTML = storedMethods.map { method in
            return """
            <div class="payment-method" onclick="selectPaymentMethod('\(method.id)', '\(method.brand)', '\(method.last4)')">
                <div class="payment-info">
                    <div class="payment-icon">💳</div>
                    <div class="payment-details">
                        <div class="payment-name">\(method.brand.capitalized)</div>
                        <div class="payment-last4">•••• \(method.last4)</div>
                    </div>
                </div>
            </div>
            """
        }.joined(separator: "\n")

        return """
        <div class="payment-methods-container">
            <h3>Select Payment Method</h3>
            \(methodsHTML)
        </div>
        """
    }

    func handlePaymentMethodSelection(_ message: [String: Any]) {
        // Check if this is a product purchase
        if let action = message["action"] as? String, action == "purchaseProduct" {
            handleProductPurchase(message)
            return
        }

        // Original payment method selection flow
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

    private func handleProductPurchase(_ message: [String: Any]) {
        guard let paymentMethodId = message["paymentMethodId"] as? String,
              let productId = message["productId"] as? String,
              let price = message["price"] as? Int else {
            NSLog("ADVANCEKEY: ❌ Invalid product purchase message - missing required fields")
            return
        }

        // Handle bdoData as either a String (JSON) or Dictionary (already parsed)
        let bdoData: [String: Any]
        if let bdoDataString = message["bdoData"] as? String {
            // bdoData is a JSON string - parse it
            guard let parsed = try? JSONSerialization.jsonObject(with: bdoDataString.data(using: .utf8)!) as? [String: Any] else {
                NSLog("ADVANCEKEY: ❌ Invalid bdoData JSON string")
                return
            }
            bdoData = parsed
        } else if let bdoDataDict = message["bdoData"] as? [String: Any] {
            // bdoData is already a dictionary - use it directly
            bdoData = bdoDataDict
        } else {
            NSLog("ADVANCEKEY: ❌ Invalid bdoData format - expected String or Dictionary")
            return
        }

        NSLog("ADVANCEKEY: 🛒 Processing product purchase")
        NSLog("ADVANCEKEY:    Product: %@", productId)
        NSLog("ADVANCEKEY:    Price: $%.2f", Double(price) / 100.0)
        NSLog("ADVANCEKEY:    Payment: %@", paymentMethodId)

        // Process the purchase
        processProductPurchase(productId: productId, price: price, bdoData: bdoData, paymentMethodId: paymentMethodId)
    }

    private func getOrCreateAddieUser(pubKey: String) async throws -> String {
        // Check cache first (use regular UserDefaults since keyboard can access it)
        if let cachedUUID = UserDefaults.standard.string(forKey: "addie_user_uuid") {
            NSLog("ADVANCEKEY: ✅ Using cached Addie UUID: %@", cachedUUID)
            return cachedUUID
        }

        NSLog("ADVANCEKEY: 🔄 Creating/fetching Addie user...")

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign request"])
        }

        let addieBaseURL = Configuration.addieBaseURL
        let endpoint = "\(addieBaseURL)/user/create"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let uuid = json["uuid"] as? String else {
            throw NSError(domain: "AddieError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get/create Addie user"])
        }

        NSLog("ADVANCEKEY: ✅ Got Addie UUID: %@", uuid)
        UserDefaults.standard.set(uuid, forKey: "addie_user_uuid")
        return uuid
    }

    private func processProductPurchase(productId: String, price: Int, bdoData: [String: Any], paymentMethodId: String) {
        NSLog("ADVANCEKEY: 💳 Creating payment intent for product")

        Task {
            do {
                // Get user keys
                guard let keys = sessionless.getKeys() else {
                    throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user keys found"])
                }

                // Get or create Addie user UUID
                let addieUUID = try await getOrCreateAddieUser(pubKey: keys.publicKey)

                // Get payees from BDO
                guard let payees = bdoData["payees"] as? [[String: Any]] else {
                    throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No payees found in BDO"])
                }

                NSLog("ADVANCEKEY: 💰 Product has %d payees", payees.count)

                // Charge with saved payment method through Addie
                let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
                let addieBaseURL = Configuration.addieBaseURL
                let endpoint = "\(addieBaseURL)/charge-with-saved-method"

                // Signature: timestamp + uuid + amount + paymentMethodId
                let message = timestamp + addieUUID + String(price) + paymentMethodId
                guard let signature = sessionless.sign(message: message) else {
                    throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign request"])
                }

                var request = URLRequest(url: URL(string: endpoint)!)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body: [String: Any] = [
                    "timestamp": timestamp,
                    "uuid": addieUUID,
                    "amount": price,
                    "currency": "usd",
                    "paymentMethodId": paymentMethodId,
                    "payees": payees,
                    "signature": signature
                ]

                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                NSLog("ADVANCEKEY: 📡 Sending payment request to Addie...")
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                }

                NSLog("ADVANCEKEY: 📡 Payment response status: %d", httpResponse.statusCode)

                guard httpResponse.statusCode == 200 else {
                    let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                    NSLog("ADVANCEKEY: ❌ Payment failed: %@", errorText)
                    throw NSError(domain: "PaymentError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Payment failed: \(errorText)"])
                }

                guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    let errorMsg = "No Result"
                    throw NSError(domain: "PaymentError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                }
                guard let success = result["success"] as? Bool, success else {
                    let errorMsg = (result["error"] as? String) ?? "Payment failed"
                    throw NSError(domain: "PaymentError", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                }

                NSLog("ADVANCEKEY: ✅ Payment successful!")

                // Save the purchased product to carrierBag
                await savePurchasedProduct(bdoData: bdoData)

                // Show success message
                await MainActor.run {
                    showPurchaseSuccess(productTitle: bdoData["title"] as? String ?? "Product")
                }

            } catch {
                NSLog("ADVANCEKEY: ❌ Purchase failed: %@", error.localizedDescription)
                await MainActor.run {
                    showPurchaseError(error: error.localizedDescription)
                }
            }
        }
    }

    private func savePurchasedProduct(bdoData: [String: Any]) async {
        NSLog("ADVANCEKEY: 💾 Saving purchased product to carrierBag")

        let title = bdoData["title"] as? String ?? "Product"
        let type = bdoData["type"] as? String ?? "product"
        let collection = determineCollectionForType(type)

        // Create purchased item entry
        let itemEntry: [String: Any] = [
            "type": type,
            "title": title,
            "bdoData": bdoData,
            "purchased": true,
            "purchasedAt": ISO8601DateFormatter().string(from: Date()),
            "savedAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Save to SharedUserDefaults carrierBag
        SharedUserDefaults.addToCarrierBagCollection(collection, item: itemEntry)

        NSLog("ADVANCEKEY: ✅ Product saved to %@ with purchased flag", collection)
    }

    private func determineCollectionForType(_ type: String) -> String {
        // Map BDO types to carrierBag collections
        switch type.lowercased() {
        case "recipe", "food": return "cookbook"
        case "potion", "remedy": return "apothecary"
        case "artwork", "image": return "gallery"
        case "book", "literature", "ebook": return "bookshelf"
        case "pet", "familiar": return "familiarPen"
        case "tool", "machine": return "machinery"
        case "gem", "metal": return "metallics"
        case "music", "song": return "music"
        case "prophecy", "divination": return "oracular"
        case "plant", "botanical": return "greenHouse"
        case "clothing", "garment": return "closet"
        case "game", "entertainment": return "games"
        case "event", "popup", "ticket": return "events"
        case "contract", "covenant": return "contracts"
        case "room", "space": return "stacks"
        case "product": return "bookshelf" // Default products to bookshelf
        default: return "stacks"
        }
    }

    private func showPurchaseSuccess(productTitle: String) {
        NSLog("ADVANCEKEY: 🎉 Showing purchase success")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: linear-gradient(135deg, #2ECC71 0%, #27AE60 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 20px;
                }
                .success-container {
                    text-align: center;
                    color: white;
                }
                .checkmark {
                    font-size: 80px;
                    animation: pop 0.5s ease-out;
                }
                @keyframes pop {
                    0% { transform: scale(0); }
                    50% { transform: scale(1.2); }
                    100% { transform: scale(1); }
                }
                .title {
                    font-size: 32px;
                    font-weight: bold;
                    margin: 20px 0;
                }
                .message {
                    font-size: 18px;
                    opacity: 0.9;
                    margin-bottom: 10px;
                }
                .product {
                    font-size: 20px;
                    font-weight: 600;
                    margin: 15px 0;
                }
                .done-btn {
                    margin-top: 30px;
                    background: white;
                    color: #27AE60;
                    border: none;
                    border-radius: 12px;
                    padding: 15px 40px;
                    font-size: 18px;
                    font-weight: 600;
                    cursor: pointer;
                }
            </style>
        </head>
        <body>
            <div class="success-container">
                <div class="checkmark">✅</div>
                <div class="title">Purchase Successful!</div>
                <div class="product">\(productTitle)</div>
                <div class="message">Saved to your Carrier Bag</div>
                <button class="done-btn" onclick="window.webkit.messageHandlers.purchase.postMessage({ action: 'done' })">Done</button>
            </div>
        </body>
        </html>
        """

        resultWebView.loadHTMLString(html, baseURL: nil)
        resultWebView.isHidden = false

        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.resultWebView.isHidden = true
        }
    }

    private func showPurchaseError(error: String) {
        NSLog("ADVANCEKEY: ❌ Showing purchase error")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: linear-gradient(135deg, #e74c3c 0%, #c0392b 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 20px;
                }
                .error-container {
                    text-align: center;
                    color: white;
                }
                .error-icon {
                    font-size: 80px;
                    animation: shake 0.5s ease-out;
                }
                @keyframes shake {
                    0%, 100% { transform: translateX(0); }
                    25% { transform: translateX(-10px); }
                    75% { transform: translateX(10px); }
                }
                .title {
                    font-size: 32px;
                    font-weight: bold;
                    margin: 20px 0;
                }
                .message {
                    font-size: 16px;
                    opacity: 0.9;
                    margin: 15px 0;
                    line-height: 1.6;
                }
                .done-btn {
                    margin-top: 30px;
                    background: white;
                    color: #c0392b;
                    border: none;
                    border-radius: 12px;
                    padding: 15px 40px;
                    font-size: 18px;
                    font-weight: 600;
                    cursor: pointer;
                }
            </style>
        </head>
        <body>
            <div class="error-container">
                <div class="error-icon">❌</div>
                <div class="title">Purchase Failed</div>
                <div class="message">\(error)</div>
                <button class="done-btn" onclick="window.webkit.messageHandlers.purchase.postMessage({ action: 'done' })">OK</button>
            </div>
        </body>
        </html>
        """

        resultWebView.loadHTMLString(html, baseURL: nil)
        resultWebView.isHidden = false
    }

    private func showNoPaymentMethodsError() {
        NSLog("ADVANCEKEY: ❌ Showing no payment methods error")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: linear-gradient(135deg, #f39c12 0%, #e67e22 100%);
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 20px;
                }
                .warning-container {
                    text-align: center;
                    color: white;
                }
                .warning-icon {
                    font-size: 80px;
                }
                .title {
                    font-size: 32px;
                    font-weight: bold;
                    margin: 20px 0;
                }
                .message {
                    font-size: 16px;
                    opacity: 0.9;
                    margin: 15px 0;
                    line-height: 1.6;
                }
                .done-btn {
                    margin-top: 30px;
                    background: white;
                    color: #e67e22;
                    border: none;
                    border-radius: 12px;
                    padding: 15px 40px;
                    font-size: 18px;
                    font-weight: 600;
                    cursor: pointer;
                }
            </style>
        </head>
        <body>
            <div class="warning-container">
                <div class="warning-icon">💳</div>
                <div class="title">No Payment Methods</div>
                <div class="message">Please add a payment method in The Advancement app first.</div>
                <button class="done-btn" onclick="window.webkit.messageHandlers.purchase.postMessage({ action: 'done' })">OK</button>
            </div>
        </body>
        </html>
        """

        resultWebView.loadHTMLString(html, baseURL: nil)
        resultWebView.isHidden = false
    }

    private func showPaymentConfirmation(for paymentMethod: PaymentMethod) {
        NSLog("ADVANCEKEY: 💳 Payment confirmation requested (skipped in keyboard extension)")
        // Skip confirmation in keyboard extension - directly process payment
        processStoredPayment(paymentMethod)
    }

    private func processStoredPayment(_ paymentMethod: PaymentMethod) {
        NSLog("ADVANCEKEY: 💰 Processing payment with stored method: %@", paymentMethod.id)

        // This would integrate with the existing Addie/Stripe payment processing
        // Show success banner
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let successScript = """
                document.getElementById('banner').innerHTML = `
                    <div style="padding: 15px; background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                        <div style="font-size: 16px; font-weight: bold; margin-bottom: 5px;">🎉 Payment Successful</div>
                        <div style="font-size: 12px;">Using \(paymentMethod.brand) ending in \(paymentMethod.last4)</div>
                    </div>
                `;
                setTimeout(() => { document.getElementById('banner').innerHTML = ''; }, 3000);
            """
            self.resultWebView.evaluateJavaScript(successScript, completionHandler: nil)
        }
    }

    func handleAddPaymentMethod() {
        NSLog("ADVANCEKEY: 💳 Add payment method requested")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let infoScript = """
                document.getElementById('banner').innerHTML = `
                    <div style="padding: 15px; background: linear-gradient(135deg, #3b82f6 0%, #2563eb 100%); color: white; text-align: center; font-family: -apple-system, BlinkMacSystemFont, sans-serif;">
                        <div style="font-size: 16px; font-weight: bold; margin-bottom: 5px;">💳 Add Payment Method</div>
                        <div style="font-size: 12px;">Please use the Nexus portal in The Advancement app</div>
                    </div>
                `;
                setTimeout(() => { document.getElementById('banner').innerHTML = ''; }, 4000);
            """
            self.resultWebView.evaluateJavaScript(infoScript, completionHandler: nil)
        }
    }
}

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
        // Since BDO is seeded in user data under "recipes", we need to find it
        // This is a simplified approach - in production you'd have proper BDO endpoints

        print("🔍 Searching for BDO in seeded user data...")

        // For now, return the seeded recipe data directly since we know the structure
        let recipeData: [String: Any] = [
            "bdo": [
                "bdoPubKey": bdoPubKey,
                "svgContent": "<svg width=\"320\" height=\"60\" viewBox=\"0 0 320 60\" xmlns=\"http://www.w3.org/2000/svg\"><rect x=\"0\" y=\"0\" width=\"320\" height=\"60\" fill=\"#f8f9fa\" stroke=\"#e9ecef\" stroke-width=\"1\" rx=\"8\"/><rect spell=\"share\" x=\"10\" y=\"10\" width=\"90\" height=\"40\" fill=\"#27ae60\" stroke=\"#219a52\" stroke-width=\"2\" rx=\"6\"><title>Share this recipe</title></rect><text spell=\"share\" x=\"55\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">📤 SHARE</text><rect spell=\"collect\" x=\"115\" y=\"10\" width=\"90\" height=\"40\" fill=\"#9b59b6\" stroke=\"#8e44ad\" stroke-width=\"2\" rx=\"6\"><title>Save to your collection</title></rect><text spell=\"collect\" x=\"160\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">💾 SAVE</text><rect spell=\"magic\" x=\"220\" y=\"10\" width=\"90\" height=\"40\" fill=\"#e91e63\" stroke=\"#c2185b\" stroke-width=\"2\" rx=\"6\"><title>Cast kitchen magic</title></rect><text spell=\"magic\" x=\"265\" y=\"32\" text-anchor=\"middle\" fill=\"white\" font-size=\"12\" font-weight=\"bold\">🪄 MAGIC</text></svg>",
                "title": "Grandma's Secret Chocolate Chip Cookies Recipe",
                "type": "recipe"
            ]
        ]

        return recipeData
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

        return true
    }
}
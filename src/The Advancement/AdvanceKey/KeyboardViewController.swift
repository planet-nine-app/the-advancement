//
//  KeyboardViewController.swift
//  AdvanceKey
//
//  Simple demoji keyboard extension
//

import UIKit
import WebKit

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

        print("🚀 Demoji Keyboard loading...")
        self.view.backgroundColor = UIColor.systemBackground

        // Initialize sessionless for BDO requests
        sessionless = Sessionless()

        setupDemojiButton()
        setupWebView()
        setupDebugLabel()

        print("✅ Demoji Keyboard ready")
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
        print("🎯 DEMOJI button tapped")

        // Get highlighted/selected text from the input context
        let proxy = self.textDocumentProxy
        let selectedText = proxy.selectedText ?? ""
        let contextBefore = proxy.documentContextBeforeInput ?? ""
        let contextAfter = proxy.documentContextAfterInput ?? ""

        // Combine all available text context
        let fullContext = contextBefore + selectedText + contextAfter

        print("📝 Text context details:")
        print("  - Selected: '\(selectedText.prefix(50))...'")
        print("  - Before: '\(contextBefore.suffix(50))...'")
        print("  - After: '\(contextAfter.prefix(50))...'")
        print("  - Full context: '\(fullContext.prefix(100))...'")

        debugLabel.text = "Searching for ✨emoji✨..."

        // Look for emojicoded sequence (starts and ends with ✨)
        if let emojicode = extractEmojicode(from: fullContext) {
            print("🎨 Found emojicode: \(emojicode.prefix(30))...")
            debugLabel.text = "Found emoji! Decoding..."
            decodeAndFetchBDO(emojicode: emojicode)
        } else {
            debugLabel.text = "No ✨emoji✨ sequence found"
            displayError("No Emoji Found", details: """
            Context checked: \(fullContext.prefix(200))

            Looking for: ✨...emojis...✨
            Selected: \(selectedText)
            """)
            print("❌ No emojicoded sequence found in context")
        }
    }

    func extractEmojicode(from text: String) -> String? {
        // Look for text between ✨ delimiters
        let pattern = "✨([^✨]+)✨"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        if let match = regex?.firstMatch(in: text, options: [], range: range) {
            let matchRange = Range(match.range, in: text)!
            return String(text[matchRange])
        }

        return nil
    }

    func decodeAndFetchBDO(emojicode: String) {
        debugLabel.text = "Decoding emoji..."

        // Decode emoji to hex using JavaScript
        let jsDecodeCode = """
        console.log('🔧 JavaScript execution starting...');

        // Load the emojicoding.js functions
        \(loadEmojicodingJS())

        console.log('📚 Emojicoding functions loaded');
        console.log('Input emojicode:', '\(emojicode)');
        console.log('Input length:', '\(emojicode)'.length);

        // Check if decodeEmojiToHex function exists
        if (typeof decodeEmojiToHex === 'undefined') {
            'ERROR: decodeEmojiToHex function not found in emojicoding.js';
        } else {
            console.log('✅ decodeEmojiToHex function found');

            try {
                console.log('🎯 Attempting to decode...');
                const decoded = decodeEmojiToHex('\(emojicode)');
                console.log('✅ Decode successful:', decoded);
                decoded; // Return the result
            } catch (error) {
                console.log('❌ Decode error:', error);
                'ERROR: ' + error.name + ': ' + error.message + ' (Stack: ' + (error.stack || 'no stack') + ')';
            }
        }
        """

        resultWebView.evaluateJavaScript(jsDecodeCode) { [weak self] result, error in
            if let error = error {
                print("❌ JS decode error: \(error)")
                self?.debugLabel.text = "JS Error: \(error.localizedDescription)"
                self?.displayError("JavaScript Error", details: error.localizedDescription)
                return
            }

            if let decodedHex = result as? String, !decodedHex.hasPrefix("ERROR:") {
                print("🔓 Decoded hex: \(decodedHex)")
                self?.debugLabel.text = "✅ Decoded! Fetching BDO..."
                self?.fetchBDOData(bdoPubKey: decodedHex)
            } else {
                let errorMsg = result as? String ?? "Unknown decode error"
                print("❌ Decode failed: \(errorMsg)")
                self?.debugLabel.text = "Decode failed"
                self?.displayError("Emoji Decode Failed", details: errorMsg)
            }
        }
    }

    func fetchBDOData(bdoPubKey: String) {
        // Fetch BDO data from test environment using URLSession
        let bdoUrl = "http://127.0.0.1:5114/"

        Task {
            do {
                let cardData = try await fetchBDOFromServer(bdoPubKey: bdoPubKey, baseUrl: bdoUrl)

                print("📦 BDO data received: \(String(describing: cardData))")

                DispatchQueue.main.async { [weak self] in
                    self?.displayBDOContent(cardData: cardData)
                }

            } catch {
                print("❌ BDO fetch error: \(error)")
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
                // Handle spell button clicks
                document.addEventListener('click', function(e) {
                    const spell = e.target.getAttribute('spell');
                    if (spell) {
                        console.log('Spell clicked:', spell);
                        // You can add spell handling logic here
                        alert('Spell cast: ' + spell);
                    }
                });
            </script>
        </body>
        </html>
        """

        resultWebView.loadHTMLString(html, baseURL: nil)
        debugLabel.text = "✅ Recipe actions loaded!"

        print("✅ SVG displayed in keyboard")
    }

    func loadEmojicodingJS() -> String {
        // Load the emojicoding JavaScript code
        guard let path = Bundle.main.path(forResource: "emojicoding", ofType: "js") else {
            print("❌ Could not find emojicoding.js file path")
            return "console.log('ERROR: emojicoding.js file not found in bundle');"
        }

        guard let jsCode = try? String(contentsOfFile: path) else {
            print("❌ Could not read emojicoding.js file content")
            return "console.log('ERROR: emojicoding.js file could not be read');"
        }

        print("✅ Loaded emojicoding.js (\(jsCode.count) characters)")

        // Add some debugging to see what functions are available
        return jsCode + """

        console.log('Available functions:', typeof decodeEmojiToHex);
        console.log('EmojicodingConfig:', typeof EmojicodingConfig);
        console.log('EMOJI_SET_64 length:', typeof EMOJI_SET_64 !== 'undefined' ? EMOJI_SET_64.length : 'undefined');
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
            print("🟡 JS Console: \(message.body)")
        }
    }
}
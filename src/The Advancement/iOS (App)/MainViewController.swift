//
//  MainViewController.swift
//  The Advancement
//
//  Main app screen with SVG-based WebView interface
//

import UIKit
import WebKit

class MainViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private var webView: WKWebView!
    private var postedBDOs: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Make view extend to full screen
        view.backgroundColor = .black

        setupWebView()
        loadMainPage()
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    private func setupWebView() {
        // Configure WKWebView
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "mainApp")
        configuration.userContentController.add(self, name: "console")

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(webView)
    }

    private func loadMainPage() {
        let html = getMainHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func getMainHTML() -> String {
        return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; -webkit-user-select: none; -webkit-user-drag: none; }
        html, body { width: 100%; min-height: 100%; overflow-x: hidden; background-color: #000000; }
        #mainSVG { width: 100vw; min-height: 100vh; display: block; }
        .button-group { cursor: pointer; }
        .button-group:active rect { fill: rgba(16, 185, 129, 0.3); }
        input { -webkit-user-select: text; }
    </style>
</head>
<body>
    <svg id="mainSVG" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 140" preserveAspectRatio="xMidYMin meet">
        <defs>
            <filter id="greenGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.8" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <filter id="purpleGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.5" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <filter id="pinkGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.6" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <filter id="yellowGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.4" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <radialGradient id="bgGradient" cx="50%" cy="50%" r="70%">
                <stop offset="0%" style="stop-color:#1a0033; stop-opacity:1" />
                <stop offset="100%" style="stop-color:#000000; stop-opacity:1" />
            </radialGradient>
        </defs>

        <!-- Background -->
        <rect width="100" height="140" fill="url(#bgGradient)"/>

        <!-- Title -->
        <text x="50" y="22" text-anchor="middle" style="font-family: -apple-system; font-size: 5px; font-weight: 700; letter-spacing: 0.5px;" fill="#10b981" filter="url(#greenGlow)">
            THE ADVANCEMENT
        </text>

        <!-- Carrier Bag Button (top right) -->
        <g id="bagButton" class="button-group">
            <ellipse cx="85" cy="15" rx="12" ry="9" fill="rgba(233, 30, 99, 0.2)" stroke="#e91e63" stroke-width="0.3" filter="url(#pinkGlow)">
                <animate attributeName="opacity" values="0.6;1;0.6" dur="2.5s" repeatCount="indefinite"/>
            </ellipse>
            <text x="85" y="17" text-anchor="middle" style="font-family: -apple-system; font-size: 3.5px; font-weight: 700; letter-spacing: 0.2px;" fill="#e91e63" filter="url(#pinkGlow)">
                BAG
            </text>
        </g>

        <!-- Posted BDOs Display Area (will be populated dynamically) -->
        <g id="bdoDisplayArea" transform="translate(0, 32)">
            <!-- BDOs will be inserted here -->
        </g>

        <!-- Input Area (at bottom) -->
        <g id="inputArea" transform="translate(0, 102)">
            <!-- POST Button -->
            <g id="postButton" class="button-group">
                <rect x="30" y="15" width="40" height="8" rx="1" fill="rgba(16, 185, 129, 0.15)" stroke="#10b981" stroke-width="0.25" filter="url(#greenGlow)" opacity="0.9">
                    <animate attributeName="opacity" values="0.7;1;0.7" dur="2s" repeatCount="indefinite"/>
                </rect>
                <text x="50" y="20" text-anchor="middle" style="font-family: -apple-system; font-size: 3px; font-weight: 600; letter-spacing: 0.3px;" fill="#10b981" filter="url(#greenGlow)">
                    POST
                </text>
            </g>

            <!-- Keyboard Installation Notice (hidden by default) -->
            <g id="keyboardNotice" class="button-group" opacity="0">
                <rect x="10" y="25" width="80" height="6" rx="1" fill="rgba(251, 191, 36, 0.1)" stroke="#fbbf24" stroke-width="0.2" opacity="0.8"/>
                <text x="50" y="29" text-anchor="middle" style="font-family: -apple-system; font-size: 2px; font-weight: 500; letter-spacing: 0.1px;" fill="#fbbf24" opacity="0.9">
                    ⌨️ Enable AdvanceKey in Settings
                </text>
            </g>
        </g>
    </svg>

    <!-- HTML input styled to look like the purple SVG rect -->
    <div style="position: absolute; top: calc(102 / 140 * 100vh); left: 10vw; width: 80vw; height: calc(10 / 140 * 100vh); pointer-events: auto;">
        <input type="text" id="textInput" placeholder="Enter text to post..." style="width: 100%; height: 100%; background: rgba(139, 92, 246, 0.15); border: 1px solid #8b5cf6; border-radius: 4px; outline: none; color: #8b5cf6; font-family: -apple-system; font-size: 2.5vh; font-weight: 500; pointer-events: auto; padding: 0 2vw; box-sizing: border-box; filter: drop-shadow(0 0 8px rgba(139, 92, 246, 0.5));" />
    </div>

    <script>
        // Override console.log to send to Swift
        (function() {
            const originalLog = console.log;
            const originalError = console.error;
            const originalWarn = console.warn;

            console.log = function(...args) {
                const message = args.map(arg =>
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                ).join(' ');
                webkit.messageHandlers.console.postMessage({level: 'log', message: message});
                originalLog.apply(console, args);
            };

            console.error = function(...args) {
                const message = args.map(arg =>
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                ).join(' ');
                webkit.messageHandlers.console.postMessage({level: 'error', message: message});
                originalError.apply(console, args);
            };

            console.warn = function(...args) {
                const message = args.map(arg =>
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                ).join(' ');
                webkit.messageHandlers.console.postMessage({level: 'warn', message: message});
                originalWarn.apply(console, args);
            };
        })();

        console.log('🚀 Main view loaded');

        const textInput = document.getElementById('textInput');

        console.log('✅ Text input element:', textInput);

        // Log input changes
        textInput.addEventListener('input', function() {
            console.log('✏️ Input changed:', textInput.value);
        });

        textInput.addEventListener('focus', function() {
            console.log('🎯 Input focused');
        });

        textInput.addEventListener('blur', function() {
            console.log('👋 Input blurred');
        });

        // POST button click handler
        document.getElementById('postButton').addEventListener('click', function() {
            console.log('🔘 POST button clicked');
            const text = textInput.value.trim();
            if (!text) {
                console.warn('⚠️ No text entered');
                alert('Please enter some text first');
                return;
            }

            console.log('📤 Posting text:', text);

            // Send to Swift
            webkit.messageHandlers.mainApp.postMessage({
                action: 'post',
                text: text
            });

            // Clear input
            textInput.value = '';
        });

        // BAG button click handler
        document.getElementById('bagButton').addEventListener('click', function() {
            console.log('🎒 BAG button clicked');

            // Send to Swift
            webkit.messageHandlers.mainApp.postMessage({
                action: 'openBag'
            });
        });

        // Keyboard Notice click handler
        document.getElementById('keyboardNotice').addEventListener('click', function() {
            console.log('⌨️ Keyboard notice clicked');

            // Send to Swift
            webkit.messageHandlers.mainApp.postMessage({
                action: 'openKeyboardSettings'
            });
        });

        // Check keyboard installation status
        function checkKeyboardInstallation() {
            webkit.messageHandlers.mainApp.postMessage({
                action: 'checkKeyboard'
            });
        }

        // Function to show/hide keyboard notice
        function setKeyboardNoticeVisible(visible) {
            const notice = document.getElementById('keyboardNotice');
            notice.setAttribute('opacity', visible ? '1' : '0');
        }

        // Check keyboard status on load
        checkKeyboardInstallation();

        // Function called from Swift to add posted BDO to display
        function addPostedBDO(bdoData) {
            const displayArea = document.getElementById('bdoDisplayArea');
            const currentBDOs = displayArea.querySelectorAll('g').length;
            const yOffset = currentBDOs * 25;

            // Create SVG for this BDO
            const bdoGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g');
            bdoGroup.setAttribute('transform', `translate(0, ${yOffset})`);

            // BDO Container
            const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
            rect.setAttribute('x', '10');
            rect.setAttribute('y', '0');
            rect.setAttribute('width', '80');
            rect.setAttribute('height', '20');
            rect.setAttribute('rx', '1');
            rect.setAttribute('fill', 'rgba(236, 72, 153, 0.15)');
            rect.setAttribute('stroke', '#ec4899');
            rect.setAttribute('stroke-width', '0.25');
            rect.setAttribute('filter', 'url(#pinkGlow)');
            bdoGroup.appendChild(rect);

            // BDO Text
            const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
            text.setAttribute('x', '50');
            text.setAttribute('y', '8');
            text.setAttribute('text-anchor', 'middle');
            text.setAttribute('style', 'font-family: -apple-system; font-size: 3px; font-weight: 600;');
            text.setAttribute('fill', '#ec4899');
            text.textContent = bdoData.text;
            bdoGroup.appendChild(text);

            displayArea.appendChild(bdoGroup);

            // Add HTML overlay for selectable emojicode
            const emojiOverlay = document.createElement('div');
            const totalYOffset = 32 + yOffset; // Base offset (32 for BDO display area) + BDO offset
            emojiOverlay.style.cssText = `
                position: absolute;
                top: calc(${totalYOffset} / 140 * 100vh + 12vh);
                left: 50%;
                transform: translateX(-50%);
                color: #fbbf24;
                font-family: -apple-system;
                font-size: 4vh;
                font-weight: 400;
                text-align: center;
                user-select: text;
                -webkit-user-select: text;
                pointer-events: auto;
                filter: drop-shadow(0 0 8px rgba(251, 191, 36, 0.6));
                letter-spacing: 0.2em;
            `;
            emojiOverlay.textContent = bdoData.emojicode || '🌟';
            document.body.appendChild(emojiOverlay);

            // Update SVG height to accommodate new BDO
            const newHeight = 140 + (currentBDOs * 10);
            document.getElementById('mainSVG').setAttribute('viewBox', `0 0 100 ${newHeight}`);
        }
    </script>
</body>
</html>
"""
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle console logging
        if message.name == "console" {
            if let logMessage = message.body as? String {
                NSLog("🌐 WebView: %@", logMessage)
            } else if let logDict = message.body as? [String: Any] {
                if let level = logDict["level"] as? String, let msg = logDict["message"] as? String {
                    NSLog("🌐 WebView [%@]: %@", level.uppercased(), msg)
                }
            }
            return
        }

        // Handle main app messages
        guard message.name == "mainApp",
              let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String else {
            return
        }

        if action == "post", let text = messageBody["text"] as? String {
            postBDO(text: text)
        } else if action == "openBag" {
            openCarrierBag()
        } else if action == "checkKeyboard" {
            checkKeyboardInstallation()
        } else if action == "openKeyboardSettings" {
            openKeyboardSettings()
        }
    }

    // MARK: - Carrier Bag

    public func openCarrierBag() {
        NSLog("🎒 Opening Carrier Bag")

        let carrierBagVC = CarrierBagViewController()
        let navController = UINavigationController(rootViewController: carrierBagVC)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true)
    }

    // MARK: - Keyboard Installation Check

    private func checkKeyboardInstallation() {
        NSLog("⌨️ Checking keyboard installation status")

        // Check for keyboard flag in shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.app.planetnine.theadvancement")
        let keyboardInstalled = sharedDefaults?.bool(forKey: "keyboardFirstUsed") ?? false

        NSLog("⌨️ Keyboard installed: %@", keyboardInstalled ? "YES" : "NO")

        // Update UI to show/hide notice
        let jsCode = "setKeyboardNoticeVisible(\(!keyboardInstalled));"
        webView.evaluateJavaScript(jsCode) { _, error in
            if let error = error {
                NSLog("⚠️ Failed to update keyboard notice: %@", error.localizedDescription)
            }
        }
    }

    private func openKeyboardSettings() {
        NSLog("⌨️ Opening keyboard settings")

        // Open Settings app to General > Keyboard > Keyboards
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - BDO Posting

    private func postBDO(text: String) {
        NSLog("📝 Posting BDO with text: %@", text)

        Task {
            do {
                let bdoData = try await createTextBDO(text: text)

                await MainActor.run {
                    addBDOToDisplay(bdoData)
                }
            } catch {
                NSLog("❌ Failed to post BDO: %@", error.localizedDescription)
                await MainActor.run {
                    showError("Failed to post: \\(error.localizedDescription)")
                }
            }
        }
    }

    private func createTextBDO(text: String) async throws -> [String: Any] {
        // Get BDO user UUID
        guard let bdoUserData = UserDefaults.standard.data(forKey: "bdoUser"),
              let bdoUser = try? JSONSerialization.jsonObject(with: bdoUserData) as? [String: Any],
              let uuid = bdoUser["uuid"] as? String else {
            NSLog("❌ No BDO user found in UserDefaults")
            // Try to check if it exists at all
            if let keys = Array(UserDefaults.standard.dictionaryRepresentation().keys) as? [String] {
                NSLog("📋 Available UserDefaults keys: %@", keys.joined(separator: ", "))
            }
            throw NSError(domain: "BDOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No BDO user found"])
        }

        NSLog("✅ Using BDO user UUID: %@", uuid)

        // Create SVG from text
        let svg = createTextSVG(text: text)

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "the-advancement"
        let sessionless = Sessionless()

        guard let keys = sessionless.getKeys() else {
            throw NSError(domain: "KeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No keys available"])
        }

        NSLog("🔑 Using pubKey: %@", keys.publicKey)

        // The message format for BDO posting should be: timestamp + bdoUUID + hash
        let message = timestamp + uuid + hash
        NSLog("📝 Signing message: timestamp(%@) + uuid(%@) + hash(%@)", timestamp, uuid, hash)

        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign"])
        }

        NSLog("✍️ Generated signature: %@...", String(signature.prefix(20)))

        let bdoPayload: [String: Any] = [
            "timestamp": timestamp,
            "signature": signature,
            "hash": hash,
            "pubKey": keys.publicKey,
            "bdo": [
                "type": "text-post",
                "text": text,
                "svgContent": svg,
                "created": timestamp
            ]
        ]

        let url = URL(string: Configuration.BDO.putBDO(userUUID: uuid))!
        NSLog("📡 Sending BDO to: %@", url.absoluteString)

        if let payloadData = try? JSONSerialization.data(withJSONObject: bdoPayload),
           let payloadString = String(data: payloadData, encoding: .utf8) {
            NSLog("📦 BDO payload: %@", payloadString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: bdoPayload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BDOError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "BDO creation failed: \\(errorMessage)"])
        }

        let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Log the full response to see what we got
        if let responseString = String(data: data, encoding: .utf8) {
            NSLog("📦 BDO creation response: %@", responseString)
        }

        NSLog("✅ BDO created successfully")

        // Check if emojiShortcode is already in the response (preferred method)
        if let emojiShortcode = responseJSON?["emojiShortcode"] as? String {
            NSLog("✅ Got emojiShortcode from response: %@", emojiShortcode)
            return [
                "text": text,
                "emojicode": emojiShortcode
            ]
        }

        // Fallback: Try to get emojicode by fetching with pubKey
        if let bdoPubKey = responseJSON?["pubKey"] as? String {
            NSLog("🔑 BDO pubKey from response: %@", bdoPubKey)
            do {
                let emojicode = try await fetchEmojicode(pubKey: bdoPubKey)
                NSLog("✅ Got emojicode: %@", emojicode)
                return [
                    "text": text,
                    "emojicode": emojicode,
                    "pubKey": bdoPubKey
                ]
            } catch {
                NSLog("⚠️ Failed to fetch emojicode: %@", error.localizedDescription)
            }
        } else {
            NSLog("⚠️ No pubKey in BDO response, checking other fields")
            NSLog("📋 Response keys: %@", responseJSON?.keys.joined(separator: ", ") ?? "none")
        }

        return ["text": text, "emojicode": "🌟"]
    }

    private func createTextSVG(text: String) -> String {
        return """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100">
            <rect width="200" height="100" fill="#1a0033"/>
            <text x="100" y="50" text-anchor="middle" fill="#ec4899" font-size="16" font-family="Arial">\(text)</text>
        </svg>
        """
    }

    private func fetchEmojicode(pubKey: String) async throws -> String {
        let url = URL(string: Configuration.BDO.getEmojicode(pubKey: pubKey))!
        NSLog("🔍 Fetching emojicode from: %@", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            NSLog("📡 Emojicode fetch status: %d", httpResponse.statusCode)
        }

        if let responseString = String(data: data, encoding: .utf8) {
            NSLog("📄 Emojicode response: %@", responseString)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            NSLog("📋 Emojicode JSON keys: %@", json.keys.joined(separator: ", "))

            if let emojicode = json["emojicode"] as? String {
                NSLog("📱 Got emojicode: %@", emojicode)
                return emojicode
            }
        }

        NSLog("⚠️ No emojicode found in response, returning default")
        return "🌟"
    }

    private func addBDOToDisplay(_ bdoData: [String: Any]) {
        postedBDOs.append(bdoData)

        guard let jsonData = try? JSONSerialization.data(withJSONObject: bdoData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            NSLog("⚠️ Failed to serialize BDO data")
            return
        }

        let jsCode = """
        (function() {
            try {
                const bdoData = \(jsonString);
                console.log('📥 Received BDO data:', bdoData);
                addPostedBDO(bdoData);
            } catch(e) {
                console.error('❌ Error adding BDO:', e.message, e.stack);
            }
        })();
        """

        NSLog("📤 Executing JavaScript to add BDO")

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                NSLog("⚠️ Failed to add BDO to display: %@", error.localizedDescription)
            } else {
                NSLog("✅ BDO added to display successfully")
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

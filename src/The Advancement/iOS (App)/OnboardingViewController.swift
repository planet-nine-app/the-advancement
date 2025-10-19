//
//  OnboardingViewController.swift
//  The Advancement
//
//  Onboarding flow with SVG-based WebView interface
//

import UIKit
import WebKit

class OnboardingViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Make view extend to full screen (under status bar)
        view.backgroundColor = .black

        setupWebView()
        loadOnboardingPage()
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
        configuration.userContentController.add(self, name: "onboarding")
        configuration.userContentController.add(self, name: "console")

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(webView)
    }

    private func loadOnboardingPage() {
        let html = getOnboardingHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func getOnboardingHTML() -> String {
        return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; -webkit-user-select: none; -webkit-user-drag: none; }
        html, body { width: 100%; height: 100%; overflow: hidden; background-color: #000000; }
        #onboardingSVG { width: 100vw; height: 100vh; display: block; }
        .button-group { cursor: pointer; }
        .button-group:active rect { fill: rgba(16, 185, 129, 0.2); }
    </style>
</head>
<body>
    <svg id="onboardingSVG" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet">
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
            <g id="particle">
                <circle r="0.2" fill="#8b5cf6" opacity="0.6" filter="url(#purpleGlow)">
                    <animate attributeName="opacity" values="0.3;0.8;0.3" dur="4s" repeatCount="indefinite"/>
                </circle>
            </g>
        </defs>

        <rect width="100" height="100" fill="url(#bgGradient)"/>

        <use href="#particle" x="10" y="15">
            <animateMotion path="M 0 0 Q 8 -12 0 -24 Q -8 -36 0 -48" dur="10s" repeatCount="indefinite"/>
        </use>
        <use href="#particle" x="90" y="25">
            <animateMotion path="M 0 0 Q -10 10 0 20 Q 10 30 0 40" dur="12s" repeatCount="indefinite"/>
        </use>
        <use href="#particle" x="25" y="85">
            <animateMotion path="M 0 0 Q 15 -8 30 0 Q 45 8 60 0" dur="14s" repeatCount="indefinite"/>
        </use>
        <use href="#particle" x="75" y="75">
            <animateMotion path="M 0 0 Q -8 -12 -16 -24 Q -24 -36 -32 -48" dur="11s" repeatCount="indefinite"/>
        </use>

        <g id="corners">
            <path d="M 5,5 L 15,5 M 5,5 L 5,15" stroke="#10b981" stroke-width="0.4" opacity="0.7" filter="url(#greenGlow)"/>
            <path d="M 95,5 L 85,5 M 95,5 L 95,15" stroke="#ec4899" stroke-width="0.4" opacity="0.7" filter="url(#pinkGlow)"/>
            <path d="M 5,95 L 15,95 M 5,95 L 5,85" stroke="#fbbf24" stroke-width="0.4" opacity="0.7" filter="url(#yellowGlow)"/>
            <path d="M 95,95 L 85,95 M 95,95 L 95,85" stroke="#8b5cf6" stroke-width="0.4" opacity="0.7" filter="url(#purpleGlow)"/>
        </g>

        <g id="content">
            <text x="50" y="22" text-anchor="middle" style="font-family: -apple-system; font-size: 5px; font-weight: 700; letter-spacing: 0.5px;" fill="#10b981" filter="url(#greenGlow)">
                GREETINGS HUMAN
            </text>
            <text x="50" y="32" text-anchor="middle" style="font-family: -apple-system; font-size: 3.5px; font-weight: 400; letter-spacing: 0.2px;" fill="#8b5cf6" opacity="0.9">
                Would you like to join
            </text>
            <text x="50" y="37" text-anchor="middle" style="font-family: -apple-system; font-size: 6px; font-weight: 700; letter-spacing: 0.8px;" fill="#ec4899" filter="url(#pinkGlow)">
                THE ADVANCEMENT
            </text>
            <text x="50" y="41" text-anchor="middle" style="font-family: -apple-system; font-size: 2.8px; font-weight: 400; letter-spacing: 0.1px;" fill="#8b5cf6" opacity="0.8">
                ?
            </text>
        </g>

        <g id="yesButton" class="button-group">
            <rect x="25" y="50" width="20" height="8" rx="1" fill="rgba(16, 185, 129, 0.15)" stroke="#10b981" stroke-width="0.25" filter="url(#greenGlow)" opacity="0.9">
                <animate attributeName="opacity" values="0.7;1;0.7" dur="2s" repeatCount="indefinite"/>
            </rect>
            <text x="35" y="54.8" text-anchor="middle" style="font-family: -apple-system; font-size: 3px; font-weight: 600; letter-spacing: 0.3px;" fill="#10b981" filter="url(#greenGlow)">
                YES
            </text>
        </g>

        <g id="hellYesButton" class="button-group">
            <rect x="55" y="50" width="20" height="8" rx="1" fill="rgba(236, 72, 153, 0.15)" stroke="#ec4899" stroke-width="0.25" filter="url(#pinkGlow)" opacity="0.9">
                <animate attributeName="opacity" values="0.7;1;0.7" dur="2.5s" repeatCount="indefinite"/>
            </rect>
            <text x="65" y="54.8" text-anchor="middle" style="font-family: -apple-system; font-size: 3px; font-weight: 600; letter-spacing: 0.3px;" fill="#ec4899" filter="url(#pinkGlow)">
                HELL YES
            </text>
        </g>

        <g id="loadingState" opacity="0">
            <text id="loadingText" x="50" y="70" text-anchor="middle" style="font-family: -apple-system; font-size: 2.5px; font-weight: 500;" fill="#10b981" filter="url(#greenGlow)">
                Initiating connection to Planet Nine...
            </text>
            <circle cx="50" cy="75" r="3" fill="none" stroke="#10b981" stroke-width="0.4" stroke-dasharray="15 5" opacity="0.8">
                <animateTransform attributeName="transform" type="rotate" from="0 50 75" to="360 50 75" dur="2s" repeatCount="indefinite"/>
            </circle>
        </g>

        <g id="errorState" opacity="0">
            <text id="errorText" x="50" y="70" text-anchor="middle" style="font-family: -apple-system; font-size: 2.2px; font-weight: 500;" fill="#ef4444" filter="url(#yellowGlow)">
                Error: Connection failed
            </text>
        </g>

        <line x1="20" y1="92" x2="80" y2="92" stroke="#8b5cf6" stroke-width="0.15" opacity="0.5" filter="url(#purpleGlow)">
            <animate attributeName="opacity" values="0.3;0.7;0.3" dur="3s" repeatCount="indefinite"/>
        </line>
    </svg>

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

        console.log('🚀 Onboarding view loaded');

        document.getElementById('yesButton').addEventListener('click', joinAdvancement);
        document.getElementById('hellYesButton').addEventListener('click', joinAdvancement);

        function joinAdvancement() {
            console.log('🎯 Starting advancement join process');
            document.getElementById('yesButton').style.display = 'none';
            document.getElementById('hellYesButton').style.display = 'none';
            document.getElementById('loadingState').setAttribute('opacity', '1');
            webkit.messageHandlers.onboarding.postMessage({action: 'join'});
        }

        function updateLoadingText(text) {
            document.getElementById('loadingText').textContent = text;
        }

        function showError(errorMessage) {
            document.getElementById('loadingState').setAttribute('opacity', '0');
            document.getElementById('errorState').setAttribute('opacity', '1');
            document.getElementById('errorText').textContent = 'Error: ' + errorMessage;
            setTimeout(function() {
                document.getElementById('yesButton').style.display = 'block';
                document.getElementById('hellYesButton').style.display = 'block';
                document.getElementById('errorState').setAttribute('opacity', '0');
            }, 3000);
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

        // Handle onboarding messages
        guard message.name == "onboarding",
              let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String else {
            return
        }

        if action == "join" {
            joinAdvancement()
        }
    }

    // MARK: - Onboarding Flow

    private func joinAdvancement() {
        NSLog("🚀 User joining The Advancement...")

        // Create users for all services
        Task {
            do {
                try await createPlanetNineUsers()

                // Transition to main app
                await MainActor.run {
                    transitionToMainApp()
                }
            } catch {
                await MainActor.run {
                    showError(error)
                }
            }
        }
    }

    private func createPlanetNineUsers() async throws {
        updateLoadingStatus("Generating cryptographic keys...")
        NSLog("🚀 Creating Planet Nine users...")

        // Generate keys using Sessionless
        let sessionless = Sessionless()

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        // Get or generate user keys
        let keys = sessionless.getKeys() ?? sessionless.generateKeys()
        guard let userPubKey = keys?.publicKey else {
            throw NSError(domain: "KeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get user keys"])
        }

        // Save pubKey to SharedUserDefaults
        SharedUserDefaults.setCurrentUserPubKey(userPubKey)

        NSLog("🔑 User pubKey: %@", userPubKey)

        // Create signature for user creation
        let message = timestamp + userPubKey
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign message"])
        }

        // Create Fount user
        updateLoadingStatus("Creating Fount user...")
        let fountUUID = try await createFountUser(pubKey: userPubKey, timestamp: timestamp, signature: signature)

        // Create BDO user
        updateLoadingStatus("Creating BDO user...")
        let bdoUUID = try await createBDOUser(pubKey: userPubKey)

        // Create carrierBag for the user
        updateLoadingStatus("Creating carrierBag...")
        try await createCarrierBag(userUUID: bdoUUID, pubKey: userPubKey)

        // Create Addie user
        updateLoadingStatus("Creating payment user...")
        try await createAddieUser(pubKey: userPubKey)

        updateLoadingStatus("Welcome to The Advancement!")
        NSLog("✅ Planet Nine users created successfully!")
        NSLog("✅ Fount UUID: %@", fountUUID)
        NSLog("✅ BDO UUID: %@", bdoUUID)
    }

    private func createFountUser(pubKey: String, timestamp: String, signature: String) async throws -> String {
        let url = URL(string: "http://localhost:5117/user/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Fount"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fount error: \(errorMessage)"])
        }

        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        guard let userUUID = responseJSON?["uuid"] as? String else {
            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("⚠️ Fount response: %@", responseString)
            }
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Fount user response"])
        }

        SharedUserDefaults.setCovenantUserUUID(userUUID)
        NSLog("✅ Fount user created: %@", userUUID)

        return userUUID
    }

    private func createCarrierBag(userUUID: String, pubKey: String) async throws {
        // BDO service endpoint
        let url = URL(string: "http://localhost:5114/user/\(userUUID)/bdo")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create empty carrierBag with all collections
        let carrierBagData: [String: Any] = [
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
            "stacks": []
        ]

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = ""
        let sessionless = Sessionless()
        let message = timestamp + hash + pubKey
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign carrierBag creation"])
        }

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "hash": hash,
            "signature": signature,
            "bdo": carrierBagData
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from BDO service"])
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BDOError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "CarrierBag creation failed: \(errorMessage)"])
        }

        // Save carrierBag to SharedUserDefaults
        SharedUserDefaults.saveCarrierBag(carrierBagData)

        NSLog("✅ CarrierBag created successfully")
    }

    private func createBDOUser(pubKey: String) async throws -> String {
        let url = URL(string: "http://localhost:5114/user/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "the-advancement"
        let sessionless = Sessionless()
        let message = timestamp + pubKey + hash
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign BDO user creation"])
        }

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "hash": hash,
            "signature": signature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from BDO service"])
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BDOError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "BDO user creation failed: \(errorMessage)"])
        }

        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userUUID = responseJSON?["uuid"] as? String else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse BDO user response"])
        }

        // Store BDO UUID
        let bdoUser: [String: Any] = ["uuid": userUUID, "bdo": [:]]
        if let userData = try? JSONSerialization.data(withJSONObject: bdoUser) {
            UserDefaults.standard.set(userData, forKey: "bdoUser")
            NSLog("💾 Stored BDO user to UserDefaults with key 'bdoUser'")

            // Verify it was saved
            if let savedData = UserDefaults.standard.data(forKey: "bdoUser"),
               let saved = try? JSONSerialization.jsonObject(with: savedData) as? [String: Any],
               let savedUUID = saved["uuid"] as? String {
                NSLog("✅ Verified BDO UUID saved: %@", savedUUID)
            } else {
                NSLog("⚠️ Failed to verify BDO UUID was saved")
            }
        } else {
            NSLog("❌ Failed to serialize BDO user data")
        }

        NSLog("✅ BDO user created: %@", userUUID)
        return userUUID
    }

    private func createAddieUser(pubKey: String) async throws {
        let url = URL(string: "http://localhost:5116/user/create")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let sessionless = Sessionless()
        let message = timestamp + pubKey
        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign Addie user creation"])
        }

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response from Addie service"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "AddieError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Addie user creation failed: \(errorMessage)"])
        }

        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let userUUID = responseJSON?["uuid"] as? String else {
            throw NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to parse Addie user response"])
        }

        // Store Addie UUID
        let addieUser: [String: Any] = ["uuid": userUUID, "created": timestamp, "pubKey": pubKey]
        if let userData = try? JSONSerialization.data(withJSONObject: addieUser) {
            UserDefaults.standard.set(userData, forKey: "addieUser")
        }

        NSLog("✅ Addie user created: %@", userUUID)
    }

    private func updateLoadingStatus(_ status: String) {
        webView.evaluateJavaScript("updateLoadingText('\(status)')") { result, error in
            if let error = error {
                NSLog("⚠️ Failed to update loading text: %@", error.localizedDescription)
            }
        }
    }

    private func transitionToMainApp() {
        NSLog("🎉 Transitioning to main app...")

        if let windowScene = view.window?.windowScene,
           let sceneDelegate = windowScene.delegate as? SceneDelegate,
           let window = sceneDelegate.window {

            // Load main view controller from storyboard
            let mainVC = createMainViewController()

            window.rootViewController = mainVC

            UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: nil)
        }
    }

    private func createMainViewController() -> UIViewController {
        // Use new SVG-based MainViewController
        return MainViewController()
    }

    private func showError(_ error: Error) {
        NSLog("❌ Error creating users: %@", error.localizedDescription)

        let escapedError = error.localizedDescription.replacingOccurrences(of: "'", with: "\\'")
        webView.evaluateJavaScript("showError('\(escapedError)')") { result, error in
            if let error = error {
                NSLog("⚠️ Failed to show error: %@", error.localizedDescription)
            }
        }
    }
}

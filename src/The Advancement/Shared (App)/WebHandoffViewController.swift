//
//  WebHandoffViewController.swift
//  The Advancement
//
//  Web-to-app purchase handoff for linkitylink using authteam color sequence verification
//

#if os(iOS)
import UIKit
import WebKit

class WebHandoffViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {

    private var webView: WKWebView!
    private let sessionless = Sessionless()
    private var handoffToken: String?
    private var handoffData: [String: Any]?
    private var authSequence: [String] = []

    // Base discovery
    private var baseEmojicode: String?  // 4-emoji base identifier like 💚☮️💚🏴‍☠️
    private var resolvedLinkitylinkURL: String?  // Resolved URL for the base's linkitylink
    private var resolvedBaseInfo: [String: Any]?  // Full base information from Fount

    // Preloaded with token from caller
    var preloadedToken: String?
    var preloadedBaseEmojicode: String?  // Can be preloaded from URL scheme

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Connect from Web"
        view.backgroundColor = UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)

        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        // Setup WebView
        setupWebView()
        loadHandoffUI()

        NSLog("HANDOFF: View loaded")

        // If we have a preloaded base emojicode, resolve it first
        if let baseEmoji = preloadedBaseEmojicode, !baseEmoji.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.resolveBase(emojicode: baseEmoji)
            }
        }
        // If we have a preloaded token (and base is already resolved), fetch the handoff data
        else if let token = preloadedToken, !token.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.fetchHandoff(token: token)
            }
        }
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "handoff")
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "handoff")

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        view.addSubview(webView)

        // Layout
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadHandoffUI() {
        let html = generateHandoffHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    @objc private func closeTapped() {
        NSLog("HANDOFF: Close button tapped")
        dismiss(animated: true)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "handoff",
              let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String else {
            NSLog("HANDOFF: Invalid message")
            return
        }

        NSLog("HANDOFF: Received action: %@", action)

        switch action {
        case "submitBase":
            guard let emojicode = messageBody["emojicode"] as? String else { return }
            resolveBase(emojicode: emojicode)

        case "submitToken":
            guard let token = messageBody["token"] as? String else { return }
            fetchHandoff(token: token)

        case "colorTapped":
            guard let color = messageBody["color"] as? String else { return }
            handleColorTap(color: color)

        case "verifySequence":
            verifySequence()

        case "completePurchase":
            completePurchase()

        case "cancel":
            closeTapped()

        default:
            NSLog("HANDOFF: Unknown action: %@", action)
        }
    }

    // MARK: - Base Resolution

    private func resolveBase(emojicode: String) {
        NSLog("HANDOFF: Resolving base for emojicode: %@", emojicode)

        self.baseEmojicode = emojicode

        // Use the app's home Fount to resolve the base
        // The base emojicode format is: 💚☮️💚🏴‍☠️ (4 emojis + federation subdomain)
        // This will resolve to the base's linkitylink URL

        let fountBaseURL = Configuration.fountBaseURL
        guard let encodedEmojicode = emojicode.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(fountBaseURL)/base/\(encodedEmojicode)") else {
            NSLog("HANDOFF: Invalid Fount URL for base resolution")
            // Fall back to default linkitylink
            self.resolvedLinkitylinkURL = Configuration.linkitylinkBaseURL
            DispatchQueue.main.async {
                self.showTokenSection()
            }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("HANDOFF: Base resolution failed: %@", error.localizedDescription)
                // Fall back to default
                self.resolvedLinkitylinkURL = Configuration.linkitylinkBaseURL
                DispatchQueue.main.async {
                    self.showTokenSection()
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("HANDOFF: Invalid base resolution response")
                self.resolvedLinkitylinkURL = Configuration.linkitylinkBaseURL
                DispatchQueue.main.async {
                    self.showTokenSection()
                }
                return
            }

            // Store the base info
            self.resolvedBaseInfo = json

            // Extract the linkitylink URL from the base info
            // The base BDO should contain a services object with linkitylink URL
            if let services = json["services"] as? [String: Any],
               let linkitylinkURL = services["linkitylink"] as? String {
                self.resolvedLinkitylinkURL = linkitylinkURL
                NSLog("HANDOFF: Resolved linkitylink URL: %@", linkitylinkURL)
            } else if let baseURL = json["baseURL"] as? String {
                // Construct linkitylink URL from base URL
                // Assuming linkitylink runs on port 3010 relative to base
                self.resolvedLinkitylinkURL = "\(baseURL.replacingOccurrences(of: ":3000", with: ":3010"))"
                NSLog("HANDOFF: Constructed linkitylink URL: %@", self.resolvedLinkitylinkURL ?? "nil")
            } else {
                // Fall back to default
                self.resolvedLinkitylinkURL = Configuration.linkitylinkBaseURL
                NSLog("HANDOFF: Using default linkitylink URL")
            }

            DispatchQueue.main.async {
                self.showBaseResolvedUI()
                // If we have a preloaded token, continue to fetch handoff
                if let token = self.preloadedToken, !token.isEmpty {
                    self.fetchHandoff(token: token)
                }
            }
        }.resume()
    }

    private func getLinkitylinkURL() -> String {
        return resolvedLinkitylinkURL ?? Configuration.linkitylinkBaseURL
    }

    // MARK: - Handoff Flow

    private func fetchHandoff(token: String) {
        NSLog("HANDOFF: Fetching handoff for token: %@", token)

        let baseURL = getLinkitylinkURL()
        let endpoint = "\(baseURL)/handoff/\(token)"
        guard let url = URL(string: endpoint) else {
            showError("Invalid handoff URL")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.showError("Failed to fetch handoff: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                DispatchQueue.main.async {
                    self.showError("Invalid handoff response")
                }
                return
            }

            guard let success = json["success"] as? Bool, success else {
                let errorMsg = json["error"] as? String ?? "Handoff not found"
                DispatchQueue.main.async {
                    self.showError(errorMsg)
                }
                return
            }

            // Store the handoff data
            self.handoffToken = token
            self.handoffData = json
            self.authSequence = json["authSequence"] as? [String] ?? []

            NSLog("HANDOFF: Got handoff data with %d color sequence", self.authSequence.count)

            DispatchQueue.main.async {
                self.showAuthteamUI()
            }
        }.resume()
    }

    private func handleColorTap(color: String) {
        NSLog("HANDOFF: Color tapped: %@", color)
        // The JavaScript handles the visual feedback and sequence tracking
    }

    private func verifySequence() {
        guard let token = handoffToken,
              let keys = sessionless.getKeys() else {
            showError("Missing credentials")
            return
        }

        NSLog("HANDOFF: Verifying sequence...")

        let baseURL = getLinkitylinkURL()
        let endpoint = "\(baseURL)/handoff/\(token)/verify"
        guard let url = URL(string: endpoint) else {
            showError("Invalid verify URL")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey

        guard let signature = sessionless.sign(message: message) else {
            showError("Failed to sign verification")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pubKey": keys.publicKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.showError("Verification failed: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success else {
                DispatchQueue.main.async {
                    self.showError("Sequence verification failed")
                }
                return
            }

            NSLog("HANDOFF: Sequence verified! App connected.")

            DispatchQueue.main.async {
                self.showPurchaseUI()
            }
        }.resume()
    }

    private func completePurchase() {
        guard let token = handoffToken,
              let keys = sessionless.getKeys() else {
            showError("Missing credentials")
            return
        }

        NSLog("HANDOFF: Completing purchase...")

        let baseURL = getLinkitylinkURL()
        let endpoint = "\(baseURL)/handoff/\(token)/complete"
        guard let url = URL(string: endpoint) else {
            showError("Invalid complete URL")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey + token

        guard let signature = sessionless.sign(message: message) else {
            showError("Failed to sign purchase")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Get saved payment method
        var paymentMethodId: String? = nil
        if let cardsData = UserDefaults.standard.data(forKey: "stripe_saved_cards"),
           let cards = try? JSONSerialization.jsonObject(with: cardsData) as? [[String: Any]],
           let firstCard = cards.first,
           let cardId = firstCard["id"] as? String {
            paymentMethodId = cardId
        }

        guard let pmId = paymentMethodId else {
            showError("No saved payment method. Please add a card first.")
            return
        }

        let body: [String: Any] = [
            "pubKey": keys.publicKey,
            "timestamp": timestamp,
            "signature": signature,
            "paymentMethodId": pmId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.showError("Purchase failed: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let success = json["success"] as? Bool, success else {
                if let data = data, let responseStr = String(data: data, encoding: .utf8) {
                    NSLog("HANDOFF: Purchase response: %@", responseStr)
                }
                DispatchQueue.main.async {
                    self.showError("Purchase could not be completed")
                }
                return
            }

            let emojicode = json["emojicode"] as? String ?? ""

            NSLog("HANDOFF: Purchase complete! Emojicode: %@", emojicode)

            DispatchQueue.main.async {
                self.showSuccessUI(emojicode: emojicode)
            }
        }.resume()
    }

    // MARK: - UI Updates

    private func showTokenSection() {
        let js = "showSection('tokenSection');"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func showBaseResolvedUI() {
        let baseName = (resolvedBaseInfo?["name"] as? String) ?? baseEmojicode ?? "Unknown Base"
        let escapedName = baseName.replacingOccurrences(of: "'", with: "\\'")

        let js = """
        showBaseResolved({
            baseName: '\(escapedName)',
            baseEmoji: '\(baseEmojicode ?? "")'
        });
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func showAuthteamUI() {
        guard let data = handoffData else { return }

        let title = (data["bdoData"] as? [String: Any])?["title"] as? String ?? "Your Linkitylink"
        let linkCount = ((data["bdoData"] as? [String: Any])?["links"] as? [[String: Any]])?.count ?? 0

        let sequenceJSON = (try? JSONSerialization.data(withJSONObject: authSequence)) ?? Data()
        let sequenceString = String(data: sequenceJSON, encoding: .utf8) ?? "[]"

        let js = """
        showAuthteam({
            title: '\(title.replacingOccurrences(of: "'", with: "\\'"))',
            linkCount: \(linkCount),
            sequence: \(sequenceString)
        });
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func showPurchaseUI() {
        guard let data = handoffData else { return }

        let title = (data["bdoData"] as? [String: Any])?["title"] as? String ?? "Your Linkitylink"

        let js = """
        showPurchase({
            title: '\(title.replacingOccurrences(of: "'", with: "\\'"))',
            price: 15.00
        });
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func showSuccessUI(emojicode: String) {
        let js = """
        showSuccess({
            emojicode: '\(emojicode)'
        });
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    private func showError(_ message: String) {
        let escapedMessage = message.replacingOccurrences(of: "'", with: "\\'")
        let js = "showError('\(escapedMessage)');"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    // MARK: - HTML Generation

    private func generateHandoffHTML() -> String {
        let preloadedTokenJS = preloadedToken != nil ? "'\(preloadedToken!)'" : "null"
        let preloadedBaseJS = preloadedBaseEmojicode != nil ? "'\(preloadedBaseEmojicode!)'" : "null"

        return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
    <style>
        :root {
            --bg-primary: #1a0033;
            --bg-secondary: #2d0a4e;
            --accent-green: #10b981;
            --accent-purple: #8b5cf6;
            --accent-pink: #e91e63;
            --text-primary: #e0d4f7;
            --text-secondary: #a0a0a0;
        }

        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, var(--bg-primary) 0%, var(--bg-secondary) 100%);
            color: var(--text-primary);
            min-height: 100vh;
            padding: 20px;
        }

        .container {
            max-width: 400px;
            margin: 0 auto;
        }

        .section {
            display: none;
            animation: fadeIn 0.3s ease;
        }
        .section.active { display: block; }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        h1 {
            font-size: 24px;
            color: var(--accent-green);
            margin-bottom: 20px;
            text-align: center;
        }

        h2 {
            font-size: 18px;
            color: var(--accent-purple);
            margin-bottom: 15px;
        }

        .input-group {
            margin-bottom: 20px;
        }

        input[type="text"] {
            width: 100%;
            padding: 15px;
            border: 2px solid var(--accent-purple);
            border-radius: 12px;
            background: rgba(139, 92, 246, 0.1);
            color: var(--text-primary);
            font-size: 16px;
            outline: none;
        }

        input[type="text"]:focus {
            border-color: var(--accent-green);
            box-shadow: 0 0 20px rgba(16, 185, 129, 0.3);
        }

        .btn {
            width: 100%;
            padding: 15px 30px;
            border: none;
            border-radius: 12px;
            font-size: 18px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-bottom: 10px;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--accent-green) 0%, #059669 100%);
            color: white;
        }

        .btn-primary:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(16, 185, 129, 0.4);
        }

        .btn-secondary {
            background: rgba(139, 92, 246, 0.2);
            color: var(--accent-purple);
            border: 2px solid var(--accent-purple);
        }

        /* Color buttons for authteam */
        .color-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 10px;
            margin: 20px 0;
        }

        .color-btn {
            aspect-ratio: 1;
            border: 3px solid transparent;
            border-radius: 12px;
            cursor: pointer;
            transition: all 0.2s ease;
        }

        .color-btn:active {
            transform: scale(0.95);
        }

        .color-btn.red { background: #ef4444; }
        .color-btn.blue { background: #3b82f6; }
        .color-btn.green { background: #22c55e; }
        .color-btn.yellow { background: #eab308; }
        .color-btn.purple { background: #a855f7; }
        .color-btn.orange { background: #f97316; }

        .color-btn.selected {
            border-color: white;
            box-shadow: 0 0 20px currentColor;
        }

        /* Sequence display */
        .sequence-display {
            display: flex;
            justify-content: center;
            gap: 8px;
            margin: 20px 0;
            min-height: 50px;
        }

        .sequence-dot {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            border: 2px solid rgba(255,255,255,0.3);
        }

        .sequence-dot.red { background: #ef4444; }
        .sequence-dot.blue { background: #3b82f6; }
        .sequence-dot.green { background: #22c55e; }
        .sequence-dot.yellow { background: #eab308; }
        .sequence-dot.purple { background: #a855f7; }
        .sequence-dot.orange { background: #f97316; }

        /* Info box */
        .info-box {
            background: rgba(139, 92, 246, 0.1);
            border: 1px solid var(--accent-purple);
            border-radius: 12px;
            padding: 15px;
            margin: 20px 0;
        }

        .info-box p {
            margin: 5px 0;
            font-size: 14px;
        }

        /* Price display */
        .price-display {
            text-align: center;
            margin: 30px 0;
        }

        .price {
            font-size: 48px;
            font-weight: 700;
            color: var(--accent-green);
        }

        .price-original {
            font-size: 24px;
            color: var(--text-secondary);
            text-decoration: line-through;
            margin-right: 10px;
        }

        .discount-badge {
            display: inline-block;
            background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
            color: white;
            padding: 5px 15px;
            border-radius: 20px;
            font-size: 14px;
            font-weight: 600;
            margin-top: 10px;
        }

        /* Success */
        .success-icon {
            font-size: 80px;
            text-align: center;
            margin: 20px 0;
        }

        .emojicode {
            font-size: 32px;
            text-align: center;
            letter-spacing: 4px;
            background: rgba(16, 185, 129, 0.1);
            border: 2px solid var(--accent-green);
            border-radius: 12px;
            padding: 20px;
            margin: 20px 0;
        }

        /* Error */
        .error-message {
            background: rgba(239, 68, 68, 0.1);
            border: 1px solid #ef4444;
            color: #ef4444;
            padding: 15px;
            border-radius: 12px;
            margin: 20px 0;
            text-align: center;
        }

        .hidden { display: none; }
    </style>
</head>
<body>
    <div class="container">
        <!-- Base Entry Section -->
        <div id="baseSection" class="section active">
            <h1>Select Base</h1>
            <p style="text-align: center; margin-bottom: 20px; color: var(--text-secondary);">
                Enter the 4-emoji base code shown on the linkitylink website.
            </p>
            <p style="text-align: center; margin-bottom: 30px; font-size: 12px; color: var(--text-secondary);">
                Example: 💚☮️💚🏴‍☠️
            </p>
            <div class="input-group">
                <input type="text" id="baseInput" placeholder="Enter base emojis..." autocomplete="off" style="font-size: 24px; text-align: center;">
            </div>
            <button class="btn btn-primary" onclick="submitBase()">Find Base</button>
            <button class="btn btn-secondary" onclick="skipBase()">Use Default Base</button>
            <button class="btn btn-secondary" onclick="cancel()">Cancel</button>
        </div>

        <!-- Token Entry Section -->
        <div id="tokenSection" class="section">
            <h1>Connect from Web</h1>
            <div id="baseIndicator" class="info-box" style="display: none;">
                <p style="font-size: 12px; color: var(--text-secondary);">Connected to base:</p>
                <p><strong id="connectedBaseName"></strong></p>
            </div>
            <p style="text-align: center; margin-bottom: 30px; color: var(--text-secondary);">
                Enter the handoff code shown on the website to continue your purchase here.
            </p>
            <div class="input-group">
                <input type="text" id="tokenInput" placeholder="Enter handoff code..." autocomplete="off" autocapitalize="none">
            </div>
            <button class="btn btn-primary" onclick="submitToken()">Connect</button>
            <button class="btn btn-secondary" onclick="cancel()">Cancel</button>
        </div>

        <!-- Authteam Section -->
        <div id="authteamSection" class="section">
            <h1>Verify Connection</h1>
            <div class="info-box">
                <p><strong id="productTitle">Your Linkitylink</strong></p>
                <p id="linkCountInfo">Creating link page...</p>
            </div>
            <p style="text-align: center; margin-bottom: 15px;">
                Tap the colors in the sequence shown on the website:
            </p>
            <div id="targetSequence" class="sequence-display"></div>
            <p style="text-align: center; font-size: 12px; color: var(--text-secondary); margin-bottom: 15px;">
                Your progress:
            </p>
            <div id="userSequence" class="sequence-display"></div>
            <div class="color-grid">
                <button class="color-btn red" onclick="colorTapped('red')"></button>
                <button class="color-btn blue" onclick="colorTapped('blue')"></button>
                <button class="color-btn green" onclick="colorTapped('green')"></button>
                <button class="color-btn yellow" onclick="colorTapped('yellow')"></button>
                <button class="color-btn purple" onclick="colorTapped('purple')"></button>
                <button class="color-btn orange" onclick="colorTapped('orange')"></button>
            </div>
            <button class="btn btn-primary" id="verifyBtn" disabled onclick="verifySequence()">
                Complete Sequence First
            </button>
            <button class="btn btn-secondary" onclick="cancel()">Cancel</button>
        </div>

        <!-- Purchase Section -->
        <div id="purchaseSection" class="section">
            <h1>Complete Purchase</h1>
            <div class="info-box">
                <p><strong id="purchaseTitle">Your Linkitylink</strong></p>
                <p>App connected successfully!</p>
            </div>
            <div class="price-display">
                <span class="price-original">$20</span>
                <span class="price">$15</span>
                <div class="discount-badge">25% App Discount</div>
            </div>
            <button class="btn btn-primary" onclick="completePurchase()">
                Complete Purchase - $15
            </button>
            <button class="btn btn-secondary" onclick="cancel()">Cancel</button>
        </div>

        <!-- Success Section -->
        <div id="successSection" class="section">
            <h1>Purchase Complete!</h1>
            <div class="success-icon">
            </div>
            <p style="text-align: center; margin-bottom: 20px;">
                Your Linkitylink has been created! Here's your emojicode:
            </p>
            <div id="emojicodeDisplay" class="emojicode"></div>
            <p style="text-align: center; font-size: 14px; color: var(--text-secondary); margin-bottom: 20px;">
                Share this code with anyone to let them view your link page!
            </p>
            <button class="btn btn-primary" onclick="copyEmojicode()">Copy Emojicode</button>
            <button class="btn btn-secondary" onclick="done()">Done</button>
        </div>

        <!-- Error Display -->
        <div id="errorDisplay" class="error-message hidden"></div>
    </div>

    <script>
        let currentSequence = [];
        let targetSequence = [];
        let preloadedToken = \(preloadedTokenJS);
        let preloadedBase = \(preloadedBaseJS);
        let resolvedBaseName = null;

        // Auto-fill base if preloaded
        if (preloadedBase) {
            document.getElementById('baseInput').value = preloadedBase;
        }

        // Auto-fill token if preloaded
        if (preloadedToken) {
            document.getElementById('tokenInput').value = preloadedToken;
        }

        function showSection(sectionId) {
            document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
            document.getElementById(sectionId).classList.add('active');
            document.getElementById('errorDisplay').classList.add('hidden');
        }

        function submitBase() {
            const baseEmoji = document.getElementById('baseInput').value.trim();
            if (!baseEmoji) {
                showError('Please enter a base emojicode');
                return;
            }
            webkit.messageHandlers.handoff.postMessage({
                action: 'submitBase',
                emojicode: baseEmoji
            });
        }

        function skipBase() {
            // Use default base, go directly to token entry
            showSection('tokenSection');
            document.getElementById('tokenInput').focus();
        }

        function showBaseResolved(data) {
            resolvedBaseName = data.baseName;
            document.getElementById('connectedBaseName').textContent = data.baseName + ' ' + data.baseEmoji;
            document.getElementById('baseIndicator').style.display = 'block';
            showSection('tokenSection');
            document.getElementById('tokenInput').focus();
        }

        function submitToken() {
            const token = document.getElementById('tokenInput').value.trim();
            if (!token) {
                showError('Please enter a handoff code');
                return;
            }
            webkit.messageHandlers.handoff.postMessage({
                action: 'submitToken',
                token: token
            });
        }

        function showAuthteam(data) {
            document.getElementById('productTitle').textContent = data.title;
            document.getElementById('linkCountInfo').textContent = data.linkCount + ' links';

            targetSequence = data.sequence;
            currentSequence = [];

            // Show target sequence
            const targetEl = document.getElementById('targetSequence');
            targetEl.innerHTML = targetSequence.map(c =>
                '<div class="sequence-dot ' + c + '"></div>'
            ).join('');

            // Clear user sequence
            document.getElementById('userSequence').innerHTML = '';

            // Reset verify button
            document.getElementById('verifyBtn').disabled = true;
            document.getElementById('verifyBtn').textContent = 'Complete Sequence First';

            showSection('authteamSection');
        }

        function colorTapped(color) {
            webkit.messageHandlers.handoff.postMessage({
                action: 'colorTapped',
                color: color
            });

            // Add to sequence
            if (currentSequence.length < targetSequence.length) {
                currentSequence.push(color);

                // Update display
                const userEl = document.getElementById('userSequence');
                userEl.innerHTML = currentSequence.map(c =>
                    '<div class="sequence-dot ' + c + '"></div>'
                ).join('');

                // Check if complete
                if (currentSequence.length === targetSequence.length) {
                    // Check if correct
                    const correct = currentSequence.every((c, i) => c === targetSequence[i]);
                    if (correct) {
                        document.getElementById('verifyBtn').disabled = false;
                        document.getElementById('verifyBtn').textContent = 'Verify & Connect';
                    } else {
                        // Wrong sequence, reset
                        setTimeout(() => {
                            showError('Incorrect sequence. Try again!');
                            currentSequence = [];
                            userEl.innerHTML = '';
                        }, 500);
                    }
                }
            }
        }

        function verifySequence() {
            webkit.messageHandlers.handoff.postMessage({ action: 'verifySequence' });
        }

        function showPurchase(data) {
            document.getElementById('purchaseTitle').textContent = data.title;
            showSection('purchaseSection');
        }

        function completePurchase() {
            webkit.messageHandlers.handoff.postMessage({ action: 'completePurchase' });
        }

        function showSuccess(data) {
            document.getElementById('emojicodeDisplay').textContent = data.emojicode;
            showSection('successSection');
        }

        function copyEmojicode() {
            const emojicode = document.getElementById('emojicodeDisplay').textContent;
            navigator.clipboard.writeText(emojicode).then(() => {
                alert('Emojicode copied!');
            });
        }

        function done() {
            webkit.messageHandlers.handoff.postMessage({ action: 'cancel' });
        }

        function cancel() {
            webkit.messageHandlers.handoff.postMessage({ action: 'cancel' });
        }

        function showError(message) {
            const el = document.getElementById('errorDisplay');
            el.textContent = message;
            el.classList.remove('hidden');
            setTimeout(() => el.classList.add('hidden'), 5000);
        }

        // Focus input on load
        setTimeout(() => {
            if (preloadedBase) {
                // Base was preloaded, will be resolved by Swift
            } else if (!preloadedToken) {
                document.getElementById('baseInput').focus();
            }
        }, 300);
    </script>
</body>
</html>
"""
    }
}

#endif

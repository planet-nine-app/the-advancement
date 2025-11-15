//
//  EnchantmentEmporiumViewController.swift
//  The Advancement
//
//  The Enchantment Emporium - Cast MAGIC spells to create Planet Nine services
//

#if os(iOS)
import UIKit
import WebKit

class EnchantmentEmporiumViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {

    private var webView: WKWebView!
    private let sessionless = Sessionless()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "✨ Enchantment Emporium"
        view.backgroundColor = UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)

        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        // Setup WebView
        setupWebView()

        NSLog("EMPORIUM: ✨ Enchantment Emporium loaded")
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "emporium")
    }

    private func setupWebView() {
        let contentController = WKUserContentController()
        contentController.add(self, name: "emporium")

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

        // Load HTML
        if let htmlPath = Bundle.main.path(forResource: "EnchantmentEmporium", ofType: "html"),
           let htmlString = try? String(contentsOfFile: htmlPath, encoding: .utf8) {
            let baseURL = URL(fileURLWithPath: htmlPath).deletingLastPathComponent()
            webView.loadHTMLString(htmlString, baseURL: baseURL)
            NSLog("EMPORIUM: ✨ Loaded EnchantmentEmporium.html")
        } else {
            NSLog("EMPORIUM: ❌ Failed to load EnchantmentEmporium.html")
        }
    }

    @objc private func closeTapped() {
        NSLog("EMPORIUM: Close button tapped")
        dismiss(animated: true)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "emporium",
              let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String else {
            NSLog("EMPORIUM: ❌ Invalid message")
            return
        }

        NSLog("EMPORIUM: 📨 Received action: %@", action)

        switch action {
        case "getUserStats":
            sendUserStats()

        case "castEnchantment":
            guard let enchantmentId = messageBody["enchantmentId"] as? String,
                  let paymentMethod = messageBody["paymentMethod"] as? String else {
                NSLog("EMPORIUM: ❌ Missing enchantmentId or paymentMethod")
                return
            }
            castEnchantment(enchantmentId: enchantmentId, paymentMethod: paymentMethod)

        case "copyEmojicode":
            guard let emojicode = messageBody["emojicode"] as? String else { return }
            UIPasteboard.general.string = emojicode
            NSLog("EMPORIUM: 📋 Copied emojicode to clipboard")
            showAlert(title: "Copied!", message: "Emojicode copied to clipboard")

        case "shareEmojicode":
            guard let emojicode = messageBody["emojicode"] as? String else { return }
            shareEmojicode(emojicode)

        case "viewTapestry":
            guard let emojicode = messageBody["emojicode"] as? String else { return }
            viewTapestry(emojicode)

        default:
            NSLog("EMPORIUM: ⚠️ Unknown action: %@", action)
        }
    }

    // MARK: - User Stats

    private func sendUserStats() {
        NSLog("EMPORIUM: 📊 Getting user stats...")

        // Get link count from carrierBag
        var linkCount = 0
        if let carrierBag = SharedUserDefaults.getCarrierBag(),
           let links = carrierBag["links"] as? [[String: Any]] {
            linkCount = links.count
        }

        // TODO: Get actual MP/nineum from MAGIC protocol
        // For now, using placeholder values
        let mp = 150
        let nineum = 500

        let stats: [String: Any] = [
            "linkCount": linkCount,
            "mp": mp,
            "nineum": nineum
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: stats, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            NSLog("EMPORIUM: ❌ Failed to serialize stats")
            return
        }

        let javascript = "window.updateUserStats(\(jsonString));"
        webView.evaluateJavaScript(javascript) { _, error in
            if let error = error {
                NSLog("EMPORIUM: ❌ Error sending stats: %@", error.localizedDescription)
            } else {
                NSLog("EMPORIUM: ✅ Stats sent: %d links, %d MP", linkCount, mp)
            }
        }
    }

    // MARK: - Cast Enchantment

    private func castEnchantment(enchantmentId: String, paymentMethod: String) {
        NSLog("EMPORIUM: ✨ Casting enchantment: %@ with payment method: %@", enchantmentId, paymentMethod)

        // Route to appropriate MAGIC spell
        switch enchantmentId {
        case "glyphenge":
            castGlyphengeSpell(paymentMethod: paymentMethod)
        case "linktree-importer":
            castGlyphtreeSpell(paymentMethod: paymentMethod)
        default:
            NSLog("EMPORIUM: ❌ Unknown enchantment: %@", enchantmentId)
            showErrorJS("Unknown enchantment")
        }
    }

    // MARK: - MAGIC Spell Casting

    private func castGlyphengeSpell(paymentMethod: String) {
        NSLog("EMPORIUM: 🔮 Casting glyphenge MAGIC spell...")

        // 1. Validate requirements
        guard let carrierBag = SharedUserDefaults.getCarrierBag(),
              let links = carrierBag["links"] as? [[String: Any]],
              !links.isEmpty else {
            NSLog("EMPORIUM: ❌ No links in carrierBag")
            showErrorJS("You need at least one link in your carrierBag to cast Glyphenge")
            return
        }

        NSLog("EMPORIUM: ✅ Found %d links in carrierBag", links.count)

        // 2. Get sessionless keys for caster authentication
        guard let keys = sessionless.getKeys() else {
            NSLog("EMPORIUM: ❌ No sessionless keys")
            showErrorJS("Authentication error")
            return
        }

        // 3. Build MAGIC spell request
        let glyphengeServiceURL = "http://localhost:5125"
        let spellEndpoint = "\(glyphengeServiceURL)/magic/spell/glyphenge"

        guard let spellURL = URL(string: spellEndpoint) else {
            NSLog("EMPORIUM: ❌ Invalid spell URL")
            showErrorJS("Invalid Glyphenge service URL")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey  // caster signature: timestamp + pubKey

        guard let signature = sessionless.sign(message: message) else {
            NSLog("EMPORIUM: ❌ Failed to sign spell cast")
            showErrorJS("Signature error")
            return
        }

        var spellRequest = URLRequest(url: spellURL)
        spellRequest.httpMethod = "POST"
        spellRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let spellPayload: [String: Any] = [
            "caster": [
                "pubKey": keys.publicKey,
                "timestamp": timestamp,
                "signature": signature
            ],
            "payload": [
                "paymentMethod": paymentMethod,
                "links": links,
                "title": "My Glyphenge"
            ]
        ]

        do {
            spellRequest.httpBody = try JSONSerialization.data(withJSONObject: spellPayload)
        } catch {
            NSLog("EMPORIUM: ❌ Failed to serialize spell request")
            showErrorJS("Failed to prepare spell")
            return
        }

        NSLog("EMPORIUM: ✨ Casting glyphenge spell...")

        // 4. Cast the spell (atomic operation: payment + SVG + BDO + carrierBag)
        URLSession.shared.dataTask(with: spellRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("EMPORIUM: ❌ Spell cast error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showErrorJS("Spell failed: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("EMPORIUM: ❌ Invalid spell response")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    NSLog("EMPORIUM: Response: %@", responseString)
                }
                DispatchQueue.main.async {
                    self.showErrorJS("Invalid spell response")
                }
                return
            }

            guard let success = json["success"] as? Bool, success else {
                let errorMsg = json["error"] as? String ?? "Spell failed"
                NSLog("EMPORIUM: ❌ Spell failed: %@", errorMsg)
                DispatchQueue.main.async {
                    self.showErrorJS(errorMsg)
                }
                return
            }

            guard let emojicode = json["emojicode"] as? String else {
                NSLog("EMPORIUM: ❌ No emojicode in response")
                DispatchQueue.main.async {
                    self.showErrorJS("Spell succeeded but no emojicode returned")
                }
                return
            }

            NSLog("EMPORIUM: ✅ Spell cast successful! Emojicode: %@", emojicode)

            DispatchQueue.main.async {
                self.showSuccessJS(emojicode: emojicode)
            }

        }.resume()
    }

    private func castGlyphtreeSpell(paymentMethod: String) {
        NSLog("EMPORIUM: 🌳 Casting glyphtree MAGIC spell...")

        // Prompt for Linktree URL
        let alert = UIAlertController(
            title: "🌳 Linktree Importer",
            message: "Enter your linktr.ee URL to import all your links",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "https://linktr.ee/username"
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Import", style: .default) { [weak self] _ in
            guard let self = self,
                  let linktreeUrl = alert.textFields?.first?.text,
                  !linktreeUrl.isEmpty else {
                NSLog("EMPORIUM: ❌ No URL provided")
                return
            }

            self.executeGlyphtreeSpell(linktreeUrl: linktreeUrl, paymentMethod: paymentMethod)
        })

        present(alert, animated: true)
    }

    private func executeGlyphtreeSpell(linktreeUrl: String, paymentMethod: String) {
        NSLog("EMPORIUM: 🔮 Executing glyphtree spell for: %@", linktreeUrl)

        // Validate URL
        guard let url = URL(string: linktreeUrl),
              url.host?.contains("linktr.ee") == true else {
            NSLog("EMPORIUM: ❌ Invalid Linktree URL")
            showErrorJS("Please enter a valid linktr.ee URL")
            return
        }

        // Get sessionless keys for caster authentication
        guard let keys = sessionless.getKeys() else {
            NSLog("EMPORIUM: ❌ No sessionless keys")
            showErrorJS("Authentication error")
            return
        }

        // Build MAGIC spell request
        let glyphengeServiceURL = "http://localhost:5125"
        let spellEndpoint = "\(glyphengeServiceURL)/magic/spell/glyphtree"

        guard let spellURL = URL(string: spellEndpoint) else {
            NSLog("EMPORIUM: ❌ Invalid spell URL")
            showErrorJS("Invalid Glyphenge service URL")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey  // caster signature: timestamp + pubKey

        guard let signature = sessionless.sign(message: message) else {
            NSLog("EMPORIUM: ❌ Failed to sign spell cast")
            showErrorJS("Signature error")
            return
        }

        var spellRequest = URLRequest(url: spellURL)
        spellRequest.httpMethod = "POST"
        spellRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let spellPayload: [String: Any] = [
            "caster": [
                "pubKey": keys.publicKey,
                "timestamp": timestamp,
                "signature": signature
            ],
            "payload": [
                "paymentMethod": paymentMethod,
                "linktreeUrl": linktreeUrl
            ]
        ]

        do {
            spellRequest.httpBody = try JSONSerialization.data(withJSONObject: spellPayload)
        } catch {
            NSLog("EMPORIUM: ❌ Failed to serialize spell request")
            showErrorJS("Failed to prepare spell")
            return
        }

        NSLog("EMPORIUM: ✨ Casting glyphtree spell...")

        // Cast the spell (atomic operation: fetch + parse + payment + SVG + BDO + carrierBag)
        URLSession.shared.dataTask(with: spellRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("EMPORIUM: ❌ Spell cast error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showErrorJS("Spell failed: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("EMPORIUM: ❌ Invalid spell response")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    NSLog("EMPORIUM: Response: %@", responseString)
                }
                DispatchQueue.main.async {
                    self.showErrorJS("Invalid spell response")
                }
                return
            }

            guard let success = json["success"] as? Bool, success else {
                let errorMsg = json["error"] as? String ?? "Spell failed"
                NSLog("EMPORIUM: ❌ Spell failed: %@", errorMsg)
                DispatchQueue.main.async {
                    self.showErrorJS(errorMsg)
                }
                return
            }

            guard let emojicode = json["emojicode"] as? String,
                  let linkCount = json["linkCount"] as? Int else {
                NSLog("EMPORIUM: ❌ Missing data in response")
                DispatchQueue.main.async {
                    self.showErrorJS("Spell succeeded but incomplete response")
                }
                return
            }

            NSLog("EMPORIUM: ✅ Spell cast successful! Imported %d links, emojicode: %@", linkCount, emojicode)

            DispatchQueue.main.async {
                self.showSuccessJS(emojicode: emojicode)
            }

        }.resume()
    }

    // MARK: - JavaScript Communication

    private func showSuccessJS(emojicode: String) {
        let data: [String: Any] = [
            "emojicode": emojicode
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            NSLog("EMPORIUM: ❌ Failed to serialize success data")
            return
        }

        let javascript = "window.showSuccess(\(jsonString));"
        webView.evaluateJavaScript(javascript) { _, error in
            if let error = error {
                NSLog("EMPORIUM: ❌ Error showing success: %@", error.localizedDescription)
            } else {
                NSLog("EMPORIUM: ✅ Success view shown")
            }
        }
    }

    private func showErrorJS(_ message: String) {
        let escapedMessage = message.replacingOccurrences(of: "'", with: "\\'")
        let javascript = "window.showError('\(escapedMessage)');"
        webView.evaluateJavaScript(javascript) { _, error in
            if let error = error {
                NSLog("EMPORIUM: ❌ Error showing error: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Actions

    private func shareEmojicode(_ emojicode: String) {
        NSLog("EMPORIUM: 📤 Sharing emojicode: %@", emojicode)

        let text = "Check out my Glyphenge link tapestry! ✨\n\n\(emojicode)\n\nhttps://glyphenge.com?emojicode=\(emojicode)"

        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        present(activityVC, animated: true)
    }

    private func viewTapestry(_ emojicode: String) {
        NSLog("EMPORIUM: 👁️ Viewing tapestry: %@", emojicode)

        let urlString = "https://glyphenge.com?emojicode=\(emojicode)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("EMPORIUM: 🎨 Page loaded, injecting theme...")

        // Inject theme CSS variables into the WebView
        ThemeManager.shared.injectThemeIntoWebView(webView) { success in
            if success {
                NSLog("EMPORIUM: ✅ Theme injected successfully")
            } else {
                NSLog("EMPORIUM: ⚠️ Theme injection failed, using default CSS")
            }
        }
    }

}

#endif

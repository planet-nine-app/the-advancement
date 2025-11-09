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
            guard let enchantmentId = messageBody["enchantmentId"] as? String else {
                NSLog("EMPORIUM: ❌ Missing enchantmentId")
                return
            }
            castEnchantment(enchantmentId: enchantmentId)

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

    private func castEnchantment(enchantmentId: String) {
        NSLog("EMPORIUM: ✨ Casting enchantment: %@", enchantmentId)

        switch enchantmentId {
        case "glyphenge":
            castGlyphenge()
        case "linktree-importer":
            castLinktreeImporter()
        default:
            showErrorJS("Unknown enchantment: \(enchantmentId)")
        }
    }

    private func castGlyphenge() {
        NSLog("EMPORIUM: 🔮 Casting Glyphenge enchantment...")

        // 1. Validate requirements
        guard let carrierBag = SharedUserDefaults.getCarrierBag(),
              let links = carrierBag["links"] as? [[String: Any]],
              !links.isEmpty else {
            NSLog("EMPORIUM: ❌ No links in carrierBag")
            showErrorJS("You need at least one link in your carrierBag to cast Glyphenge")
            return
        }

        NSLog("EMPORIUM: ✅ Found %d links in carrierBag", links.count)

        // 2. Get user keys
        guard let userKeys = sessionless.getKeys() else {
            NSLog("EMPORIUM: ❌ Failed to get user keys")
            showErrorJS("Failed to get your authentication keys")
            return
        }

        // 3. Generate temporary keys for the Glyphenge BDO
        guard let tempKeys = sessionless.generateKeys() else {
            NSLog("EMPORIUM: ❌ Failed to generate temporary keys")
            showErrorJS("Failed to generate Glyphenge keys")
            return
        }

        let glyphengePubKey = tempKeys.publicKey
        NSLog("EMPORIUM: 🔑 Generated Glyphenge keys: %@...", String(glyphengePubKey.prefix(16)))

        // 4. Generate composite SVG for all links
        let compositeSVG = generateGlyphengeSVG(links: links)
        NSLog("EMPORIUM: 🎨 Generated composite SVG (%d characters)", compositeSVG.count)

        // 5. Create Glyphenge BDO data with top-level svgContent
        let glyphengeBDO: [String: Any] = [
            "title": "My Glyphenge",
            "type": "glyphenge",
            "svgContent": compositeSVG,
            "links": links,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        // 5. Create BDO via BDO service
        let bdoBaseURL = Configuration.bdoBaseURL
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        let hash = "The Advancement"

        // Sign: timestamp + pubKey + hash
        let createMessage = timestamp + glyphengePubKey + hash
        guard let createSignature = sessionless.signWithPrivateKey(message: createMessage, privateKey: tempKeys.privateKey) else {
            NSLog("EMPORIUM: ❌ Failed to sign create request")
            showErrorJS("Failed to sign BDO creation")
            return
        }

        let createEndpoint = "\(bdoBaseURL)/user/create"
        guard let createURL = URL(string: createEndpoint) else {
            NSLog("EMPORIUM: ❌ Invalid BDO URL")
            showErrorJS("Invalid BDO service URL")
            return
        }

        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "PUT"
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let createBody: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": glyphengePubKey,
            "hash": hash,
            "signature": createSignature,
            "bdo": glyphengeBDO
        ]

        do {
            createRequest.httpBody = try JSONSerialization.data(withJSONObject: createBody)
        } catch {
            NSLog("EMPORIUM: ❌ Failed to serialize create request")
            showErrorJS("Failed to prepare BDO creation")
            return
        }

        NSLog("EMPORIUM: 🌐 Creating Glyphenge BDO...")

        // Execute create request
        URLSession.shared.dataTask(with: createRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("EMPORIUM: ❌ Network error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showErrorJS("Network error: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let bdoUUID = json["uuid"] as? String else {
                NSLog("EMPORIUM: ❌ Failed to create BDO")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    NSLog("EMPORIUM: Response: %@", responseString)
                }
                DispatchQueue.main.async {
                    self.showErrorJS("Failed to create Glyphenge BDO")
                }
                return
            }

            NSLog("EMPORIUM: ✅ BDO created with UUID: %@", bdoUUID)

            // 6. Make BDO public to get emojicode
            self.makeGlyphengeBDOPublic(uuid: bdoUUID, pubKey: glyphengePubKey, privateKey: tempKeys.privateKey, bdoData: glyphengeBDO)

        }.resume()
    }

    private func makeGlyphengeBDOPublic(uuid: String, pubKey: String, privateKey: String, bdoData: [String: Any]) {
        NSLog("EMPORIUM: 🌍 Making Glyphenge BDO public...")

        let bdoBaseURL = Configuration.bdoBaseURL
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        let hash = "The Advancement"

        // Sign: timestamp + uuid + hash
        let updateMessage = timestamp + uuid + hash
        guard let updateSignature = sessionless.signWithPrivateKey(message: updateMessage, privateKey: privateKey) else {
            NSLog("EMPORIUM: ❌ Failed to sign update request")
            showErrorJS("Failed to sign BDO update")
            return
        }

        let updateEndpoint = "\(bdoBaseURL)/user/\(uuid)/bdo"
        guard let updateURL = URL(string: updateEndpoint) else {
            NSLog("EMPORIUM: ❌ Invalid update URL")
            showErrorJS("Invalid BDO update URL")
            return
        }

        var updateRequest = URLRequest(url: updateURL)
        updateRequest.httpMethod = "PUT"
        updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updateBody: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": pubKey,
            "hash": hash,
            "signature": updateSignature,
            "bdo": bdoData,
            "public": true  // This generates the emojicode!
        ]

        do {
            updateRequest.httpBody = try JSONSerialization.data(withJSONObject: updateBody)
        } catch {
            NSLog("EMPORIUM: ❌ Failed to serialize update request")
            showErrorJS("Failed to prepare BDO update")
            return
        }

        // Execute update request
        URLSession.shared.dataTask(with: updateRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("EMPORIUM: ❌ Network error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showErrorJS("Network error: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let emojicode = json["emojiShortcode"] as? String else {
                NSLog("EMPORIUM: ❌ Failed to make BDO public")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    NSLog("EMPORIUM: Response: %@", responseString)
                }
                DispatchQueue.main.async {
                    self.showErrorJS("Failed to generate emojicode")
                }
                return
            }

            NSLog("EMPORIUM: ✅ Emojicode generated: %@", emojicode)

            // 7. Save to carrierBag "store" collection
            DispatchQueue.main.async {
                self.saveGlyphengeToStore(emojicode: emojicode)

                // 8. Show success
                self.showSuccessJS(emojicode: emojicode)
            }

        }.resume()
    }

    private func saveGlyphengeToStore(emojicode: String) {
        NSLog("EMPORIUM: 💼 Saving Glyphenge to carrierBag store...")

        let glyphengeRecord: [String: Any] = [
            "type": "glyphenge",
            "emojicode": emojicode,
            "url": "https://glyphenge.com?emojicode=\(emojicode)",
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        SharedUserDefaults.addToCarrierBagCollection("store", item: glyphengeRecord)
        NSLog("EMPORIUM: ✅ Glyphenge saved to store collection")
    }

    // MARK: - Linktree Importer

    private func castLinktreeImporter() {
        NSLog("EMPORIUM: 🌳 Casting Linktree Importer enchantment...")

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
                  let urlString = alert.textFields?.first?.text,
                  !urlString.isEmpty else {
                NSLog("EMPORIUM: ❌ No URL provided")
                return
            }

            self.importFromLinktree(urlString: urlString)
        })

        present(alert, animated: true)
    }

    private func importFromLinktree(urlString: String) {
        NSLog("EMPORIUM: 📎 Importing from: %@", urlString)

        // Validate URL
        guard let url = URL(string: urlString),
              url.host?.contains("linktr.ee") == true else {
            NSLog("EMPORIUM: ❌ Invalid Linktree URL")
            showErrorJS("Please enter a valid linktr.ee URL")
            return
        }

        // Fetch Linktree page
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        NSLog("EMPORIUM: 🌐 Fetching Linktree page...")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("EMPORIUM: ❌ Fetch error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showErrorJS("Failed to fetch Linktree page: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let html = String(data: data, encoding: .utf8) else {
                NSLog("EMPORIUM: ❌ No data received")
                DispatchQueue.main.async {
                    self.showErrorJS("Failed to load Linktree page")
                }
                return
            }

            NSLog("EMPORIUM: ✅ Page fetched (%d characters)", html.count)

            // Parse links from HTML
            self.parseLinktreeLinks(html: html, sourceUrl: urlString)

        }.resume()
    }

    private func parseLinktreeLinks(html: String, sourceUrl: String) {
        NSLog("EMPORIUM: 🔍 Parsing Linktree data...")

        // Extract __NEXT_DATA__ script tag
        guard let regex = try? NSRegularExpression(pattern: "<script id=\"__NEXT_DATA__\"[^>]*>(.*?)</script>", options: .dotMatchesLineSeparators),
              let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
              let jsonRange = Range(match.range(at: 1), in: html) else {
            NSLog("EMPORIUM: ❌ Could not find __NEXT_DATA__ in page")
            DispatchQueue.main.async {
                self.showErrorJS("Could not extract data from Linktree page - format may have changed")
            }
            return
        }

        let jsonString = String(html[jsonRange])
        NSLog("EMPORIUM: ✅ Found __NEXT_DATA__ (%d characters)", jsonString.count)

        // Parse JSON
        guard let jsonData = jsonString.data(using: .utf8),
              let nextData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let props = nextData["props"] as? [String: Any],
              let pageProps = props["pageProps"] as? [String: Any],
              let account = pageProps["account"] as? [String: Any] else {
            NSLog("EMPORIUM: ❌ Could not parse JSON structure")
            DispatchQueue.main.async {
                self.showErrorJS("Could not parse Linktree data structure")
            }
            return
        }

        let username = account["username"] as? String ?? "Unknown"
        let pageTitle = account["pageTitle"] as? String ?? username

        guard let linktreeLinks = account["links"] as? [[String: Any]],
              !linktreeLinks.isEmpty else {
            NSLog("EMPORIUM: ❌ No links found in account")
            DispatchQueue.main.async {
                self.showErrorJS("No links found in Linktree account")
            }
            return
        }

        NSLog("EMPORIUM: 📊 Account: %@", username)
        NSLog("EMPORIUM: 📝 Title: %@", pageTitle)
        NSLog("EMPORIUM: ✅ Found %d links", linktreeLinks.count)

        // Convert to standard link format
        var links: [[String: Any]] = []
        for (index, link) in linktreeLinks.enumerated() {
            if let title = link["title"] as? String,
               let url = link["url"] as? String,
               !url.isEmpty {
                links.append([
                    "title": title,
                    "url": url,
                    "savedAt": ISO8601DateFormatter().string(from: Date())
                ])
                NSLog("EMPORIUM:    %d. %@", index + 1, title)
                NSLog("EMPORIUM:       → %@", url)
            }
        }

        if links.isEmpty {
            NSLog("EMPORIUM: ❌ No valid links found")
            DispatchQueue.main.async {
                self.showErrorJS("No valid links found in Linktree page")
            }
            return
        }

        NSLog("EMPORIUM: ✅ Extracted %d valid links", links.count)

        // Create Glyphenge BDO from imported links
        DispatchQueue.main.async {
            self.createGlyphengeFromLinks(links: links, title: "\(username)'s Links", source: sourceUrl)
        }
    }

    private func createGlyphengeFromLinks(links: [[String: Any]], title: String, source: String) {
        NSLog("EMPORIUM: 🎨 Creating Glyphenge from %d imported links...", links.count)

        // Generate temporary keys for the Glyphenge BDO
        guard let tempKeys = sessionless.generateKeys() else {
            NSLog("EMPORIUM: ❌ Failed to generate temporary keys")
            showErrorJS("Failed to generate Glyphenge keys")
            return
        }

        let glyphengePubKey = tempKeys.publicKey
        NSLog("EMPORIUM: 🔑 Generated Glyphenge keys: %@...", String(glyphengePubKey.prefix(16)))

        // Generate composite SVG for all links
        let compositeSVG = generateGlyphengeSVG(links: links)
        NSLog("EMPORIUM: 🎨 Generated composite SVG (%d characters)", compositeSVG.count)

        // Create Glyphenge BDO data with top-level svgContent
        let glyphengeBDO: [String: Any] = [
            "title": title,
            "type": "glyphenge",
            "svgContent": compositeSVG,
            "links": links,
            "source": "linktree",
            "sourceUrl": source,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        // Create BDO via BDO service
        let bdoBaseURL = Configuration.bdoBaseURL
        let timestamp = String(Int64(Date().timeIntervalSince1970 * 1000))
        let hash = "The Advancement"

        // Sign: timestamp + pubKey + hash
        let createMessage = timestamp + glyphengePubKey + hash
        guard let createSignature = sessionless.signWithPrivateKey(message: createMessage, privateKey: tempKeys.privateKey) else {
            NSLog("EMPORIUM: ❌ Failed to sign create request")
            showErrorJS("Failed to sign BDO creation")
            return
        }

        let createEndpoint = "\(bdoBaseURL)/user/create"
        guard let createURL = URL(string: createEndpoint) else {
            NSLog("EMPORIUM: ❌ Invalid BDO URL")
            showErrorJS("Invalid BDO service URL")
            return
        }

        var createRequest = URLRequest(url: createURL)
        createRequest.httpMethod = "PUT"
        createRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let createBody: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": glyphengePubKey,
            "hash": hash,
            "signature": createSignature,
            "bdo": glyphengeBDO
        ]

        do {
            createRequest.httpBody = try JSONSerialization.data(withJSONObject: createBody)
        } catch {
            NSLog("EMPORIUM: ❌ Failed to serialize create request")
            showErrorJS("Failed to prepare BDO creation")
            return
        }

        NSLog("EMPORIUM: 🌐 Creating Glyphenge BDO from Linktree import...")

        // Execute create request
        URLSession.shared.dataTask(with: createRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("EMPORIUM: ❌ Network error: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.showErrorJS("Network error: \(error.localizedDescription)")
                }
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let bdoUUID = json["uuid"] as? String else {
                NSLog("EMPORIUM: ❌ Failed to create BDO")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    NSLog("EMPORIUM: Response: %@", responseString)
                }
                DispatchQueue.main.async {
                    self.showErrorJS("Failed to create Glyphenge BDO")
                }
                return
            }

            NSLog("EMPORIUM: ✅ BDO created with UUID: %@", bdoUUID)

            // Make BDO public to get emojicode
            self.makeGlyphengeBDOPublic(uuid: bdoUUID, pubKey: glyphengePubKey, privateKey: tempKeys.privateKey, bdoData: glyphengeBDO)

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

    // MARK: - Glyphenge SVG Generation

    private func generateGlyphengeSVG(links: [[String: Any]]) -> String {
        let linkCount = links.count

        if linkCount <= 6 {
            return generateCompactSVG(links: links)
        } else if linkCount <= 13 {
            return generateGridSVG(links: links)
        } else {
            return generateDenseSVG(links: links)
        }
    }

    private func generateCompactSVG(links: [[String: Any]]) -> String {
        let height = max(400, links.count * 110 + 60)
        let gradients = [
            ["#10b981", "#059669"],
            ["#3b82f6", "#2563eb"],
            ["#8b5cf6", "#7c3aed"],
            ["#ec4899", "#db2777"],
            ["#f59e0b", "#d97706"],
            ["#a78bfa", "#8b5cf6"]
        ]

        var linkElements = ""
        for (index, link) in links.enumerated() {
            let y = 60 + (index * 110)
            let title = link["title"] as? String ?? "Untitled"
            let url = link["url"] as? String ?? "#"
            let truncatedTitle = title.count > 30 ? String(title.prefix(30)) + "..." : title

            let gradient = gradients[index % gradients.count]
            let gradId = "grad\(index)"

            linkElements += """
            <defs>
                <linearGradient id="\(gradId)" x1="0%" y1="0%" x2="100%" y2="0%">
                    <stop offset="0%" style="stop-color:\(gradient[0]);stop-opacity:1" />
                    <stop offset="100%" style="stop-color:\(gradient[1]);stop-opacity:1" />
                </linearGradient>
            </defs>

            <a href="\(escapeXML(url))" target="_blank">
                <rect x="50" y="\(y)" width="600" height="90" rx="15" fill="url(#\(gradId))" opacity="0.9"/>
                <text x="90" y="\(y + 40)" fill="white" font-size="20" font-weight="bold">\(escapeXML(truncatedTitle))</text>
                <text x="90" y="\(y + 65)" fill="rgba(255,255,255,0.8)" font-size="14">🔗 Tap to open</text>
                <text x="600" y="\(y + 50)" fill="white" font-size="30">→</text>
            </a>
            """
        }

        return """
        <svg width="700" height="\(height)" viewBox="0 0 700 \(height)" xmlns="http://www.w3.org/2000/svg">
            <rect width="700" height="\(height)" fill="#f9fafb"/>

            <text x="350" y="35" fill="#1f2937" font-size="24" font-weight="bold" text-anchor="middle">
                My Links
            </text>

            \(linkElements)
        </svg>
        """
    }

    private func generateGridSVG(links: [[String: Any]]) -> String {
        let rows = (links.count + 1) / 2
        let height = max(400, rows * 100 + 100)
        let gradients = [
            ["#10b981", "#059669"],
            ["#3b82f6", "#2563eb"],
            ["#8b5cf6", "#7c3aed"],
            ["#ec4899", "#db2777"],
            ["#f59e0b", "#d97706"],
            ["#a78bfa", "#8b5cf6"]
        ]

        var linkElements = ""
        for (index, link) in links.enumerated() {
            let col = index % 2
            let row = index / 2
            let x = col == 0 ? 40 : 370
            let y = 80 + (row * 100)

            let title = link["title"] as? String ?? "Untitled"
            let url = link["url"] as? String ?? "#"
            let truncatedTitle = title.count > 15 ? String(title.prefix(15)) + "..." : title

            let gradient = gradients[index % gradients.count]
            let gradId = "grad\(index)"

            linkElements += """
            <defs>
                <linearGradient id="\(gradId)" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style="stop-color:\(gradient[0]);stop-opacity:1" />
                    <stop offset="100%" style="stop-color:\(gradient[1]);stop-opacity:1" />
                </linearGradient>
            </defs>

            <a href="\(escapeXML(url))" target="_blank">
                <rect x="\(x)" y="\(y)" width="290" height="80" rx="12" fill="url(#\(gradId))" opacity="0.9"/>
                <text x="\(x + 20)" y="\(y + 35)" fill="white" font-size="16" font-weight="bold">\(escapeXML(truncatedTitle))</text>
                <text x="\(x + 20)" y="\(y + 55)" fill="rgba(255,255,255,0.8)" font-size="12">🔗 Click</text>
            </a>
            """
        }

        return """
        <svg width="700" height="\(height)" viewBox="0 0 700 \(height)" xmlns="http://www.w3.org/2000/svg">
            <rect width="700" height="\(height)" fill="#f9fafb"/>

            <text x="350" y="40" fill="#1f2937" font-size="24" font-weight="bold" text-anchor="middle">
                My Links
            </text>

            \(linkElements)
        </svg>
        """
    }

    private func generateDenseSVG(links: [[String: Any]]) -> String {
        let rows = (links.count + 2) / 3
        let height = max(400, rows * 80 + 100)
        let gradients = [
            ["#10b981", "#059669"],
            ["#3b82f6", "#2563eb"],
            ["#8b5cf6", "#7c3aed"],
            ["#ec4899", "#db2777"],
            ["#f59e0b", "#d97706"],
            ["#a78bfa", "#8b5cf6"]
        ]

        var linkElements = ""
        for (index, link) in links.enumerated() {
            let col = index % 3
            let row = index / 3
            let x = 30 + (col * 220)
            let y = 80 + (row * 80)

            let title = link["title"] as? String ?? "Untitled"
            let url = link["url"] as? String ?? "#"
            let truncatedTitle = title.count > 12 ? String(title.prefix(12)) + "..." : title

            let gradient = gradients[index % gradients.count]
            let gradId = "grad\(index)"

            linkElements += """
            <defs>
                <linearGradient id="\(gradId)" x1="0%" y1="0%" x2="100%" y2="100%">
                    <stop offset="0%" style="stop-color:\(gradient[0]);stop-opacity:1" />
                    <stop offset="100%" style="stop-color:\(gradient[1]);stop-opacity:1" />
                </linearGradient>
            </defs>

            <a href="\(escapeXML(url))" target="_blank">
                <rect x="\(x)" y="\(y)" width="190" height="65" rx="10" fill="url(#\(gradId))" opacity="0.9"/>
                <text x="\(x + 15)" y="\(y + 30)" fill="white" font-size="14" font-weight="bold">\(escapeXML(truncatedTitle))</text>
                <text x="\(x + 15)" y="\(y + 48)" fill="rgba(255,255,255,0.8)" font-size="11">🔗</text>
            </a>
            """
        }

        return """
        <svg width="700" height="\(height)" viewBox="0 0 700 \(height)" xmlns="http://www.w3.org/2000/svg">
            <rect width="700" height="\(height)" fill="#f9fafb"/>

            <text x="350" y="40" fill="#1f2937" font-size="22" font-weight="bold" text-anchor="middle">
                My Links
            </text>

            \(linkElements)
        </svg>
        """
    }

    private func escapeXML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Sessionless Extension for Custom Key Signing

extension Sessionless {
    func signWithPrivateKey(message: String, privateKey: String) -> String? {
        guard let signJS = jsContext?.objectForKeyedSubscript("globalThis")?.objectForKeyedSubscript("sessionless")?.objectForKeyedSubscript("sign") else {
            NSLog("SESSIONLESS: ❌ Cannot sign: signJS not available")
            return nil
        }

        guard let signatureJS = signJS.call(withArguments: [message, privateKey]) else {
            NSLog("SESSIONLESS: ❌ Failed to call signJS")
            return nil
        }

        return signatureJS.toString()
    }
}

#endif

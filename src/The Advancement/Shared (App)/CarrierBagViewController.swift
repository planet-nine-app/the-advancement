//
//  CarrierBagViewController.swift
//  The Advancement
//
//  HTML-based carrier bag view showing all collections
//

#if os(iOS)
import UIKit
import WebKit

class CarrierBagViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {

    private var webView: WKWebView!
    private var carrierBagData: [String: Any] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "🎒 Carrier Bag"
        view.backgroundColor = UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0) // Match HTML background

        // Setup navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        // Setup WebView
        setupWebView()

        // Load initial data
        loadCarrierBagData()

        // Observe app becoming active to refresh
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        NSLog("ADVANCEAPP: 🎒 CarrierBagViewController loaded (HTML-based)")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCarrierBagData()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "itemSelected")
    }

    private func setupWebView() {
        let contentController = WKUserContentController()

        // Register message handler for item selection
        contentController.add(self, name: "itemSelected")

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
        if let htmlPath = Bundle.main.path(forResource: "CarrierBag", ofType: "html"),
           let htmlString = try? String(contentsOfFile: htmlPath, encoding: .utf8) {
            let baseURL = URL(fileURLWithPath: htmlPath).deletingLastPathComponent()
            webView.loadHTMLString(htmlString, baseURL: baseURL)
            NSLog("ADVANCEAPP: 🎒 Loaded CarrierBag.html")
        } else {
            NSLog("ADVANCEAPP: ❌ Failed to load CarrierBag.html")
        }
    }

    @objc private func appBecameActive() {
        NSLog("ADVANCEAPP: 🎒 App became active, refreshing carrier bag")
        loadCarrierBagData()
    }

    @objc private func refreshTapped() {
        NSLog("ADVANCEAPP: 🎒 Refresh button tapped")
        loadCarrierBagData()
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP: 🎒 Close button tapped")
        dismiss(animated: true)
    }

    private func loadCarrierBagData() {
        NSLog("ADVANCEAPP: 🎒 Loading carrier bag data from SharedUserDefaults...")

        // Load from SharedUserDefaults (updated by AdvanceKey)
        if let carrierBag = SharedUserDefaults.getCarrierBag() {
            NSLog("ADVANCEAPP: 🎒 Found carrier bag with %d collections", carrierBag.keys.count)
            carrierBagData = carrierBag
            updateWebView()
        } else {
            NSLog("ADVANCEAPP: 🎒 No carrier bag found, creating empty one")
            let emptyCarrierBag = SharedUserDefaults.createEmptyCarrierBag()
            SharedUserDefaults.saveCarrierBag(emptyCarrierBag)
            carrierBagData = emptyCarrierBag
            updateWebView()
        }
    }

    private func updateWebView() {
        // Convert carrier bag to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: carrierBagData, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            NSLog("ADVANCEAPP: ❌ Failed to serialize carrier bag data")
            return
        }

        // Escape for JavaScript
        let escapedJson = jsonString.replacingOccurrences(of: "\\", with: "\\\\")
                                    .replacingOccurrences(of: "'", with: "\\'")
                                    .replacingOccurrences(of: "\n", with: "\\n")
                                    .replacingOccurrences(of: "\r", with: "\\r")

        let javascript = "window.updateCarrierBag(\(jsonString));"

        webView.evaluateJavaScript(javascript) { result, error in
            if let error = error {
                NSLog("ADVANCEAPP: ❌ Error updating carrier bag in WebView: %@", error.localizedDescription)
            } else {
                NSLog("ADVANCEAPP: ✅ Carrier bag updated in WebView")
            }
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "itemSelected" else { return }

        guard let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String,
              action == "select",
              let collectionName = messageBody["collection"] as? String,
              let index = messageBody["index"] as? Int,
              let item = messageBody["item"] as? [String: Any] else {
            NSLog("ADVANCEAPP: ❌ Invalid item selection message")
            return
        }

        NSLog("ADVANCEAPP: 📖 Item selected from %@: %@", collectionName, item["title"] as? String ?? "Unknown")

        showItemDetails(item: item, collectionName: collectionName, index: index)
    }

    // MARK: - Item Details

    private func showItemDetails(item: [String: Any], collectionName: String, index: Int) {
        // Special handling for music items - open audio player
        if collectionName == "music" {
            // Try to get feedUrl from top level or metadata
            let feedUrl: String? = {
                if let url = item["feedUrl"] as? String {
                    return url
                } else if let metadata = item["metadata"] as? [String: Any],
                          let url = metadata["feedUrl"] as? String {
                    return url
                }
                return nil
            }()

            if let feedUrl = feedUrl {
                openMusicPlayer(feedUrl: feedUrl, title: item["title"] as? String ?? "Music")
                return
            }
        }

        let title = item["title"] as? String ?? "Item Details"
        var message = ""

        // Build message from item properties
        var details: [String] = []

        if let type = item["type"] as? String {
            details.append("Type: \(type)")
        }

        if let description = item["description"] as? String, !description.isEmpty {
            details.append("\n\(description)")
        }

        if let emojicode = item["emojicode"] as? String, !emojicode.isEmpty {
            details.append("\nEmojicode: \(emojicode)")
        }

        if let bdoPubKey = item["bdoPubKey"] as? String, !bdoPubKey.isEmpty {
            details.append("\nBDO PubKey: \(bdoPubKey.prefix(20))...")
        }

        if let savedAt = item["savedAt"] as? String {
            details.append("\nSaved: \(formatDate(savedAt))")
        }

        // Add other properties
        for (key, value) in item {
            if !["title", "type", "description", "emojicode", "bdoPubKey", "savedAt"].contains(key) {
                details.append("\n\(key): \(value)")
            }
        }

        message = details.joined()

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        // Add copy buttons
        if let emojicode = item["emojicode"] as? String, !emojicode.isEmpty {
            alert.addAction(UIAlertAction(title: "Copy Emojicode", style: .default) { _ in
                UIPasteboard.general.string = emojicode
                NSLog("ADVANCEAPP: 📋 Copied emojicode to clipboard")
            })
        }

        if let bdoPubKey = item["bdoPubKey"] as? String, !bdoPubKey.isEmpty {
            alert.addAction(UIAlertAction(title: "Copy BDO PubKey", style: .default) { _ in
                UIPasteboard.general.string = bdoPubKey
                NSLog("ADVANCEAPP: 📋 Copied BDO PubKey to clipboard")
            })
        }

        // Add remove option
        alert.addAction(UIAlertAction(title: "Remove from \(collectionName)", style: .destructive) { _ in
            self.removeItem(collectionName: collectionName, index: index)
        })

        alert.addAction(UIAlertAction(title: "OK", style: .default))

        present(alert, animated: true)
    }

    private func removeItem(collectionName: String, index: Int) {
        NSLog("ADVANCEAPP: 🗑️ Removing item at index %d from %@", index, collectionName)

        // Get current carrier bag
        guard var carrierBag = SharedUserDefaults.getCarrierBag() else {
            NSLog("ADVANCEAPP: ❌ No carrier bag found")
            return
        }

        // Remove item from collection
        if var collection = carrierBag[collectionName] as? [[String: Any]] {
            guard index >= 0 && index < collection.count else {
                NSLog("ADVANCEAPP: ❌ Invalid index")
                return
            }

            collection.remove(at: index)
            carrierBag[collectionName] = collection

            // Save updated carrier bag
            SharedUserDefaults.saveCarrierBag(carrierBag)

            // Reload
            loadCarrierBagData()

            NSLog("ADVANCEAPP: ✅ Item removed from %@", collectionName)
        }
    }

    private func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "Unknown date" }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
    }

    // MARK: - Music Player

    private func openMusicPlayer(feedUrl: String, title: String) {
        NSLog("ADVANCEAPP: 🎵 Opening music player for: %@", title)
        NSLog("ADVANCEAPP: 🎵 Feed URL: %@", feedUrl)

        // Create music player view controller
        let playerVC = MusicPlayerViewController()
        playerVC.feedUrl = feedUrl
        playerVC.feedTitle = title

        // Present as modal
        let navController = UINavigationController(rootViewController: playerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}

// MARK: - Music Player View Controller

class MusicPlayerViewController: UIViewController, WKNavigationDelegate {
    var feedUrl: String?
    var feedTitle: String?
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = feedTitle ?? "🎵 Music Player"
        view.backgroundColor = UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        // Setup WebView
        setupWebView()
    }

    private func setupWebView() {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

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

        // Load Dolores audio player
        loadAudioPlayer()
    }

    private func loadAudioPlayer() {
        guard let feedUrl = feedUrl else {
            NSLog("MUSICPLAYER: ❌ No feed URL provided")
            return
        }

        // Use Configuration for environment-aware Dolores URL
        let doloresUrl = Configuration.Dolores.audioPlayer(feedUrl: feedUrl)

        guard let url = URL(string: doloresUrl) else {
            NSLog("MUSICPLAYER: ❌ Invalid URL: %@", doloresUrl)
            return
        }

        NSLog("MUSICPLAYER: 🎵 Loading Dolores audio player: %@", doloresUrl)

        let request = URLRequest(url: url)
        webView.load(request)
    }

    @objc private func closeTapped() {
        NSLog("MUSICPLAYER: 🎵 Close button tapped")
        dismiss(animated: true)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("MUSICPLAYER: ✅ Audio player loaded successfully")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("MUSICPLAYER: ❌ Failed to load audio player: %@", error.localizedDescription)
    }
}

#endif

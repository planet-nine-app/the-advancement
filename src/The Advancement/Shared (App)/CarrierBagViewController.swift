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
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "addAddress")
    }

    private func setupWebView() {
        let contentController = WKUserContentController()

        // Register message handlers
        contentController.add(self, name: "itemSelected")
        contentController.add(self, name: "addAddress")

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

        let javascript = "window.updateCarrierBag(\(jsonString));"

        // Wait a bit to ensure WebView JavaScript is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            self.webView.evaluateJavaScript(javascript) { result, error in
                if let error = error {
                    NSLog("ADVANCEAPP: ❌ Error updating carrier bag in WebView: %@", error.localizedDescription)
                    // Retry once if failed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.webView.evaluateJavaScript(javascript) { _, retryError in
                            if let retryError = retryError {
                                NSLog("ADVANCEAPP: ❌ Retry also failed: %@", retryError.localizedDescription)
                            } else {
                                NSLog("ADVANCEAPP: ✅ Carrier bag updated in WebView (retry)")
                            }
                        }
                    }
                } else {
                    NSLog("ADVANCEAPP: ✅ Carrier bag updated in WebView")
                }
            }
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "itemSelected" {
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

            // Special handling for addresses
            if collectionName == "addresses" {
                showAddressDetails(address: item, index: index)
            } else {
                showItemDetails(item: item, collectionName: collectionName, index: index)
            }
        } else if message.name == "addAddress" {
            NSLog("ADVANCEAPP: 📮 Add new address requested")
            showAddressForm(address: nil, index: nil)
        }
    }

    // MARK: - Item Details

    private func showItemDetails(item: [String: Any], collectionName: String, index: Int) {
        NSLog("ADVANCEAPP: 🎵 showItemDetails called - collection: %@", collectionName)
        NSLog("ADVANCEAPP: 🎵 Item keys: %@", item.keys.joined(separator: ", "))

        // Special handling for music items - open audio player
        if collectionName == "music" {
            // Debug: Print entire item structure
            if let jsonData = try? JSONSerialization.data(withJSONObject: item, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                NSLog("ADVANCEAPP: 🎵 Full item structure:\n%@", jsonString)
            }

            // Try to get feedUrl from various possible locations
            let feedUrl: String? = {
                // Try top level first
                if let url = item["feedUrl"] as? String {
                    NSLog("ADVANCEAPP: 🎵 Found feedUrl at top level: %@", url)
                    return url
                }

                // Try item.metadata.feedUrl
                if let metadata = item["metadata"] as? [String: Any],
                   let url = metadata["feedUrl"] as? String {
                    NSLog("ADVANCEAPP: 🎵 Found feedUrl in metadata: %@", url)
                    return url
                }

                // Try item.bdoData.metadata.feedUrl (AdvanceKey save format)
                if let bdoData = item["bdoData"] as? [String: Any],
                   let metadata = bdoData["metadata"] as? [String: Any],
                   let url = metadata["feedUrl"] as? String {
                    NSLog("ADVANCEAPP: 🎵 Found feedUrl in bdoData.metadata: %@", url)
                    return url
                }

                NSLog("ADVANCEAPP: 🎵 No feedUrl found in any location!")
                return nil
            }()

            if let feedUrl = feedUrl {
                NSLog("ADVANCEAPP: 🎵 Opening music player with URL: %@", feedUrl)
                openMusicPlayer(feedUrl: feedUrl, title: item["title"] as? String ?? "Music")
                return
            } else {
                NSLog("ADVANCEAPP: ⚠️ Music item has no feedUrl, showing alert instead")
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

    // MARK: - Address Management

    private func showAddressDetails(address: [String: Any], index: Int) {
        NSLog("ADVANCEAPP: 📮 Showing address details at index %d", index)

        let name = address["name"] as? String ?? "Address"
        let recipientName = address["recipientName"] as? String ?? ""
        let street = address["street"] as? String ?? ""
        let street2 = address["street2"] as? String ?? ""
        let city = address["city"] as? String ?? ""
        let state = address["state"] as? String ?? ""
        let zip = address["zip"] as? String ?? ""
        let country = address["country"] as? String ?? "US"
        let phone = address["phone"] as? String ?? ""
        let isPrimary = address["isPrimary"] as? Bool ?? false

        var message = "\(recipientName)\n"
        message += "\(street)\n"
        if !street2.isEmpty {
            message += "\(street2)\n"
        }
        message += "\(city), \(state) \(zip)\n"
        message += "\(country)\n"
        if !phone.isEmpty {
            message += "\nPhone: \(phone)"
        }
        if isPrimary {
            message += "\n\n⭐️ Primary Address"
        }

        let alert = UIAlertController(title: name, message: message, preferredStyle: .alert)

        // Edit button
        alert.addAction(UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.showAddressForm(address: address, index: index)
        })

        // Set as Primary button (if not already primary)
        if !isPrimary {
            alert.addAction(UIAlertAction(title: "Set as Primary", style: .default) { [weak self] _ in
                self?.setAddressAsPrimary(index: index)
            })
        }

        // Delete button
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.removeAddress(index: index)
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func showAddressForm(address: [String: Any]?, index: Int?) {
        NSLog("ADVANCEAPP: 📮 Showing address form (editing: %@)", address != nil ? "yes" : "no")

        let formVC = AddressFormViewController()
        formVC.existingAddress = address
        formVC.addressIndex = index
        formVC.onSave = { [weak self] updatedAddress in
            self?.saveAddress(updatedAddress, at: index)
        }

        let navController = UINavigationController(rootViewController: formVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true)
    }

    private func saveAddress(_ address: [String: Any], at index: Int?) {
        NSLog("ADVANCEAPP: 📮 Saving address (index: %@)", index != nil ? String(index!) : "new")

        guard var carrierBag = SharedUserDefaults.getCarrierBag() else {
            NSLog("ADVANCEAPP: ❌ No carrier bag found")
            return
        }

        var addresses = carrierBag["addresses"] as? [[String: Any]] ?? []

        var addressToSave = address
        addressToSave["id"] = addressToSave["id"] ?? UUID().uuidString
        addressToSave["createdAt"] = addressToSave["createdAt"] ?? ISO8601DateFormatter().string(from: Date())

        if let index = index, index >= 0 && index < addresses.count {
            // Update existing address
            addresses[index] = addressToSave
            NSLog("ADVANCEAPP: ✅ Updated address at index %d", index)
        } else {
            // Add new address
            // If this is the first address, make it primary
            if addresses.isEmpty {
                addressToSave["isPrimary"] = true
            }
            addresses.append(addressToSave)
            NSLog("ADVANCEAPP: ✅ Added new address")
        }

        carrierBag["addresses"] = addresses
        SharedUserDefaults.saveCarrierBag(carrierBag)

        // Reload
        loadCarrierBagData()
    }

    private func setAddressAsPrimary(index: Int) {
        NSLog("ADVANCEAPP: 📮 Setting address at index %d as primary", index)

        guard var carrierBag = SharedUserDefaults.getCarrierBag() else {
            NSLog("ADVANCEAPP: ❌ No carrier bag found")
            return
        }

        var addresses = carrierBag["addresses"] as? [[String: Any]] ?? []

        // Remove primary from all addresses
        for i in 0..<addresses.count {
            addresses[i]["isPrimary"] = (i == index)
        }

        carrierBag["addresses"] = addresses
        SharedUserDefaults.saveCarrierBag(carrierBag)

        // Reload
        loadCarrierBagData()

        NSLog("ADVANCEAPP: ✅ Address set as primary")
    }

    private func removeAddress(index: Int) {
        NSLog("ADVANCEAPP: 🗑️ Removing address at index %d", index)

        guard var carrierBag = SharedUserDefaults.getCarrierBag() else {
            NSLog("ADVANCEAPP: ❌ No carrier bag found")
            return
        }

        var addresses = carrierBag["addresses"] as? [[String: Any]] ?? []

        guard index >= 0 && index < addresses.count else {
            NSLog("ADVANCEAPP: ❌ Invalid index")
            return
        }

        let wasPrimary = addresses[index]["isPrimary"] as? Bool ?? false
        addresses.remove(at: index)

        // If we removed the primary address, make the first one primary
        if wasPrimary && !addresses.isEmpty {
            addresses[0]["isPrimary"] = true
        }

        carrierBag["addresses"] = addresses
        SharedUserDefaults.saveCarrierBag(carrierBag)

        // Reload
        loadCarrierBagData()

        NSLog("ADVANCEAPP: ✅ Address removed")
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

// MARK: - Address Form View Controller

class AddressFormViewController: UIViewController, UITextFieldDelegate {
    var existingAddress: [String: Any]?
    var addressIndex: Int?
    var onSave: (([String: Any]) -> Void)?

    private var scrollView: UIScrollView!
    private var contentView: UIView!

    private var nameField: UITextField!
    private var recipientNameField: UITextField!
    private var streetField: UITextField!
    private var street2Field: UITextField!
    private var cityField: UITextField!
    private var stateField: UITextField!
    private var zipField: UITextField!
    private var countryField: UITextField!
    private var phoneField: UITextField!
    private var isPrimarySwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = existingAddress != nil ? "Edit Address" : "Add Address"
        view.backgroundColor = UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)

        // Navigation bar buttons
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )

        setupUI()
        populateFields()

        // Keyboard handling
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        // Scroll view for keyboard avoidance
        scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        // Create form fields
        var yOffset: CGFloat = 20

        // Name
        addLabel("Address Name (e.g., Home, Work)", at: &yOffset)
        nameField = addTextField(placeholder: "Home", at: &yOffset)

        // Recipient Name
        addLabel("Recipient Name", at: &yOffset)
        recipientNameField = addTextField(placeholder: "John Doe", at: &yOffset)

        // Street
        addLabel("Street Address", at: &yOffset)
        streetField = addTextField(placeholder: "123 Main St", at: &yOffset)

        // Street 2
        addLabel("Apt / Suite (Optional)", at: &yOffset)
        street2Field = addTextField(placeholder: "Apt 4B", at: &yOffset)

        // City
        addLabel("City", at: &yOffset)
        cityField = addTextField(placeholder: "San Francisco", at: &yOffset)

        // State
        addLabel("State / Province", at: &yOffset)
        stateField = addTextField(placeholder: "CA", at: &yOffset)

        // Zip
        addLabel("ZIP / Postal Code", at: &yOffset)
        zipField = addTextField(placeholder: "94102", at: &yOffset)
        zipField.keyboardType = .numbersAndPunctuation

        // Country
        addLabel("Country", at: &yOffset)
        countryField = addTextField(placeholder: "US", at: &yOffset)

        // Phone
        addLabel("Phone (Optional)", at: &yOffset)
        phoneField = addTextField(placeholder: "+1-555-123-4567", at: &yOffset)
        phoneField.keyboardType = .phonePad

        // Primary switch
        let primaryContainer = UIView()
        primaryContainer.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(primaryContainer)

        let primaryLabel = UILabel()
        primaryLabel.text = "Set as Primary Address"
        primaryLabel.textColor = .white
        primaryLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryContainer.addSubview(primaryLabel)

        isPrimarySwitch = UISwitch()
        isPrimarySwitch.translatesAutoresizingMaskIntoConstraints = false
        primaryContainer.addSubview(isPrimarySwitch)

        NSLayoutConstraint.activate([
            primaryContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            primaryContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            primaryContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            primaryContainer.heightAnchor.constraint(equalToConstant: 44),

            primaryLabel.leadingAnchor.constraint(equalTo: primaryContainer.leadingAnchor),
            primaryLabel.centerYAnchor.constraint(equalTo: primaryContainer.centerYAnchor),

            isPrimarySwitch.trailingAnchor.constraint(equalTo: primaryContainer.trailingAnchor),
            isPrimarySwitch.centerYAnchor.constraint(equalTo: primaryContainer.centerYAnchor),

            contentView.bottomAnchor.constraint(equalTo: primaryContainer.bottomAnchor, constant: 20)
        ])
    }

    private func addLabel(_ text: String, at yOffset: inout CGFloat) {
        let label = UILabel()
        label.text = text
        label.textColor = UIColor(red: 0.65, green: 0.54, blue: 0.98, alpha: 1.0) // #a78bfa
        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])

        yOffset += 26
    }

    private func addTextField(placeholder: String, at yOffset: inout CGFloat) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.textColor = .white
        textField.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        textField.layer.borderColor = UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 0.3).cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 8
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 44))
        textField.rightViewMode = .always
        textField.returnKeyType = .next
        textField.delegate = self
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.heightAnchor.constraint(equalToConstant: 44)
        ])

        yOffset += 60

        return textField
    }

    private func populateFields() {
        guard let address = existingAddress else { return }

        nameField.text = address["name"] as? String
        recipientNameField.text = address["recipientName"] as? String
        streetField.text = address["street"] as? String
        street2Field.text = address["street2"] as? String
        cityField.text = address["city"] as? String
        stateField.text = address["state"] as? String
        zipField.text = address["zip"] as? String
        countryField.text = address["country"] as? String ?? "US"
        phoneField.text = address["phone"] as? String
        isPrimarySwitch.isOn = address["isPrimary"] as? Bool ?? false
    }

    @objc private func cancelTapped() {
        NSLog("ADDRESSFORM: Cancel tapped")
        dismiss(animated: true)
    }

    @objc private func saveTapped() {
        NSLog("ADDRESSFORM: Save tapped")

        // Validate required fields
        guard let name = nameField.text, !name.isEmpty,
              let recipientName = recipientNameField.text, !recipientName.isEmpty,
              let street = streetField.text, !street.isEmpty,
              let city = cityField.text, !city.isEmpty,
              let state = stateField.text, !state.isEmpty,
              let zip = zipField.text, !zip.isEmpty else {
            let alert = UIAlertController(
                title: "Missing Information",
                message: "Please fill in all required fields (Name, Recipient, Street, City, State, ZIP)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        var address: [String: Any] = [
            "name": name,
            "recipientName": recipientName,
            "street": street,
            "street2": street2Field.text ?? "",
            "city": city,
            "state": state,
            "zip": zip,
            "country": countryField.text ?? "US",
            "phone": phoneField.text ?? "",
            "isPrimary": isPrimarySwitch.isOn
        ]

        // Preserve existing ID if editing
        if let existingId = existingAddress?["id"] as? String {
            address["id"] = existingId
        }
        if let existingCreatedAt = existingAddress?["createdAt"] as? String {
            address["createdAt"] = existingCreatedAt
        }

        NSLog("ADDRESSFORM: Saving address: %@", name)

        onSave?(address)
        dismiss(animated: true)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Move to next field or dismiss keyboard
        if textField == nameField {
            recipientNameField.becomeFirstResponder()
        } else if textField == recipientNameField {
            streetField.becomeFirstResponder()
        } else if textField == streetField {
            street2Field.becomeFirstResponder()
        } else if textField == street2Field {
            cityField.becomeFirstResponder()
        } else if textField == cityField {
            stateField.becomeFirstResponder()
        } else if textField == stateField {
            zipField.becomeFirstResponder()
        } else if textField == zipField {
            countryField.becomeFirstResponder()
        } else if textField == countryField {
            phoneField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return false
    }

    // MARK: - Keyboard Handling

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }

        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
}

#endif

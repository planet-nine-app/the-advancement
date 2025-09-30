//
//  InstantiationViewController.swift
//  The Advancement
//
//  Shows Fount user information and instantiation details
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

#if os(iOS)
class InstantiationViewController: UIViewController {

    private var userInfo: [String: Any] = [:]
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let sessionless = Sessionless()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "⚡ Instantiation"
        view.backgroundColor = .systemBackground

        setupUI()
        loadAllUserInfo()

        // Add refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        NSLog("ADVANCEAPP: ⚡ InstantiationViewController loaded")
    }

    private func setupUI() {
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        // Setup stack view
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)

        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }

    @objc private func refreshTapped() {
        NSLog("ADVANCEAPP: ⚡ Refresh button tapped")
        loadAllUserInfo()
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP: ⚡ Close button tapped")
        dismiss(animated: true)
    }

    private func loadAllUserInfo() {
        NSLog("ADVANCEAPP: ⚡ Loading Fount user info and saved payment methods...")

        // Clear existing views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Show loading state
        let loadingLabel = createInfoLabel(title: "Loading...", value: "Fetching user information and payment methods")
        stackView.addArrangedSubview(loadingLabel)

        // Use real sessionless keys with UserDefaults fallback
        Task {
            do {
                // First ensure users exist (like NexusViewController does)
                await ensureUsersExist()

                // Get sessionless public key for Fount calls
                guard let keys = sessionless.getKeys() else {
                    throw NSError(domain: "InstantiationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No sessionless keys available"])
                }

                let publicKey = keys.publicKey
                NSLog("ADVANCEAPP: ⚡ Using publicKey: %@ for Fount calls", publicKey)

                // Log all stored UUIDs for debugging
                NSLog("ADVANCEAPP: 🔍 [UUID DEBUG] Starting service calls with stored UUIDs:")
                if let fountUUID = getStoredFountUUID() {
                    NSLog("ADVANCEAPP: 🔍 [UUID DEBUG] Fount UUID: %@", fountUUID)
                } else {
                    NSLog("ADVANCEAPP: 🔍 [UUID DEBUG] No Fount UUID stored")
                }

                if let bdoUUID = getStoredBDOUUID() {
                    NSLog("ADVANCEAPP: 🔍 [UUID DEBUG] BDO UUID: %@", bdoUUID)
                } else {
                    NSLog("ADVANCEAPP: 🔍 [UUID DEBUG] No BDO UUID stored")
                }

                if let addieUUID = getStoredAddieUUID() {
                    NSLog("ADVANCEAPP: 🔍 [UUID DEBUG] Addie UUID: %@", addieUUID)
                } else {
                    NSLog("ADVANCEAPP: 🔍 [UUID DEBUG] No Addie UUID stored")
                }

                // Get specific UUIDs for each service
                guard let addieUUID = getStoredAddieUUID() else {
                    throw NSError(domain: "InstantiationError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Addie UUID available - user must be created first"])
                }

                NSLog("ADVANCEAPP: ⚡ Using Addie UUID: %@ for payment methods", addieUUID)

                // Load both Fount user info and payment methods concurrently
                async let userInfo = fetchFountUserInfo(publicKey: publicKey)
                async let paymentMethods = fetchSavedPaymentMethods(uuid: addieUUID)

                let (fountData, addieData) = try await (userInfo, paymentMethods)

                DispatchQueue.main.async {
                    self.displayUserInfo(fountData, publicKey: publicKey, paymentMethods: addieData)
                }
            } catch {
                NSLog("ADVANCEAPP: ⚠️ Failed to load user info: %@", error.localizedDescription)
                DispatchQueue.main.async {
                    self.displayError(error)
                }
            }
        }
    }

    private func fetchFountUserInfo(publicKey: String) async throws -> [String: Any] {
        // Get stored Fount user UUID
        guard let fountUserData = UserDefaults.standard.data(forKey: "fountUser"),
              let fountUser = try? JSONSerialization.jsonObject(with: fountUserData) as? [String: Any],
              let uuid = fountUser["uuid"] as? String else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No Fount user found"])
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + uuid

        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign Fount request"])
        }

        guard let url = URL(string: "http://127.0.0.1:5117/user/\(uuid)?timestamp=\(timestamp)&signature=\(signature)") else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Fount URL"])
        }
        
        let hash = "the-advancement"

        NSLog("ADVANCEAPP: 📡 Fetching user info from Fount")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(timestamp, forHTTPHeaderField: "x-timestamp")
        request.setValue(signature, forHTTPHeaderField: "x-signature")
        request.setValue(hash, forHTTPHeaderField: "x-hash")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Fount error: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return jsonObject ?? [:]
    }

    private func fetchSavedPaymentMethods(uuid: String) async throws -> [String: Any] {
        // Create authenticated request using sessionless signature
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + uuid

        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "AddieError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign request"])
        }

        // Use correct Addie endpoint with URL parameters
        let addieUrl = "http://127.0.0.1:5116/saved-payment-methods?uuid=\(uuid)&timestamp=\(timestamp)&processor=stripe&signature=\(signature)"

        guard let url = URL(string: addieUrl) else {
            throw NSError(domain: "AddieError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid Addie URL"])
        }

        NSLog("ADVANCEAPP: 💳 Fetching saved payment methods from Addie")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(signature, forHTTPHeaderField: "x-signature")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AddieError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        NSLog("ADVANCEAPP: 💳 Addie payment methods response: %d", httpResponse.statusCode)

        if httpResponse.statusCode == 404 {
            // User doesn't exist in Addie yet or no payment methods
            NSLog("ADVANCEAPP: 💳 No payment methods found for user")
            return ["paymentMethods": []]
        }

        guard httpResponse.statusCode == 200 else {
            throw NSError(domain: "AddieError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Addie error: \(httpResponse.statusCode)"])
        }

        let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return jsonObject ?? ["paymentMethods": []]
    }

    private func displayUserInfo(_ info: [String: Any], publicKey: String, paymentMethods: [String: Any] = [:]) {
        // Clear loading state
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add header
        let headerLabel = UILabel()
        headerLabel.text = "Fount User Instantiation"
        headerLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        headerLabel.textAlignment = .center
        stackView.addArrangedSubview(headerLabel)

        // Add separator
        let separator = UIView()
        separator.backgroundColor = .systemGray4
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        stackView.addArrangedSubview(separator)

        // Public Key (with copy button)
        let pubKeyView = createCopyableInfoLabel(title: "Public Key", value: publicKey)
        stackView.addArrangedSubview(pubKeyView)

        // BDO data if available
        if let dataDict = info["data"] as? [String: Any] {
            if let type = dataDict["type"] as? String {
                let typeView = createInfoLabel(title: "BDO Type", value: type)
                stackView.addArrangedSubview(typeView)
            }

            // CarrierBag info
            if let carrierBag = dataDict["carrierBag"] as? [String: Any] {
                let carrierBagHeader = UILabel()
                carrierBagHeader.text = "CarrierBag Contents"
                carrierBagHeader.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
                stackView.addArrangedSubview(carrierBagHeader)

                if let created = carrierBag["created"] as? String {
                    let createdView = createInfoLabel(title: "Created", value: formatDate(created))
                    stackView.addArrangedSubview(createdView)
                }

                if let lastUpdated = carrierBag["lastUpdated"] as? String {
                    let updatedView = createInfoLabel(title: "Last Updated", value: formatDate(lastUpdated))
                    stackView.addArrangedSubview(updatedView)
                }

                // Count items in each collection
                let collections = ["cookbook", "apothecary", "gallery", "bookshelf", "familiarPen", "machinery", "metallics", "music", "oracular", "greenHouse", "closet", "games"]

                for collection in collections {
                    if let items = carrierBag[collection] as? [Any] {
                        let emoji = getCollectionEmoji(collection)
                        let countView = createInfoLabel(title: "\(emoji) \(collection.capitalized)", value: "\(items.count) items")
                        stackView.addArrangedSubview(countView)
                    }
                }
            }
        }

        // User UUID if available
        if let owner = (info["data"] as? [String: Any])?["owner"] as? String {
            let ownerView = createInfoLabel(title: "User UUID", value: owner)
            stackView.addArrangedSubview(ownerView)
        }

        // Saved Payment Methods Section
        let paymentMethodsHeader = UILabel()
        paymentMethodsHeader.text = "💳 Saved Payment Methods"
        paymentMethodsHeader.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        stackView.addArrangedSubview(paymentMethodsHeader)

        if let methods = paymentMethods["paymentMethods"] as? [[String: Any]], !methods.isEmpty {
            NSLog("ADVANCEAPP: 💳 Found \(methods.count) saved payment methods")

            for (index, method) in methods.enumerated() {
                let cardInfo = method["card"] as? [String: Any] ?? [:]
                let brand = cardInfo["brand"] as? String ?? "Unknown"
                let last4 = cardInfo["last4"] as? String ?? "****"
                let expMonth = cardInfo["exp_month"] as? Int ?? 0
                let expYear = cardInfo["exp_year"] as? Int ?? 0

                let methodTitle = "Card \(index + 1)"
                let methodDetails = "\(brand.capitalized) •••• \(last4) • Expires \(expMonth)/\(expYear)"

                let methodView = createInfoLabel(title: methodTitle, value: methodDetails)
                stackView.addArrangedSubview(methodView)
            }
        } else {
            NSLog("ADVANCEAPP: 💳 No saved payment methods found")
            let noMethodsView = createInfoLabel(title: "No Saved Cards", value: "Make a purchase through Nexus to save your payment method")
            stackView.addArrangedSubview(noMethodsView)
        }

        // Raw JSON for debugging
        let jsonView = createRawJSONView(info)
        stackView.addArrangedSubview(jsonView)

        NSLog("ADVANCEAPP: ⚡ Displayed user info with \(stackView.arrangedSubviews.count) elements")
    }

    private func displayError(_ error: Error) {
        // Clear loading state
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let errorLabel = createInfoLabel(title: "Error", value: error.localizedDescription)
        errorLabel.backgroundColor = .systemRed.withAlphaComponent(0.1)
        stackView.addArrangedSubview(errorLabel)

        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.backgroundColor = .systemBlue
        retryButton.setTitleColor(.white, for: .normal)
        retryButton.layer.cornerRadius = 8
        retryButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        retryButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        stackView.addArrangedSubview(retryButton)
    }

    private func createInfoLabel(title: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .systemBlue

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.numberOfLines = 0
        valueLabel.textColor = .label

        let stackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        return containerView
    }

    private func createCopyableInfoLabel(title: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .systemBlue

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = UIFont.systemFont(ofSize: 14)
        valueLabel.numberOfLines = 0
        valueLabel.textColor = .label

        let copyButton = UIButton(type: .system)
        copyButton.setTitle("📋 Copy", for: .normal)
        copyButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        copyButton.backgroundColor = .systemBlue
        copyButton.setTitleColor(.white, for: .normal)
        copyButton.layer.cornerRadius = 6
        copyButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        // Store value in button for copy action
        copyButton.accessibilityLabel = value
        copyButton.addTarget(self, action: #selector(copyButtonTapped(_:)), for: .touchUpInside)

        let contentStackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        contentStackView.axis = .vertical
        contentStackView.spacing = 4

        let mainStackView = UIStackView(arrangedSubviews: [contentStackView, copyButton])
        mainStackView.axis = .horizontal
        mainStackView.spacing = 12
        mainStackView.alignment = .center
        mainStackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(mainStackView)
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        return containerView
    }

    @objc private func copyButtonTapped(_ sender: UIButton) {
        guard let valueToCopy = sender.accessibilityLabel else { return }

        UIPasteboard.general.string = valueToCopy
        NSLog("ADVANCEAPP: 📋 Copied to clipboard: %@", valueToCopy)

        // Provide visual feedback
        sender.setTitle("✅ Copied!", for: .normal)
        sender.backgroundColor = .systemGreen

        // Reset button after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            sender.setTitle("📋 Copy", for: .normal)
            sender.backgroundColor = .systemBlue
        }
    }

    private func createRawJSONView(_ data: [String: Any]) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .systemGray6
        containerView.layer.cornerRadius = 8

        let titleLabel = UILabel()
        titleLabel.text = "Raw JSON Data"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .systemBlue

        let textView = UITextView()
        textView.isEditable = false
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .clear

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            textView.text = String(data: jsonData, encoding: .utf8) ?? "Unable to format JSON"
        } catch {
            textView.text = "Error formatting JSON: \(error.localizedDescription)"
        }

        textView.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [titleLabel, textView])
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false

        containerView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            textView.heightAnchor.constraint(equalToConstant: 200)
        ])

        return containerView
    }

    private func getCollectionEmoji(_ collection: String) -> String {
        switch collection {
        case "cookbook": return "🍪"
        case "apothecary": return "🧪"
        case "gallery": return "🖼️"
        case "bookshelf": return "📚"
        case "familiarPen": return "🐾"
        case "machinery": return "⚙️"
        case "metallics": return "⚡"
        case "music": return "🎵"
        case "oracular": return "🔮"
        case "greenHouse": return "🌱"
        case "closet": return "👕"
        case "games": return "🎮"
        default: return "📦"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        guard !dateString.isEmpty else { return "Unknown date" }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }

        return dateString
    }

    // MARK: - UUID Management




    // MARK: - User Initialization

    private func ensureUsersExist() async {
        NSLog("ADVANCEAPP: 🚀 [INIT] Ensuring users exist in Fount and Addie...")
        await ensureSessionlessKeys()
        await ensureFountUserExists()
        await ensureCarrierBagExists()
        await ensureAddieUserExists()
        NSLog("ADVANCEAPP: ✅ [INIT] User initialization complete")
    }

    private func ensureSessionlessKeys() async {
        NSLog("ADVANCEAPP: 🔑 [KEYS] Checking sessionless keys...")

        if let keys = sessionless.getKeys() {
            NSLog("ADVANCEAPP: ✅ [KEYS] Sessionless keys already exist")
            NSLog("ADVANCEAPP: 🔑 [KEYS] PublicKey: %@", keys.publicKey)
        } else {
            NSLog("ADVANCEAPP: 🔧 [KEYS] No sessionless keys found, generating new ones...")
            let newKeys = sessionless.generateKeys()
            if newKeys != nil {
                if let keys = sessionless.getKeys() {
                    NSLog("ADVANCEAPP: ✅ [KEYS] New sessionless keys generated successfully")
                    NSLog("ADVANCEAPP: 🔑 [KEYS] New PublicKey: %@", keys.publicKey)
                } else {
                    NSLog("ADVANCEAPP: ❌ [KEYS] Failed to retrieve generated keys")
                }
            } else {
                NSLog("ADVANCEAPP: ❌ [KEYS] Failed to generate sessionless keys")
            }
        }
    }

    private func ensureFountUserExists() async {
        NSLog("ADVANCEAPP: 🌊 [FOUNT] Checking Fount user...")

        // Check if we already have a stored Fount user
        if let fountUserData = UserDefaults.standard.data(forKey: "fountUser"),
           let fountUser = try? JSONSerialization.jsonObject(with: fountUserData) as? [String: Any],
           let uuid = fountUser["uuid"] as? String {
            NSLog("ADVANCEAPP: ✅ [FOUNT] Using existing Fount user: %@", uuid)
            return
        }

        NSLog("ADVANCEAPP: 🔧 [FOUNT] No stored Fount user, creating new one...")

        guard let keys = sessionless.getKeys() else {
            NSLog("ADVANCEAPP: ❌ [FOUNT] No sessionless keys available for Fount user creation")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey

        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP: ❌ [FOUNT] Failed to sign Fount user creation message")
            return
        }

        let userPayload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": keys.publicKey,
            "signature": signature
        ]

        do {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userPayload),
                  let url = URL(string: "http://127.0.0.1:5117/user/create") else {
                NSLog("ADVANCEAPP: ❌ [FOUNT] Failed to create Fount user request")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Parse response to get user data
                    if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let uuid = responseData["uuid"] as? String {

                        let fountUser: [String: Any] = [
                            "uuid": uuid,
                            "ordinal": responseData["ordinal"] ?? 0,
                            "created": timestamp,
                            "pubKey": keys.publicKey
                        ]

                        // Store for future use
                        if let userData = try? JSONSerialization.data(withJSONObject: fountUser) {
                            UserDefaults.standard.set(userData, forKey: "fountUser")
                            NSLog("ADVANCEAPP: ✅ [FOUNT] Fount user created and stored: %@", uuid)
                        }
                    } else {
                        NSLog("ADVANCEAPP: ✅ [FOUNT] Fount user created successfully")
                        if let responseString = String(data: data, encoding: .utf8) {
                            NSLog("ADVANCEAPP: 📄 [FOUNT] Response: %@", responseString)
                        }
                    }
                } else {
                    NSLog("ADVANCEAPP: ⚠️ [FOUNT] Fount user creation returned status: %d", httpResponse.statusCode)
                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("ADVANCEAPP: ❌ [FOUNT] Error: %@", responseString)
                    }
                }
            }
        } catch {
            NSLog("ADVANCEAPP: ❌ [FOUNT] Failed to create Fount user: %@", error.localizedDescription)
        }
    }

    private func ensureCarrierBagExists() async {
        NSLog("ADVANCEAPP: 🎒 [CARRIERBAG] Checking CarrierBag BDO...")

        guard let keys = sessionless.getKeys() else {
            NSLog("ADVANCEAPP: ❌ [FOUNT] No sessionless keys available for Fount user creation")
            return
        }

        // First, create or get BDO user
        let bdoUserUuid = await ensureBDOUserExists(publicKey: keys.publicKey)
        guard !bdoUserUuid.isEmpty else {
            NSLog("ADVANCEAPP: ❌ [FOUNT] Failed to create/get BDO user")
            return
        }

        // Then, create CarrierBag BDO
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + bdoUserUuid
        let hash = "the-advancement"

        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP: ❌ [FOUNT] Failed to sign CarrierBag BDO creation message")
            return
        }

        let carrierBagPayload: [String: Any] = [
            "timestamp": timestamp,
            "signature": signature,
            "hash": hash,
            "data": [
                "type": "carrierBag",
                "owner": getStoredBDOUUID() ?? "unknown-bdo-owner",
                "carrierBag": [
                    "created": ISO8601DateFormatter().string(from: Date()),
                    "lastUpdated": ISO8601DateFormatter().string(from: Date()),
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
                    "games": []
                ]
            ]
        ]

        do {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: carrierBagPayload),
                  let url = URL(string: "http://127.0.0.1:5114/user/\(bdoUserUuid)/bdo") else {
                NSLog("ADVANCEAPP: ❌ [FOUNT] Failed to create CarrierBag BDO request")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    NSLog("ADVANCEAPP: ✅ [FOUNT] CarrierBag BDO created/updated successfully")

                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("ADVANCEAPP: 📄 [FOUNT] Response: %@", responseString)
                    }
                } else {
                    NSLog("ADVANCEAPP: ⚠️ [FOUNT] CarrierBag BDO creation returned status: %d", httpResponse.statusCode)

                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("ADVANCEAPP: ❌ [FOUNT] Error: %@", responseString)
                    }
                }
            }

        } catch {
            NSLog("ADVANCEAPP: ❌ [FOUNT] Failed to create CarrierBag BDO: %@", error.localizedDescription)
        }
    }

    private func ensureBDOUserExists(publicKey: String) async -> String {
        NSLog("ADVANCEAPP: 🗄️ [BDO] Checking BDO user...")

        // Check if BDO user already exists in storage
        if let existingUser = UserDefaults.standard.data(forKey: "bdoUser"),
           let userData = try? JSONSerialization.jsonObject(with: existingUser) as? [String: Any],
           let uuid = userData["uuid"] as? String {
            NSLog("ADVANCEAPP: ✅ [BDO] Using existing BDO user: %@", uuid)
            return uuid
        }

        NSLog("ADVANCEAPP: 🔧 [BDO] No stored BDO user, creating new one...")

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "the-advancement"
        let message = timestamp + publicKey + hash

        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP: ❌ [BDO] Failed to sign BDO user creation message")
            return ""
        }

        let userPayload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": publicKey,
            "signature": signature,
            "hash": hash
        ]

        do {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userPayload),
                  let url = URL(string: "http://127.0.0.1:5114/user/create") else {
                NSLog("ADVANCEAPP: ❌ [BDO] Failed to create BDO user request")
                return ""
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    // Parse response to get BDO user UUID
                    if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let uuid = responseData["uuid"] as? String {

                        let bdoUser: [String: Any] = [
                            "uuid": uuid,
                            "bdo": [String: Any]()
                        ]

                        // Store for future use
                        if let userData = try? JSONSerialization.data(withJSONObject: bdoUser) {
                            UserDefaults.standard.set(userData, forKey: "bdoUser")
                            NSLog("ADVANCEAPP: ✅ [BDO] BDO user created and stored: %@", uuid)
                        }

                        return uuid
                    } else {
                        NSLog("ADVANCEAPP: ✅ [BDO] BDO user created but no UUID in response")
                        if let responseString = String(data: data, encoding: .utf8) {
                            NSLog("ADVANCEAPP: 📄 [BDO] Response string from create user: %@", responseString)
                        }
                    }
                } else {
                    NSLog("ADVANCEAPP: ⚠️ [BDO] BDO user creation returned status: %d", httpResponse.statusCode)

                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("ADVANCEAPP: ❌ [BDO] Error: %@", responseString)
                    }
                }
            }

        } catch {
            NSLog("ADVANCEAPP: ❌ [BDO] Failed to create BDO user: %@", error.localizedDescription)
        }

        return ""
    }

    private func ensureAddieUserExists() async {
        NSLog("ADVANCEAPP: 💳 [ADDIE] Checking Addie user...")

        // Check if user already exists in storage
        if let existingUser = UserDefaults.standard.data(forKey: "addieUser"),
           let userData = try? JSONSerialization.jsonObject(with: existingUser) as? [String: Any],
           let uuid = userData["uuid"] as? String {
            NSLog("ADVANCEAPP: ✅ [ADDIE] Using existing Addie user: %@", uuid)
            return
        }

        NSLog("ADVANCEAPP: 🔧 [ADDIE] No stored Addie user, creating new one...")

        guard let keys = sessionless.getKeys() else {
            NSLog("ADVANCEAPP: ❌ [ADDIE] No sessionless keys available for Addie user creation")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + keys.publicKey

        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP: ❌ [ADDIE] Failed to sign Addie user creation message")
            return
        }

        let userPayload: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": keys.publicKey,
            "signature": signature
        ]

        do {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: userPayload),
                  let url = URL(string: "http://127.0.0.1:5116/user/create") else {
                NSLog("ADVANCEAPP: ❌ [ADDIE] Failed to create Addie user request")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    // Parse response to get user data
                    if let responseData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let uuid = responseData["uuid"] as? String {

                        let addieUser: [String: Any] = [
                            "uuid": uuid,
                            "created": timestamp,
                            "pubKey": keys.publicKey
                        ]

                        // Store for future use
                        if let userData = try? JSONSerialization.data(withJSONObject: addieUser) {
                            UserDefaults.standard.set(userData, forKey: "addieUser")
                            NSLog("ADVANCEAPP: ✅ [ADDIE] Addie user created and stored: %@", uuid)
                        }
                    } else {
                        NSLog("ADVANCEAPP: ✅ [ADDIE] Addie user created successfully")
                        if let responseString = String(data: data, encoding: .utf8) {
                            NSLog("ADVANCEAPP: 📄 [ADDIE] Response: %@", responseString)
                        }
                    }
                } else {
                    NSLog("ADVANCEAPP: ⚠️ [ADDIE] Addie user creation returned status: %d", httpResponse.statusCode)

                    // Log error response
                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("ADVANCEAPP: ❌ [ADDIE] Error: %@", responseString)
                    }
                }
            }

        } catch {
            NSLog("ADVANCEAPP: ❌ [ADDIE] Failed to create Addie user: %@", error.localizedDescription)
        }
    }

    // MARK: - UUID Management Helpers

    private func getStoredFountUUID() -> String? {
        if let fountUserData = UserDefaults.standard.data(forKey: "fountUser"),
           let fountUser = try? JSONSerialization.jsonObject(with: fountUserData) as? [String: Any],
           let uuid = fountUser["uuid"] as? String {
            return uuid
        }
        return nil
    }

    private func getStoredBDOUUID() -> String? {
        if let bdoUserData = UserDefaults.standard.data(forKey: "bdoUser"),
           let bdoUser = try? JSONSerialization.jsonObject(with: bdoUserData) as? [String: Any],
           let uuid = bdoUser["uuid"] as? String {
            return uuid
        }
        return nil
    }

    private func getStoredAddieUUID() -> String? {
        if let addieUserData = UserDefaults.standard.data(forKey: "addieUser"),
           let addieUser = try? JSONSerialization.jsonObject(with: addieUserData) as? [String: Any],
           let uuid = addieUser["uuid"] as? String {
            return uuid
        }
        return nil
    }
}
#endif

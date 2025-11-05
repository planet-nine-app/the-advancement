//
//  PaymentMethodViewController.swift
//  The Advancement
//
//  Manages payment methods using Stripe SetupIntent via WebView
//

#if os(iOS)
import UIKit
import WebKit

class PaymentMethodViewController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {

    private var webView: WKWebView!
    private var stripePublishableKey: String = "pk_test_TYooMQauvdEDq54NiTphI7jx" // TODO: Move to Configuration
    private var customerId: String?
    private var savedCards: [[String: Any]] = []
    private let sessionless = Sessionless()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "💳 Payment Methods"
        view.backgroundColor = UIColor(red: 0.1, green: 0.0, blue: 0.2, alpha: 1.0)

        // Setup navigation bar
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        // Setup WebView
        setupWebView()

        // Load customer ID
        loadCustomerInfo()

        NSLog("PAYMENTMETHOD: 💳 PaymentMethodViewController loaded")
    }

    deinit {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "paymentMethod")
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "consoleLog")
    }

    private func setupWebView() {
        let contentController = WKUserContentController()

        // Register message handler
        contentController.add(self, name: "paymentMethod")

        // Register console.log handler
        contentController.add(self, name: "consoleLog")

        // Inject console.log override
        let consoleScript = """
        (function() {
            var originalLog = console.log;
            var originalError = console.error;
            var originalWarn = console.warn;

            console.log = function() {
                var args = Array.prototype.slice.call(arguments);
                window.webkit.messageHandlers.consoleLog.postMessage({
                    level: 'log',
                    message: args.map(String).join(' ')
                });
                originalLog.apply(console, arguments);
            };

            console.error = function() {
                var args = Array.prototype.slice.call(arguments);
                window.webkit.messageHandlers.consoleLog.postMessage({
                    level: 'error',
                    message: args.map(String).join(' ')
                });
                originalError.apply(console, arguments);
            };

            console.warn = function() {
                var args = Array.prototype.slice.call(arguments);
                window.webkit.messageHandlers.consoleLog.postMessage({
                    level: 'warn',
                    message: args.map(String).join(' ')
                });
                originalWarn.apply(console, arguments);
            };
        })();
        """

        let userScript = WKUserScript(source: consoleScript, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        contentController.addUserScript(userScript)

        let config = WKWebViewConfiguration()
        config.userContentController = contentController

        // Allow JavaScript
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

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

        // Load HTML - use loadFileURL to avoid sandboxing issues with Stripe.js
        if let htmlPath = Bundle.main.path(forResource: "PaymentMethod", ofType: "html") {
            let htmlURL = URL(fileURLWithPath: htmlPath)
            let accessURL = htmlURL.deletingLastPathComponent()
            webView.loadFileURL(htmlURL, allowingReadAccessTo: accessURL)
            NSLog("PAYMENTMETHOD: 💳 Loaded PaymentMethod.html from file URL")
        } else {
            NSLog("PAYMENTMETHOD: ❌ Failed to find PaymentMethod.html")
        }
    }

    private func loadCustomerInfo() {
        // Try to load saved customer ID from SharedUserDefaults (App Group)
        if let savedCustomerId = SharedUserDefaults.shared.string(forKey: "stripe_customer_id") {
            customerId = savedCustomerId
            NSLog("PAYMENTMETHOD: 💳 Loaded customer ID: %@", savedCustomerId)
        } else {
            NSLog("PAYMENTMETHOD: 💳 No customer ID found, will create on first card save")
        }

        // Load saved cards
        loadSavedCards()
    }

    private func loadSavedCards() {
        // Load from SharedUserDefaults (App Group) for keyboard extension access
        if let cardsData = SharedUserDefaults.shared.data(forKey: "stripe_saved_cards"),
           let cards = try? JSONSerialization.jsonObject(with: cardsData) as? [[String: Any]] {
            savedCards = cards
            NSLog("PAYMENTMETHOD: 💳 Loaded %d saved cards from SharedUserDefaults", cards.count)
        } else {
            savedCards = []
            NSLog("PAYMENTMETHOD: 💳 No saved cards found")
        }
    }

    private func saveSavedCards() {
        if let cardsData = try? JSONSerialization.data(withJSONObject: savedCards) {
            SharedUserDefaults.shared.set(cardsData, forKey: "stripe_saved_cards")
            SharedUserDefaults.shared.synchronize()
            NSLog("PAYMENTMETHOD: 💳 Saved %d cards to SharedUserDefaults", savedCards.count)
        }
    }

    @objc private func closeTapped() {
        NSLog("PAYMENTMETHOD: 💳 Close button tapped")
        dismiss(animated: true)
    }

    // Public method to switch tabs from external callers
    public func switchToTab(_ tabName: String) {
        NSLog("PAYMENTMETHOD: 📑 Switching to tab: %@", tabName)
        let jsCode = "if (typeof switchToTab === 'function') { switchToTab('\(tabName)'); }"
        webView.evaluateJavaScript(jsCode) { _, error in
            if let error = error {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to switch tab: %@", error.localizedDescription)
            } else {
                NSLog("PAYMENTMETHOD: ✅ Tab switched successfully")
            }
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle console.log messages
        if message.name == "consoleLog" {
            if let logData = message.body as? [String: Any],
               let level = logData["level"] as? String,
               let logMessage = logData["message"] as? String {
                switch level {
                case "error":
                    NSLog("🌐 WebView [ERROR]: %@", logMessage)
                case "warn":
                    NSLog("🌐 WebView [WARN]: %@", logMessage)
                default:
                    NSLog("🌐 WebView [LOG]: %@", logMessage)
                }
            }
            return
        }

        guard message.name == "paymentMethod" else { return }

        guard let messageBody = message.body as? [String: Any],
              let method = messageBody["method"] as? String,
              let messageId = messageBody["messageId"] else {
            NSLog("PAYMENTMETHOD: ❌ Invalid message from WebView")
            return
        }

        let params = messageBody["params"] as? [String: Any] ?? [:]

        NSLog("PAYMENTMETHOD: 📨 Received method call: %@", method)

        switch method {
        case "createSetupIntent":
            createSetupIntent(messageId: messageId)

        case "setupIntentSucceeded":
            setupIntentSucceeded(params: params, messageId: messageId)

        case "getSavedCards":
            getSavedCards(messageId: messageId)

        case "deletePaymentMethod":
            deletePaymentMethod(params: params, messageId: messageId)

        case "issueVirtualCard":
            issueVirtualCard(params: params, messageId: messageId)

        case "issuePhysicalCard":
            issuePhysicalCard(messageId: messageId)

        case "getIssuedCards":
            getIssuedCards(messageId: messageId)

        case "getCardDetails":
            getCardDetails(params: params, messageId: messageId)

        case "updateCardStatus":
            updateCardStatus(params: params, messageId: messageId)

        case "createCardholder":
            createCardholder(params: params, messageId: messageId)

        case "getCardholderStatus":
            getCardholderStatus(messageId: messageId)

        case "getTransactions":
            getTransactions(messageId: messageId)

        case "savePayoutCard":
            savePayoutCard(params: params, messageId: messageId)

        case "getPayoutCardStatus":
            getPayoutCardStatus(messageId: messageId)

        default:
            sendResponse(messageId: messageId, error: "Unknown method: \(method)")
        }
    }

    // MARK: - API Methods

    private func createSetupIntent(messageId: Any) {
        NSLog("PAYMENTMETHOD: 🔧 Creating SetupIntent...")

        guard let homeBase = getHomeBaseURL() else {
            sendResponse(messageId: messageId, error: "No home base configured")
            return
        }

        let endpoint = "\(homeBase)/processor/stripe/setup-intent"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))

        var body: [String: Any] = [
            "timestamp": timestamp
        ]

        // Try to get user's pubKey and sign the request
        if let keys = sessionless.getKeys() {
            let pubKey = keys.publicKey

            // Sign the request
            let message = timestamp + pubKey

            if let signature = signMessage(message) {
                body["pubKey"] = pubKey
                body["signature"] = signature
                NSLog("PAYMENTMETHOD: 🔐 Authenticated request with pubKey: %@", String(pubKey.prefix(20)))
            } else {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to sign message, sending unsigned request")
                body["pubKey"] = pubKey
            }
        } else {
            NSLog("PAYMENTMETHOD: ⚠️ No pubKey found, creating anonymous SetupIntent")
        }

        // Include customer ID if we have one
        if let customerId = customerId {
            body["customerId"] = customerId
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to create SetupIntent: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["clientSecret"] as? String,
                  let publishableKey = json["publishableKey"] as? String else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response from server")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            // Save customer ID if returned (use SharedUserDefaults for keyboard access)
            if let customerId = json["customerId"] as? String {
                self.customerId = customerId
                SharedUserDefaults.shared.set(customerId, forKey: "stripe_customer_id")
                SharedUserDefaults.shared.synchronize()
                NSLog("PAYMENTMETHOD: 💳 Saved customer ID to SharedUserDefaults: %@", customerId)
            }

            NSLog("PAYMENTMETHOD: ✅ SetupIntent created successfully")
            NSLog("PAYMENTMETHOD: 🔑 Using publishable key: %@", String(publishableKey.prefix(20)))

            self.sendResponse(messageId: messageId, result: [
                "clientSecret": clientSecret,
                "publishableKey": publishableKey  // Use the key from Addie's response
            ])
        }.resume()
    }

    private func setupIntentSucceeded(params: [String: Any], messageId: Any) {
        guard let setupIntentId = params["setupIntentId"] as? String,
              let paymentMethodId = params["paymentMethodId"] as? String else {
            sendResponse(messageId: messageId, error: "Missing setupIntentId or paymentMethodId")
            return
        }

        NSLog("PAYMENTMETHOD: ✅ SetupIntent succeeded: %@", setupIntentId)
        NSLog("PAYMENTMETHOD: 💳 Payment method ID: %@", paymentMethodId)

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            NSLog("PAYMENTMETHOD: ⚠️ No authentication, cannot update payment method")
            sendResponse(messageId: messageId, error: "Authentication required")
            return
        }

        let pubKey = keys.publicKey

        // CRITICAL: First update the payment method to set allow_redisplay = 'always'
        // This must happen BEFORE fetching payment methods
        NSLog("PAYMENTMETHOD: 🔄 Updating payment method allow_redisplay to 'always'...")

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let updateMessage = timestamp + pubKey + paymentMethodId
        guard let updateSignature = signMessage(updateMessage) else {
            NSLog("PAYMENTMETHOD: ❌ Failed to sign update request")
            sendResponse(messageId: messageId, error: "Failed to sign request")
            return
        }

        let updateEndpoint = "\(homeBase)/processor/stripe/payment-method/\(paymentMethodId)/allow-redisplay"
        var updateRequest = URLRequest(url: URL(string: updateEndpoint)!)
        updateRequest.httpMethod = "POST"
        updateRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let updateBody: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": pubKey,
            "signature": updateSignature
        ]

        updateRequest.httpBody = try? JSONSerialization.data(withJSONObject: updateBody)

        URLSession.shared.dataTask(with: updateRequest) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to update payment method: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response from update endpoint")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            guard let success = json["success"] as? Bool, success else {
                NSLog("PAYMENTMETHOD: ❌ Failed to update allow_redisplay")
                if let errorMsg = json["error"] as? String {
                    self.sendResponse(messageId: messageId, error: errorMsg)
                } else {
                    self.sendResponse(messageId: messageId, error: "Failed to update payment method")
                }
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Payment method updated with allow_redisplay: always")

            // Now get or create Addie user UUID and fetch payment methods
            self.getOrCreateAddieUser(pubKey: pubKey) { [weak self] userUUID in
                guard let self = self, let uuid = userUUID else {
                    NSLog("PAYMENTMETHOD: ❌ Failed to get user UUID")
                    self?.sendResponse(messageId: messageId, error: "Failed to get user UUID")
                    return
                }

                // Fetch saved payment methods from backend
                let fetchTimestamp = String(Int(Date().timeIntervalSince1970 * 1000))
                let message = fetchTimestamp + uuid
                guard let signature = self.signMessage(message) else {
                    NSLog("PAYMENTMETHOD: ❌ Failed to sign request")
                    self.sendResponse(messageId: messageId, error: "Failed to sign request")
                    return
                }

                let endpoint = "\(homeBase)/saved-payment-methods?uuid=\(uuid)&timestamp=\(fetchTimestamp)&processor=stripe&signature=\(signature)"

                var request = URLRequest(url: URL(string: endpoint)!)
                request.httpMethod = "GET"

                URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        NSLog("PAYMENTMETHOD: ❌ Failed to fetch payment methods: %@", error.localizedDescription)
                        self.sendResponse(messageId: messageId, error: error.localizedDescription)
                        return
                    }

                    guard let data = data,
                          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                          let paymentMethods = json["paymentMethods"] as? [[String: Any]] else {
                        NSLog("PAYMENTMETHOD: ❌ Invalid response from backend")
                        self.sendResponse(messageId: messageId, error: "Invalid server response")
                        return
                    }

                    NSLog("PAYMENTMETHOD: ✅ Fetched %d payment methods from backend", paymentMethods.count)

                    // Convert to card format and save to SharedUserDefaults
                    let cards = paymentMethods.compactMap { pm -> [String: Any]? in
                        guard let card = pm["card"] as? [String: Any],
                              let last4 = card["last4"],
                              let brand = card["brand"],
                              let expMonth = card["exp_month"],
                              let expYear = card["exp_year"],
                              let id = pm["id"] as? String else {
                            return nil
                        }

                        return [
                            "id": id,
                            "brand": brand,
                            "last4": last4,
                            "exp_month": String(describing: expMonth),
                            "exp_year": String(describing: expYear),
                            "isDefault": false
                        ]
                    }

                    self.savedCards = cards
                    self.saveSavedCards()

                    NSLog("PAYMENTMETHOD: 💾 Saved %d cards to SharedUserDefaults", cards.count)

                    // Post notification that cards were updated and close this view
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("PaymentCardsSaved"), object: nil)
                        NSLog("PAYMENTMETHOD: 📢 Posted PaymentCardsSaved notification")

                        // Dismiss this view and trigger navigation to CardDisplayViewController
                        self.dismiss(animated: true) {
                            NotificationCenter.default.post(name: NSNotification.Name("ShowCardDisplay"), object: nil)
                            NSLog("PAYMENTMETHOD: 📢 Posted ShowCardDisplay notification after dismiss")
                        }
                    }

                    self.sendResponse(messageId: messageId, result: ["success": true])
                }.resume()
            }
        }.resume()
    }

    private func getOrCreateAddieUser(pubKey: String, completion: @escaping (String?) -> Void) {
        // Check cache first
        if let cachedUUID = UserDefaults.standard.string(forKey: "addie_user_uuid") {
            NSLog("PAYMENTMETHOD: ✅ Using cached Addie UUID: %@", cachedUUID)
            completion(cachedUUID)
            return
        }

        guard let homeBase = getHomeBaseURL() else {
            completion(nil)
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey
        guard let signature = signMessage(message) else {
            completion(nil)
            return
        }

        let endpoint = "\(homeBase)/user/create"
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let uuid = json["uuid"] as? String else {
                NSLog("PAYMENTMETHOD: ❌ Failed to get/create Addie user")
                completion(nil)
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Got Addie UUID: %@", uuid)
            UserDefaults.standard.set(uuid, forKey: "addie_user_uuid")
            completion(uuid)
        }.resume()
    }

    private func getSavedCards(messageId: Any) {
        NSLog("PAYMENTMETHOD: 📋 Getting saved cards from Stripe...")

        // Try to fetch from Stripe API
        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            // Fallback to local storage
            NSLog("PAYMENTMETHOD: ⚠️ No authentication, using local storage (%d cards)", savedCards.count)
            sendResponse(messageId: messageId, result: [
                "cards": savedCards
            ])
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let endpoint = "\(homeBase)/saved-payment-methods?timestamp=\(timestamp)&processor=stripe&pubKey=\(pubKey)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to fetch from Stripe, using local: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, result: [
                    "cards": self.savedCards
                ])
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let paymentMethods = json["paymentMethods"] as? [[String: Any]] else {
                NSLog("PAYMENTMETHOD: ⚠️ Invalid response from Stripe, using local")
                self.sendResponse(messageId: messageId, result: [
                    "cards": self.savedCards
                ])
                return
            }

            // Convert Stripe payment methods to card format
            let cards = paymentMethods.compactMap { pm -> [String: Any]? in
                guard let card = pm["card"] as? [String: Any],
                      let last4 = card["last4"] as? String,
                      let brand = card["brand"] as? String,
                      let expMonth = card["exp_month"] as? Int,
                      let expYear = card["exp_year"] as? Int,
                      let id = pm["id"] as? String else {
                    return nil
                }

                return [
                    "id": id,
                    "brand": brand,
                    "last4": last4,
                    "exp_month": String(expMonth),
                    "exp_year": String(expYear),
                    "isDefault": false // TODO: Determine default card
                ]
            }

            NSLog("PAYMENTMETHOD: ✅ Fetched %d cards from Stripe", cards.count)

            // Update local cache
            self.savedCards = cards
            self.saveSavedCards()

            self.sendResponse(messageId: messageId, result: [
                "cards": cards
            ])
        }.resume()
    }

    private func deletePaymentMethod(params: [String: Any], messageId: Any) {
        guard let paymentMethodId = params["paymentMethodId"] as? String else {
            sendResponse(messageId: messageId, error: "Missing paymentMethodId")
            return
        }

        NSLog("PAYMENTMETHOD: 🗑️ Deleting payment method: %@", paymentMethodId)

        // Remove from local storage first
        savedCards.removeAll { card in
            (card["id"] as? String) == paymentMethodId
        }
        saveSavedCards()

        // Try to delete from Stripe
        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            NSLog("PAYMENTMETHOD: ⚠️ No authentication, deleted locally only")
            sendResponse(messageId: messageId, result: ["success": true])
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let endpoint = "\(homeBase)/saved-payment-methods/\(paymentMethodId)?timestamp=\(timestamp)&processor=stripe&pubKey=\(pubKey)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "DELETE"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to delete from Stripe (deleted locally): %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, result: ["success": true])
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Payment method deleted from Stripe")
            self.sendResponse(messageId: messageId, result: ["success": true])
        }.resume()
    }

    // MARK: - Card Issuing Methods

    private func issueVirtualCard(params: [String: Any], messageId: Any) {
        NSLog("PAYMENTMETHOD: 🌐 Issuing virtual card...")

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, error: "Authentication required")
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let endpoint = "\(homeBase)/issuing/card/virtual"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let message = timestamp + pubKey
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, error: "Failed to sign request")
            return
        }

        var body: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": pubKey,
            "signature": signature,
            "currency": "usd"
        ]

        // Add spending limit if provided
        if let spendingLimit = params["spendingLimit"] as? Int {
            body["spendingLimit"] = spendingLimit
        }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to issue virtual card: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            if let errorMsg = json["error"] as? String {
                self.sendResponse(messageId: messageId, error: errorMsg)
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Virtual card issued")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    private func issuePhysicalCard(messageId: Any) {
        NSLog("PAYMENTMETHOD: 📬 Issuing physical card...")

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, error: "Authentication required")
            return
        }
        let pubKey = keys.publicKey

        // Get shipping address from CarrierBag
        guard let carrierBag = SharedUserDefaults.getCarrierBag(),
              let addresses = carrierBag["addresses"] as? [[String: Any]],
              let primaryAddress = addresses.first(where: { ($0["isPrimary"] as? Bool) == true }) ?? addresses.first else {
            sendResponse(messageId: messageId, error: "Please add a shipping address in Carrier Bag first")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let endpoint = "\(homeBase)/issuing/card/physical"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build shipping address, only including line2 if it's not empty (Stripe requirement)
        var shippingAddress: [String: Any] = [
            "name": primaryAddress["recipientName"] as? String ?? "",
            "line1": primaryAddress["street"] as? String ?? "",
            "city": primaryAddress["city"] as? String ?? "",
            "state": primaryAddress["state"] as? String ?? "",
            "postal_code": primaryAddress["zip"] as? String ?? "",
            "country": primaryAddress["country"] as? String ?? "US"
        ]

        // Only include line2 if it's not empty (Stripe doesn't allow empty strings for this field)
        if let line2 = primaryAddress["street2"] as? String, !line2.isEmpty {
            shippingAddress["line2"] = line2
        }

        let body: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": pubKey,
            "signature": "", // TODO: Add proper signature
            "shippingAddress": shippingAddress,
            "currency": "usd"
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to issue physical card: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            if let errorMsg = json["error"] as? String {
                self.sendResponse(messageId: messageId, error: errorMsg)
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Physical card issued")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    private func getIssuedCards(messageId: Any) {
        NSLog("PAYMENTMETHOD: 📋 Getting issued cards...")

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, result: ["cards": []])
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, result: ["cards": []])
            return
        }

        let endpoint = "\(homeBase)/issuing/cards?timestamp=\(timestamp)&pubKey=\(pubKey)&signature=\(signature)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to get issued cards: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, result: ["cards": []])
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ⚠️ Invalid response")
                self.sendResponse(messageId: messageId, result: ["cards": []])
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Got issued cards")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    private func getCardDetails(params: [String: Any], messageId: Any) {
        guard let cardId = params["cardId"] as? String else {
            sendResponse(messageId: messageId, error: "Missing cardId")
            return
        }

        NSLog("PAYMENTMETHOD: 🔍 Getting card details for: %@", cardId)

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, error: "Authentication required")
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey + cardId
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, error: "Failed to sign request")
            return
        }

        let endpoint = "\(homeBase)/issuing/card/\(cardId)/details?timestamp=\(timestamp)&pubKey=\(pubKey)&signature=\(signature)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to get card details: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            if let errorMsg = json["error"] as? String {
                self.sendResponse(messageId: messageId, error: errorMsg)
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Got card details")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    private func updateCardStatus(params: [String: Any], messageId: Any) {
        guard let cardId = params["cardId"] as? String,
              let status = params["status"] as? String else {
            sendResponse(messageId: messageId, error: "Missing cardId or status")
            return
        }

        NSLog("PAYMENTMETHOD: 🔄 Updating card status: %@ -> %@", cardId, status)

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, error: "Authentication required")
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let endpoint = "\(homeBase)/issuing/card/\(cardId)/status"

        let message = timestamp + pubKey + cardId + status
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, error: "Failed to sign request")
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": pubKey,
            "signature": signature,
            "status": status
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to update card status: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            if let errorMsg = json["error"] as? String {
                self.sendResponse(messageId: messageId, error: errorMsg)
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Card status updated")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    private func createCardholder(params: [String: Any], messageId: Any) {
        guard let individualInfo = params["individualInfo"] as? [String: Any],
              let firstName = individualInfo["firstName"] as? String,
              let lastName = individualInfo["lastName"] as? String,
              let name = individualInfo["name"] as? String,
              let email = individualInfo["email"] as? String,
              let phoneNumber = individualInfo["phoneNumber"] as? String,
              let dob = individualInfo["dob"] as? [String: Int],
              let address = individualInfo["address"] as? [String: String] else {
            sendResponse(messageId: messageId, error: "Missing or invalid individual info")
            return
        }

        NSLog("PAYMENTMETHOD: 👤 Creating cardholder: %@", name)

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, error: "Authentication required")
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let endpoint = "\(homeBase)/issuing/cardholder"

        let message = timestamp + pubKey
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, error: "Failed to sign request")
            return
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": pubKey,
            "signature": signature,
            "individualInfo": [
                "firstName": firstName,
                "lastName": lastName,
                "name": name,
                "email": email,
                "phoneNumber": phoneNumber,
                "dob": dob,
                "address": address
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to create cardholder: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            if let errorMsg = json["error"] as? String {
                self.sendResponse(messageId: messageId, error: errorMsg)
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Cardholder created successfully")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    private func getCardholderStatus(messageId: Any) {
        NSLog("PAYMENTMETHOD: 🔍 Checking cardholder status...")

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, result: ["hasCardholder": false])
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, result: ["hasCardholder": false])
            return
        }

        let endpoint = "\(homeBase)/issuing/cardholder/status?timestamp=\(timestamp)&pubKey=\(pubKey)&signature=\(signature)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to check cardholder status: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, result: ["hasCardholder": false])
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let hasCardholder = json["hasCardholder"] as? Bool else {
                NSLog("PAYMENTMETHOD: ⚠️ Invalid response")
                self.sendResponse(messageId: messageId, result: ["hasCardholder": false])
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Cardholder status: %@", hasCardholder ? "exists" : "not found")
            self.sendResponse(messageId: messageId, result: ["hasCardholder": hasCardholder])
        }.resume()
    }

    private func getTransactions(messageId: Any) {
        NSLog("PAYMENTMETHOD: 📊 Getting transactions...")

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, result: ["transactions": []])
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, result: ["transactions": []])
            return
        }

        let endpoint = "\(homeBase)/issuing/transactions?timestamp=\(timestamp)&pubKey=\(pubKey)&signature=\(signature)&limit=10"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to get transactions: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, result: ["transactions": []])
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ⚠️ Invalid response")
                self.sendResponse(messageId: messageId, result: ["transactions": []])
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Got transactions")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    // MARK: - Payout Card Methods (for receiving affiliate commissions)

    private func savePayoutCard(params: [String: Any], messageId: Any) {
        guard let paymentMethodId = params["paymentMethodId"] as? String else {
            sendResponse(messageId: messageId, error: "Missing paymentMethodId")
            return
        }

        NSLog("PAYMENTMETHOD: 💳 Saving payout card: %@", paymentMethodId)

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, error: "Authentication required")
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let endpoint = "\(homeBase)/payout-card/save"

        // Sign request (timestamp + pubKey + paymentMethodId)
        let message = timestamp + pubKey + paymentMethodId
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, error: "Failed to sign request")
            return
        }

        // Build request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "timestamp": timestamp,
            "pubKey": pubKey,
            "signature": signature,
            "paymentMethodId": paymentMethodId
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ❌ Failed to save payout card: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, error: error.localizedDescription)
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ❌ Invalid response")
                self.sendResponse(messageId: messageId, error: "Invalid server response")
                return
            }

            if let errorMsg = json["error"] as? String {
                self.sendResponse(messageId: messageId, error: errorMsg)
                return
            }

            // Store payout card ID in SharedUserDefaults so keyboard extension can access it
            if let payoutCardId = json["payoutCardId"] as? String {
                SharedUserDefaults.shared.set(payoutCardId, forKey: "stripe_payout_card_id")
                SharedUserDefaults.shared.synchronize()
                NSLog("PAYMENTMETHOD: 💳 Saved payout card ID to SharedUserDefaults: %@", payoutCardId)
            }

            NSLog("PAYMENTMETHOD: ✅ Payout card saved successfully")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    private func getPayoutCardStatus(messageId: Any) {
        NSLog("PAYMENTMETHOD: 🔍 Checking payout card status...")

        guard let homeBase = getHomeBaseURL(),
              let keys = sessionless.getKeys() else {
            sendResponse(messageId: messageId, result: ["hasPayoutCard": false])
            return
        }
        let pubKey = keys.publicKey

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey
        guard let signature = signMessage(message) else {
            sendResponse(messageId: messageId, result: ["hasPayoutCard": false])
            return
        }

        let endpoint = "\(homeBase)/payout-card/status?timestamp=\(timestamp)&pubKey=\(pubKey)&signature=\(signature)"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                NSLog("PAYMENTMETHOD: ⚠️ Failed to check payout card status: %@", error.localizedDescription)
                self.sendResponse(messageId: messageId, result: ["hasPayoutCard": false])
                return
            }

            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                NSLog("PAYMENTMETHOD: ⚠️ Invalid response")
                self.sendResponse(messageId: messageId, result: ["hasPayoutCard": false])
                return
            }

            NSLog("PAYMENTMETHOD: ✅ Got payout card status")
            self.sendResponse(messageId: messageId, result: json)
        }.resume()
    }

    // MARK: - Helpers

    private func signMessage(_ message: String) -> String? {
        return sessionless.sign(message: message)
    }

    private func getHomeBaseURL() -> String? {
        // Get home base from localStorage (set by extension)
        if let stored = UserDefaults.standard.string(forKey: "advancement-home-base-url") {
            return stored
        }

        // Default to Configuration's Addie URL (respects environment setting)
        return Configuration.addieBaseURL
    }

    private func sendResponse(messageId: Any, result: [String: Any]? = nil, error: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            var response: [String: Any] = [
                "messageId": messageId
            ]

            if let result = result {
                response["result"] = result
            }

            if let error = error {
                response["error"] = error
            }

            NSLog("PAYMENTMETHOD: 🔄 Sending response to WebView - messageId: %@", String(describing: messageId))

            if let jsonData = try? JSONSerialization.data(withJSONObject: response),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                NSLog("PAYMENTMETHOD: 📤 Response JSON: %@", String(jsonString.prefix(200)))
                let javascript = "window.dispatchEvent(new MessageEvent('message', { data: \(jsonString) }));"

                self.webView.evaluateJavaScript(javascript) { _, error in
                    if let error = error {
                        NSLog("PAYMENTMETHOD: ❌ Failed to send response: %@", error.localizedDescription)
                    } else {
                        NSLog("PAYMENTMETHOD: ✅ Response sent successfully to WebView")
                    }
                }
            } else {
                NSLog("PAYMENTMETHOD: ❌ Failed to serialize response JSON")
            }
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("PAYMENTMETHOD: ✅ WebView loaded successfully")
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("PAYMENTMETHOD: ❌ WebView failed to load: %@", error.localizedDescription)
    }
}

#endif

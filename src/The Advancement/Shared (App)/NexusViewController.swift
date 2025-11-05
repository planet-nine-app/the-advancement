//
//  NexusViewController.swift
//  The Advancement
//
//  Embeds the Nexus web portal for Planet Nine ecosystem access and purchases
//

#if os(iOS)
import UIKit
import WebKit
#elseif os(macOS)
import Cocoa
import WebKit
#endif

#if os(iOS)
class NexusViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private var webView: WKWebView!
    private let nexusURL = "http://127.0.0.1:3006/nexus"
    private let sessionless = Sessionless()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "🌐 Nexus Portal"
        view.backgroundColor = .systemBackground

        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(closeTapped)
        )

        // Add refresh button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .refresh,
            target: self,
            action: #selector(refreshTapped)
        )

        setupWebView()
        loadNexusPortal()

        // Initialize sessionless keys and create all required users
        Task {
            await initializeUsers()
        }

        NSLog("ADVANCEAPP: 🌐 NexusViewController loaded")
    }

    private func setupWebView() {
        // Create web view configuration
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Add script message handler for communication
        config.userContentController.add(self, name: "nexusController")

        // Create web view
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)

        // Setup constraints
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadNexusPortal() {
        guard let url = URL(string: nexusURL) else {
            NSLog("ADVANCEAPP: ❌ Invalid Nexus URL: %@", nexusURL)
            showErrorMessage("Invalid Nexus URL")
            return
        }

        NSLog("ADVANCEAPP: 📡 Loading Nexus portal from: %@", nexusURL)

        let request = URLRequest(url: url)
        webView.load(request)
    }

    private func showErrorMessage(_ message: String) {
        let alert = UIAlertController(
            title: "Nexus Portal Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func closeTapped() {
        NSLog("ADVANCEAPP: 🌐 Closing Nexus portal")
        dismiss(animated: true)
    }

    @objc private func refreshTapped() {
        NSLog("ADVANCEAPP: 🔄 Refreshing Nexus portal")
        loadNexusPortal()
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        NSLog("ADVANCEAPP: 📡 Nexus portal loading started")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("ADVANCEAPP: ✅ Nexus portal loaded successfully")

        // Inject JavaScript to integrate with The Advancement
        let integrationScript = """
            // Identify this as The Advancement app context
            window.theAdvancementApp = true;

            // Add payment method storage callback
            window.onPaymentMethodSaved = function(paymentMethod) {
                window.webkit.messageHandlers.nexusController.postMessage({
                    type: 'paymentMethodSaved',
                    paymentMethod: paymentMethod
                });
            };

            // Add purchase completion callback
            window.onPurchaseComplete = function(purchaseData) {
                window.webkit.messageHandlers.nexusController.postMessage({
                    type: 'purchaseComplete',
                    purchaseData: purchaseData
                });
            };

            console.log('🍎 The Advancement integration scripts loaded');
        """

        webView.evaluateJavaScript(integrationScript) { (result, error) in
            if let error = error {
                NSLog("ADVANCEAPP: ⚠️ Failed to inject integration script: %@", error.localizedDescription)
            } else {
                NSLog("ADVANCEAPP: ✅ Integration script injected successfully")
            }
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        NSLog("ADVANCEAPP: ❌ Nexus portal failed to load: %@", error.localizedDescription)

        // Show helpful error message
        let errorMessage = """
        Could not connect to Nexus portal.

        Please ensure:
        • Fount server is running on localhost:3006
        • Network connection is available

        Error: \(error.localizedDescription)
        """

        showErrorMessage(errorMessage)
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? [String: Any],
              let messageType = messageBody["type"] as? String else {
            NSLog("ADVANCEAPP: ⚠️ Invalid message received from Nexus")
            return
        }

        NSLog("ADVANCEAPP: 📨 Received message from Nexus: %@", messageType)

        switch messageType {
        case "paymentMethodSaved":
            handlePaymentMethodSaved(messageBody)
        case "purchaseComplete":
            handlePurchaseComplete(messageBody)
        case "storePaymentMethod":
            handleStorePaymentMethod(messageBody)
        case "getUserCredentials":
            handleGetUserCredentials(messageBody)
        case "signMessage":
            handleSignMessage(messageBody)
        default:
            NSLog("ADVANCEAPP: ⚠️ Unknown message type: %@", messageType)
        }
    }

    private func handlePaymentMethodSaved(_ messageBody: [String: Any]) {
        guard let paymentMethod = messageBody["paymentMethod"] as? [String: Any] else {
            NSLog("ADVANCEAPP: ❌ Invalid payment method data")
            return
        }

        NSLog("ADVANCEAPP: 💳 Payment method saved: %@", paymentMethod)

        // Store payment method for keyboard extension use
        // This will be implemented to store in shared UserDefaults
        storePaymentMethodForKeyboard(paymentMethod)

        // Show success message
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "💳 Payment Method Saved",
                message: "Your payment method has been saved and is now available for quick purchases.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Great!", style: .default))
            self.present(alert, animated: true)
        }
    }

    private func handlePurchaseComplete(_ messageBody: [String: Any]) {
        guard let purchaseData = messageBody["purchaseData"] as? [String: Any] else {
            NSLog("ADVANCEAPP: ❌ Invalid purchase data")
            return
        }

        NSLog("ADVANCEAPP: 🎉 Purchase completed: %@", purchaseData)

        // Show success message
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "🎉 Purchase Successful",
                message: "Your purchase has been completed successfully!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Awesome!", style: .default))
            self.present(alert, animated: true)
        }
    }

    private func handleStorePaymentMethod(_ messageBody: [String: Any]) {
        guard let product = messageBody["product"] as? [String: Any] else {
            NSLog("ADVANCEAPP: ❌ Invalid product data in storePaymentMethod")
            return
        }

        let paymentIntentId = messageBody["paymentIntentId"] as? String ?? ""
        let paymentMethodId = messageBody["paymentMethodId"] as? String ?? ""

        NSLog("ADVANCEAPP: 🎉 Processing successful purchase - Product: %@, PaymentIntent: %@",
              product["title"] as? String ?? "Unknown", paymentIntentId)

        // Store payment method for keyboard extension use
        let paymentMethodData: [String: Any] = [
            "paymentMethodId": paymentMethodId,
            "paymentIntentId": paymentIntentId,
            "product": product
        ]
        storePaymentMethodForKeyboard(paymentMethodData)

        // Payment method will be automatically saved by Stripe since we set savePaymentMethod: true
        // when providing user credentials to Nexus portal
        NSLog("ADVANCEAPP: 💳 Payment method %@ should be automatically saved by Stripe", paymentMethodId)

        // If it's an ebook, save to CarrierBag bookshelf
        let productType = product["type"] as? String ?? ""
        let productTitle = product["title"] as? String ?? ""

        if productType.lowercased().contains("ebook") || productTitle.lowercased().contains("book") {
            NSLog("ADVANCEAPP: 📚 Product is an ebook, saving to CarrierBag bookshelf")
            saveEbookToCarrierBag(product)
        } else {
            NSLog("ADVANCEAPP: 📦 Product type: %@, not saving to bookshelf", productType)
        }

        // Show success message
        DispatchQueue.main.async {
            let message = productType.lowercased().contains("ebook") || productTitle.lowercased().contains("book") ?
                "Your payment method has been saved and the ebook has been added to your CarrierBag bookshelf!" :
                "Your payment method has been saved for future purchases!"

            let alert = UIAlertController(
                title: "🎉 Purchase Successful",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Great!", style: .default))
            self.present(alert, animated: true)
        }
    }

    private func saveEbookToCarrierBag(_ product: [String: Any]) {
        Task {
            do {
                guard let keys = sessionless.getKeys() else {
                    NSLog("ADVANCEAPP: ❌ [CARRRIERBAG] No sessionless keys available")
                    return
                }

                // Fetch current CarrierBag from BDO with hash parameter
                let uuid = getStoredAddieUUID(for: keys.publicKey)
                let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
                let hash = "the-advancement"
                let bdoUrl = "http://127.0.0.1:5114/user/\(uuid)/bdo?timestamp=\(timestamp)&hash=\(hash)"
                guard let url = URL(string: bdoUrl) else { return }

                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    NSLog("ADVANCEAPP: ⚠️ [CARRIERBAG] Failed to fetch current CarrierBag")
                    return
                }

                guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let bdoData = jsonObject["data"] as? [String: Any],
                      var carrierBag = bdoData["carrierBag"] as? [String: Any] else {
                    NSLog("ADVANCEAPP: ⚠️ [CARRIERBAG] No CarrierBag found in BDO")
                    return
                }

                // Add ebook to bookshelf collection
                var bookshelfItems = carrierBag["bookshelf"] as? [[String: Any]] ?? []

                let ebookItem: [String: Any] = [
                    "title": product["title"] as? String ?? "Unknown Book",
                    "type": "ebook",
                    "productId": product["productId"] as? String ?? product["uuid"] as? String ?? "",
                    "price": product["price"] ?? 0,
                    "description": product["description"] as? String ?? "",
                    "savedAt": ISO8601DateFormatter().string(from: Date()),
                    "purchasedFromNexus": true
                ]

                bookshelfItems.append(ebookItem)
                carrierBag["bookshelf"] = bookshelfItems
                carrierBag["lastUpdated"] = ISO8601DateFormatter().string(from: Date())

                // Update CarrierBag in Fount
                let updatedBDO = [
                    "data": [
                        "type": "carrierBag",
                        "owner": getStoredAddieUUID(for: keys.publicKey),
                        "carrierBag": carrierBag
                    ]
                ]

                try await updateCarrierBagInFount(bdo: updatedBDO, publicKey: keys.publicKey)

                NSLog("ADVANCEAPP: ✅ [CARRIERBAG] Ebook '%@' saved to bookshelf", product["title"] as? String ?? "Unknown")

            } catch {
                NSLog("ADVANCEAPP: ❌ [CARRIERBAG] Failed to save ebook: %@", error.localizedDescription)
            }
        }
    }

    private func updateCarrierBagInFount(bdo: [String: Any], publicKey: String) async throws {
        let uuid = getStoredAddieUUID(for: publicKey)
        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "the-advancement"
        let bdoUrl = "http://127.0.0.1:5114/user/\(uuid)/bdo?timestamp=\(timestamp)&hash=\(hash)"
        guard let url = URL(string: bdoUrl) else {
            throw NSError(domain: "BDOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: bdo)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "FountError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to update CarrierBag"])
        }

        NSLog("ADVANCEAPP: ✅ [CARRIERBAG] CarrierBag updated successfully in BDO")
    }

    private func storePaymentMethodForKeyboard(_ paymentMethod: [String: Any]) {
        // Store payment method data in shared UserDefaults for keyboard extension access
        let userDefaults = UserDefaults(suiteName: "group.com.planetnine.Planet-Nine")

        // Store the payment method with a timestamp
        var storedMethods = userDefaults?.array(forKey: "stored_payment_methods") as? [[String: Any]] ?? []

        var paymentMethodWithTimestamp = paymentMethod
        paymentMethodWithTimestamp["saved_at"] = Date().timeIntervalSince1970

        storedMethods.append(paymentMethodWithTimestamp)

        userDefaults?.set(storedMethods, forKey: "stored_payment_methods")
        userDefaults?.synchronize()

        NSLog("ADVANCEAPP: 💾 Payment method stored for keyboard extension access")
    }

    private func handleGetUserCredentials(_ messageBody: [String: Any]) {
        NSLog("ADVANCEAPP: 🔐 [CREDENTIALS] Getting user credentials for payment")

        guard let callbackName = messageBody["callbackName"] as? String else {
            NSLog("ADVANCEAPP: ❌ [CREDENTIALS] No callback name provided for getUserCredentials")
            return
        }

        // Get real user credentials from stored Addie user or sessionless keys
        let userCredentials: [String: Any]

        if let addieUserData = UserDefaults.standard.data(forKey: "addieUser"),
           let addieUser = try? JSONSerialization.jsonObject(with: addieUserData) as? [String: Any],
           let uuid = addieUser["uuid"] as? String,
           let publicKey = addieUser["pubKey"] as? String {

            // Use real Addie user data
            NSLog("ADVANCEAPP: ✅ [CREDENTIALS] Using stored Addie user: %@", uuid)

            // Get private key from sessionless
            guard let keys = sessionless.getKeys() else {
                NSLog("ADVANCEAPP: ❌ [CREDENTIALS] No sessionless keys available")
                return
            }

            userCredentials = [
                "uuid": uuid,
                "privateKey": keys.privateKey,
                "publicKey": publicKey,
                "savePaymentMethod": true,
                "stripeCustomerId": uuid,  // Use Addie UUID as Stripe customer ID
                "setupFutureUsage": "off_session"  // Tell Stripe to save for future payments
            ]

            NSLog("ADVANCEAPP: 📊 [CREDENTIALS] Credentials prepared with UUID: %@", uuid)

        } else {
            NSLog("ADVANCEAPP: ⚠️ [CREDENTIALS] No stored Addie user found, using fallback test credentials")

            // Fallback to test credentials
            userCredentials = [
                "uuid": "test-advancement-user-uuid",
                "privateKey": "test-advancement-private-key",
                "publicKey": "test-advancement-public-key",
                "savePaymentMethod": true,
                "stripeCustomerId": "test-advancement-user-uuid",  // Use test UUID as customer ID
                "setupFutureUsage": "off_session"  // Tell Stripe to save for future payments
            ]
        }

        NSLog("ADVANCEAPP: 📦 [CREDENTIALS] Sending credentials with UUID: %@ and Stripe customer ID: %@",
              userCredentials["uuid"] as? String ?? "unknown",
              userCredentials["stripeCustomerId"] as? String ?? "unknown")

        // Send credentials back to JavaScript
        let responseScript = """
            if (window.\(callbackName)) {
                window.\(callbackName)(\(jsonString(from: userCredentials)));
            }
        """

        webView.evaluateJavaScript(responseScript) { (result, error) in
            if let error = error {
                NSLog("ADVANCEAPP: ❌ [CREDENTIALS] Failed to send user credentials: %@", error.localizedDescription)
            } else {
                NSLog("ADVANCEAPP: ✅ [CREDENTIALS] User credentials sent to Nexus successfully")
            }
        }
    }

    private func handleSignMessage(_ messageBody: [String: Any]) {
        NSLog("ADVANCEAPP: ✍️ [SIGNING] Starting message signing for payment")

        guard let callbackName = messageBody["callbackName"] as? String,
              let message = messageBody["message"] as? String else {
            NSLog("ADVANCEAPP: ❌ [SIGNING] Invalid signMessage request - missing callback or message")
            return
        }

        NSLog("ADVANCEAPP: 📝 [SIGNING] Message to sign: %@", message)
        NSLog("ADVANCEAPP: 📞 [SIGNING] Callback function: %@", callbackName)

        // Use real sessionless signing instead of test signature
        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP: ❌ [SIGNING] Failed to sign message with sessionless")

            // Send error back to JavaScript
            let errorData: [String: Any] = [
                "error": "Failed to sign message"
            ]

            let errorScript = """
                if (window.\(callbackName)) {
                    window.\(callbackName)(\(jsonString(from: errorData)));
                }
            """

            webView.evaluateJavaScript(errorScript) { (result, error) in
                if let error = error {
                    NSLog("ADVANCEAPP: ❌ [SIGNING] Failed to send error response: %@", error.localizedDescription)
                }
            }
            return
        }

        NSLog("ADVANCEAPP: ✅ [SIGNING] Message signed successfully, signature length: %d", signature.count)

        let responseData: [String: Any] = [
            "signature": signature
        ]

        // Send signature back to JavaScript
        let responseScript = """
            if (window.\(callbackName)) {
                window.\(callbackName)(\(jsonString(from: responseData)));
            }
        """

        webView.evaluateJavaScript(responseScript) { (result, error) in
            if let error = error {
                NSLog("ADVANCEAPP: ❌ [SIGNING] Failed to send signature: %@", error.localizedDescription)
            } else {
                NSLog("ADVANCEAPP: ✅ [SIGNING] Signature sent to Nexus successfully")
            }
        }
    }

    private func jsonString(from dictionary: [String: Any]) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }

    private func initializeUsers() async {
        NSLog("ADVANCEAPP: 🚀 [INIT] Starting user initialization...")

        // Step 1: Ensure sessionless keys exist
        await ensureSessionlessKeys()

        // Step 2: Create/verify Fount user
        await ensureFountUserExists()

        // Step 3: Create/verify Addie user
        await ensureAddieUserExists()

        NSLog("ADVANCEAPP: ✅ [INIT] User initialization complete")
    }

    private func ensureSessionlessKeys() async {
        NSLog("ADVANCEAPP: 🔑 [KEYS] Checking sessionless keys...")

        if let keys = sessionless.getKeys() {
            NSLog("ADVANCEAPP: ✅ [KEYS] Sessionless keys already exist")
            NSLog("ADVANCEAPP: 📊 [KEYS] Public key: %@", keys.publicKey.prefix(20) + "...")
            NSLog("ADVANCEAPP: 📊 [KEYS] Private key length: %d", keys.privateKey.count)
        } else {
            NSLog("ADVANCEAPP: 🔧 [KEYS] No sessionless keys found, generating new ones...")
            let newKeys = sessionless.generateKeys()
            if newKeys != nil {
                if let newKeys = sessionless.getKeys() {
                    NSLog("ADVANCEAPP: ✅ [KEYS] New sessionless keys generated successfully")
                    NSLog("ADVANCEAPP: 📊 [KEYS] New public key: %@", newKeys.publicKey.prefix(20) + "...")
                } else {
                    NSLog("ADVANCEAPP: ❌ [KEYS] Keys generated but could not retrieve them")
                }
            } else {
                NSLog("ADVANCEAPP: ❌ [KEYS] Failed to generate sessionless keys")
            }
        }
    }

    private func ensureFountUserExists() async {
        NSLog("ADVANCEAPP: ⛲ [FOUNT] Checking Fount user...")

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
                  let url = URL(string: "http://127.0.0.1:5114/user/create") else {
                NSLog("ADVANCEAPP: ❌ [BDO] Failed to create BDO user request")
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
                            "ordinal": 0,
                            "created": timestamp,
                            "pubKey": keys.publicKey
                        ]

                        // Store UUID in App Group for AdvanceKey access
                        SharedUserDefaults.setFountUserUUID(uuid)

                        // Also store full user data in standard UserDefaults for app use
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

        // Create new user using real sessionless keys (like Fount)
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

    // MARK: - UUID Management

    private func savePaymentMethodToAddie(paymentMethodId: String, paymentIntentId: String) async {
        NSLog("ADVANCEAPP: 💳 [ADDIE] Saving payment method to Addie API...")

        guard let addieUUID = getStoredAddieUUID() else {
            NSLog("ADVANCEAPP: ❌ [ADDIE] No Addie UUID available for payment method storage")
            return
        }

        guard let keys = sessionless.getKeys() else {
            NSLog("ADVANCEAPP: ❌ [ADDIE] No sessionless keys available")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + addieUUID + paymentMethodId

        guard let signature = sessionless.sign(message: message) else {
            NSLog("ADVANCEAPP: ❌ [ADDIE] Failed to sign payment method storage request")
            return
        }

        let payload: [String: Any] = [
            "uuid": addieUUID,
            "paymentMethodId": paymentMethodId,
            "paymentIntentId": paymentIntentId,
            "timestamp": timestamp,
            "signature": signature
        ]

        do {
            guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
                  let url = URL(string: "http://127.0.0.1:5116/save-payment-method") else {
                NSLog("ADVANCEAPP: ❌ [ADDIE] Failed to create payment method storage request")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    NSLog("ADVANCEAPP: ✅ [ADDIE] Payment method saved to Addie successfully")
                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("ADVANCEAPP: 📄 [ADDIE] Response: %@", responseString)
                    }
                } else {
                    NSLog("ADVANCEAPP: ⚠️ [ADDIE] Payment method storage failed with status: %d", httpResponse.statusCode)
                    if let responseString = String(data: data, encoding: .utf8) {
                        NSLog("ADVANCEAPP: ❌ [ADDIE] Error: %@", responseString)
                    }
                }
            }
        } catch {
            NSLog("ADVANCEAPP: ❌ [ADDIE] Failed to save payment method: %@", error.localizedDescription)
        }
    }

    private func getStoredAddieUUID() -> String? {
        if let addieUserData = UserDefaults.standard.data(forKey: "addieUser"),
           let addieUser = try? JSONSerialization.jsonObject(with: addieUserData) as? [String: Any],
           let uuid = addieUser["uuid"] as? String {
            return uuid
        }
        return nil
    }

    private func getStoredAddieUUID(for publicKey: String) -> String {
        // Get UUID from stored Addie user data
        if let existingUser = UserDefaults.standard.data(forKey: "addieUser"),
           let userData = try? JSONSerialization.jsonObject(with: existingUser) as? [String: Any],
           let uuid = userData["uuid"] as? String {
            NSLog("ADVANCEAPP: 🔄 Using stored Addie UUID: %@", uuid)

            // Also store in shared UserDefaults for cross-app access
            let sharedDefaults = UserDefaults(suiteName: "group.com.planetnine.Planet-Nine")
            sharedDefaults?.set(uuid, forKey: "user_uuid")

            return uuid
        }

        NSLog("ADVANCEAPP: ❌ No Addie user found, UUID not available")
        return "no-uuid-available"
    }
}

#elseif os(macOS)
// macOS implementation would go here if needed
class NexusViewController: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("ADVANCEAPP: 🌐 NexusViewController (macOS) - not implemented yet")
    }
}
#endif

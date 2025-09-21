//
//  KeyboardViewController.swift
//  AdvanceKey
//
//  Created by Zach Babb on 9/20/25.
//

import UIKit
import WebKit

class KeyboardViewController: UIInputViewController {

    @IBOutlet var nextKeyboardButton: UIButton!
    var decodeButton: UIButton!
    var debugLabel: UILabel!
    var productsWebView: WKWebView!
    var paymentWebView: WKWebView!
    var currentView: WebViewType = .none
    var sanoraService: SanoraService!
    var selectedProduct: SanoraService.Product?

    enum WebViewType {
        case none, products, payment
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()

        // Set keyboard height - keyboards need explicit height constraints
        let heightConstraint = NSLayoutConstraint(
            item: self.view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: 280 // Keyboard height
        )
        heightConstraint.priority = UILayoutPriority(999)
        self.view.addConstraint(heightConstraint)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("🚀 AdvanceKey keyboard loading...")
        self.view.backgroundColor = UIColor.systemGray6

        // Initialize Sanora service
        sanoraService = SanoraService()

        setupWebViews()
        setupDecodeButton()
        setupToggleButton()
        addStatusLabel()
        addDebugLabel()

        print("✅ AdvanceKey keyboard setup complete")
    }

    func addStatusLabel() {
        // Add a small status label to show the keyboard is working
        let statusLabel = UILabel()
        statusLabel.text = "🚀 The Advancement Keyboard"
        statusLabel.font = UIFont.systemFont(ofSize: 10, weight: .light)
        statusLabel.textColor = UIColor.systemGray
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 5),
            statusLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor)
        ])
    }

    func addDebugLabel() {
        // Add debug label to show emojicode and decoded UUID
        debugLabel = UILabel()
        debugLabel.text = "Select emoji text and tap Decode"
        debugLabel.font = UIFont.systemFont(ofSize: 9, weight: .regular)
        debugLabel.textColor = UIColor.systemGray2
        debugLabel.textAlignment = .center
        debugLabel.numberOfLines = 3
        debugLabel.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(debugLabel)

        NSLayoutConstraint.activate([
            debugLabel.bottomAnchor.constraint(equalTo: self.decodeButton.topAnchor, constant: -5),
            debugLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            debugLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            debugLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func setupDecodeButton() {
        // Create decode button above the main button
        decodeButton = UIButton(type: .system)
        decodeButton.setTitle("🔍 Decode UUID", for: .normal)
        decodeButton.sizeToFit()
        decodeButton.translatesAutoresizingMaskIntoConstraints = false
        decodeButton.backgroundColor = UIColor.systemOrange
        decodeButton.setTitleColor(.white, for: .normal)
        decodeButton.layer.cornerRadius = 8
        decodeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)

        // Add decode action
        decodeButton.addTarget(self, action: #selector(decodeSelectedText), for: .touchUpInside)

        self.view.addSubview(decodeButton)

        NSLayoutConstraint.activate([
            decodeButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            decodeButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50),
            decodeButton.heightAnchor.constraint(equalToConstant: 30),
            decodeButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }

    func setupWebViews() {
        // Configure WebView with message handler
        let configuration = WKWebViewConfiguration()
        let contentController = WKUserContentController()

        // Add message handler for JavaScript to Swift communication
        contentController.add(self, name: "keyboardAction")
        configuration.userContentController = contentController

        // Create Products WebView
        productsWebView = WKWebView(frame: .zero, configuration: configuration)
        productsWebView.translatesAutoresizingMaskIntoConstraints = false
        productsWebView.backgroundColor = UIColor.systemBackground
        productsWebView.isHidden = true

        // Create Payment WebView (with fresh configuration to avoid conflicts)
        let paymentConfiguration = WKWebViewConfiguration()
        let paymentContentController = WKUserContentController()
        paymentContentController.add(self, name: "keyboardAction")
        paymentConfiguration.userContentController = paymentContentController

        paymentWebView = WKWebView(frame: .zero, configuration: paymentConfiguration)
        paymentWebView.translatesAutoresizingMaskIntoConstraints = false
        paymentWebView.backgroundColor = UIColor.systemBackground
        paymentWebView.isHidden = true

        // Add both WebViews to the view
        self.view.addSubview(productsWebView)
        self.view.addSubview(paymentWebView)

        // Set up constraints for both WebViews (they'll occupy the same space)
        NSLayoutConstraint.activate([
            // Products WebView constraints
            productsWebView.topAnchor.constraint(equalTo: self.view.topAnchor),
            productsWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            productsWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            productsWebView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50),

            // Payment WebView constraints (same as products)
            paymentWebView.topAnchor.constraint(equalTo: self.view.topAnchor),
            paymentWebView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            paymentWebView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            paymentWebView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -50)
        ])

        print("✅ Dual WebViews setup complete")
    }


    func setupToggleButton() {
        // Create toggle button to show/hide WebView
        self.nextKeyboardButton = UIButton(type: .system)

        updateToggleButtonTitle()
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        self.nextKeyboardButton.backgroundColor = UIColor.systemBlue
        self.nextKeyboardButton.setTitleColor(.white, for: .normal)
        self.nextKeyboardButton.layer.cornerRadius = 8

        // Customize the appearance to indicate this is The Advancement keyboard
        self.nextKeyboardButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)

        // Add only toggle action - remove keyboard switch to prevent conflicts
        self.nextKeyboardButton.addTarget(self, action: #selector(toggleWebView), for: .touchUpInside)

        self.view.addSubview(self.nextKeyboardButton)

        NSLayoutConstraint.activate([
            self.nextKeyboardButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10),
            self.nextKeyboardButton.topAnchor.constraint(equalTo: self.decodeButton.bottomAnchor, constant: 5),
            self.nextKeyboardButton.heightAnchor.constraint(equalToConstant: 30),
            self.nextKeyboardButton.widthAnchor.constraint(equalToConstant: 120)
        ])
    }

    @objc func toggleWebView() {
        switch currentView {
        case .none:
            showProductsView()
        case .products:
            hideAllViews()
        case .payment:
            hideAllViews()
        }
    }

    func showProductsView() {
        currentView = .products
        productsWebView.isHidden = false
        paymentWebView.isHidden = true
        updateToggleButtonTitle()

        print("📦 Showing products view")
        loadProductsFromSanora()
    }

    func showPaymentView(for product: SanoraService.Product) {
        selectedProduct = product
        currentView = .payment
        productsWebView.isHidden = true
        paymentWebView.isHidden = false
        updateToggleButtonTitle()

        print("💳 Showing payment view for: \(product.title)")
        loadPaymentMethods(for: product)
    }

    func hideAllViews() {
        currentView = .none
        productsWebView.isHidden = true
        paymentWebView.isHidden = true
        updateToggleButtonTitle()

        print("🔒 Hiding all views")
    }

    func updateToggleButtonTitle() {
        switch currentView {
        case .none:
            self.nextKeyboardButton.setTitle("🚀 Advancement", for: .normal)
        case .products:
            self.nextKeyboardButton.setTitle("📦 Hide Products", for: .normal)
        case .payment:
            self.nextKeyboardButton.setTitle("💳 Hide Payment", for: .normal)
        }
    }

    // MARK: - Sanora Integration
    func loadProductsFromSanora() {
        print("Loading products from Sanora service...")

        Task {
            do {
                let products = try await sanoraService.fetchAllProducts()
                print("✅ Loaded \(products.count) products from Sanora")

                // Print all available product UUIDs for comparison
                print("📦 Available product UUIDs:")
                for product in products {
                    print("  - \(product.title): '\(product.uuid)'")
                }

                // Generate HTML using template system
                do {
                    let productsHTML = try HTMLTemplateService.generateProductsHTML(products: products)

                    // Load the generated HTML into the products WebView
                    DispatchQueue.main.async {
                        self.productsWebView.loadHTMLString(productsHTML, baseURL: nil)
                    }
                } catch {
                    print("❌ Failed to generate products HTML: \(error)")

                    // Show clear error message - NO FALLBACKS
                    let errorHTML = """
                    <!DOCTYPE html>
                    <html>
                    <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>body{padding: 20px; background: #f0f0f0; font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center;}</style>
                    </head>
                    <body>
                        <h1>❌ Template Error</h1>
                        <p>\(error.localizedDescription)</p>
                        <p>Check that products-template.html is included in the Xcode project target.</p>
                    </body>
                    </html>
                    """

                    DispatchQueue.main.async {
                        self.productsWebView.loadHTMLString(errorHTML, baseURL: nil)
                    }
                }

            } catch {
                print("❌ Failed to load products from Sanora: \(error)")

                // Show clear Sanora error message - NO FALLBACKS
                let errorHTML = """
                <!DOCTYPE html>
                <html>
                <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>body{padding: 20px; background: #f0f0f0; font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center;}</style>
                </head>
                <body>
                    <h1>🔌 Sanora Connection Error</h1>
                    <p>\(error.localizedDescription)</p>
                    <p>Check that Sanora is running at http://127.0.0.1:5121</p>
                </body>
                </html>
                """

                DispatchQueue.main.async {
                    self.productsWebView.loadHTMLString(errorHTML, baseURL: nil)
                }
            }
        }
    }

    func loadPaymentMethods(for product: SanoraService.Product) {
        print("Loading payment methods for product: \(product.title)")

        // Mock payment methods for now - in production you'd load from Addie
        let mockPaymentMethods = [
            PaymentMethod(id: "pm_1", brand: "Visa", last4: "1234"),
            PaymentMethod(id: "pm_2", brand: "Mastercard", last4: "5678")
        ]

        // Generate HTML using template system
        do {
            let paymentHTML = try HTMLTemplateService.generatePaymentHTML(
                selectedProduct: product,
                paymentMethods: mockPaymentMethods
            )

            // Load the generated HTML into the payment WebView
            DispatchQueue.main.async {
                self.paymentWebView.loadHTMLString(paymentHTML, baseURL: nil)
            }
        } catch {
            print("❌ Failed to generate payment HTML: \(error)")

            // Show clear error message - NO FALLBACKS
            let errorHTML = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body{padding: 20px; background: #f0f0f0; font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center;}</style>
            </head>
            <body>
                <h1>❌ Payment Template Error</h1>
                <p>\(error.localizedDescription)</p>
                <p>Check that payment-template.html is included in the Xcode project target.</p>
            </body>
            </html>
            """

            DispatchQueue.main.async {
                self.paymentWebView.loadHTMLString(errorHTML, baseURL: nil)
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        // Always show the button (don't hide based on needsInputModeSwitchKey)
        self.nextKeyboardButton.isHidden = false
        super.viewWillLayoutSubviews()
    }
    
    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        
        var textColor: UIColor
        let proxy = self.textDocumentProxy
        if proxy.keyboardAppearance == UIKeyboardAppearance.dark {
            textColor = UIColor.white
        } else {
            textColor = UIColor.black
        }
        self.nextKeyboardButton.setTitleColor(textColor, for: [])
    }
}

// MARK: - WKScriptMessageHandler
extension KeyboardViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("Received message from WebView: \(message.name)")

        guard message.name == "keyboardAction",
              let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String else {
            print("Invalid message format received")
            return
        }

        print("Action: \(action)")
        print("Full message: \(messageBody)")

        // Handle different actions from the WebView
        switch action {
        case "selectPayment":
            handleSelectPayment(messageBody)

        case "selectPaymentMethod":
            handleSelectPaymentMethod(messageBody)

        case "addPayment", "addPaymentMethod":
            handleAddPayment()

        case "completePayment":
            handleCompletePayment(messageBody)

        case "cancelPayment":
            handleCancelPayment()

        case "close":
            handleCloseKeyboard()

        case "buyProduct":
            handleBuyProduct(messageBody)

        case "viewProduct":
            handleViewProduct(messageBody)

        case "copyEmojiUUID":
            handleCopyEmojiUUID(messageBody)

        case "copyError":
            handleCopyError(messageBody)

        default:
            print("Unknown action: \(action)")
        }
    }

    // MARK: - Action Handlers
    private func handleSelectPayment(_ messageBody: [String: Any]) {
        guard let paymentId = messageBody["paymentId"] as? String,
              let description = messageBody["description"] as? String else {
            print("Missing payment selection data")
            return
        }

        print("Payment method selected: \(paymentId) - \(description)")

        // Here you would integrate with your addie payment system
        // For now, we'll just insert some text to show the communication works
        let proxy = self.textDocumentProxy
        proxy.insertText("💳 Selected: \(description)")

        // Hide the payment WebView after selection
        hideAllViews()

        // Send success back to payment WebView (optional)
        let script = "updateStatus('Payment method selected successfully');"
        paymentWebView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error updating WebView: \(error)")
            }
        }
    }

    private func handleSelectPaymentMethod(_ messageBody: [String: Any]) {
        guard let methodId = messageBody["methodId"] as? String,
              let methodData = messageBody["methodData"] as? [String: Any] else {
            print("Missing payment method selection data")
            return
        }

        print("Payment method selected: \(methodId) - \(methodData)")

        // Extract payment method details
        let brand = methodData["brand"] as? String ?? "Unknown"
        let last4 = methodData["last4"] as? String ?? "****"

        // Insert text to show the selection worked
        let proxy = self.textDocumentProxy
        proxy.insertText("💳 Selected: \(brand) •••• \(last4)")

        print("Selected payment method: \(brand) ending in \(last4)")
    }

    private func handleCompletePayment(_ messageBody: [String: Any]) {
        guard let paymentMethod = messageBody["paymentMethod"] as? [String: Any] else {
            print("Missing payment method data for completion")
            return
        }

        print("Completing payment with method: \(paymentMethod)")

        // Here you would integrate with Addie to process the actual payment
        let proxy = self.textDocumentProxy
        proxy.insertText("✅ Payment completed!")

        // Hide payment view after completion
        hideAllViews()
    }

    private func handleCancelPayment() {
        print("Payment cancelled by user")

        let proxy = self.textDocumentProxy
        proxy.insertText("❌ Payment cancelled")

        // Hide payment view
        hideAllViews()
    }

    private func handleBuyProduct(_ messageBody: [String: Any]) {
        guard let productId = messageBody["productId"] as? String,
              let title = messageBody["title"] as? String,
              let price = messageBody["price"] as? Int else {
            print("Missing product data for purchase")
            return
        }

        print("Buy product requested: \(title) (\(productId))")

        // Find the product from Sanora and show payment view
        Task {
            do {
                let products = try await sanoraService.fetchAllProducts()
                if let product = products.first(where: { $0.productId == productId }) {
                    showPaymentView(for: product)
                } else {
                    print("Product not found: \(productId)")
                    let proxy = self.textDocumentProxy
                    proxy.insertText("❌ Product not found")
                }
            } catch {
                print("Failed to load product for purchase: \(error)")
                let proxy = self.textDocumentProxy
                proxy.insertText("❌ Failed to load product")
            }
        }
    }

    private func handleViewProduct(_ messageBody: [String: Any]) {
        guard let productId = messageBody["productId"] as? String,
              let title = messageBody["title"] as? String else {
            print("Missing product data for viewing")
            return
        }

        print("View product: \(title) (\(productId))")

        // For now, just provide feedback that the product was viewed
        let proxy = self.textDocumentProxy
        proxy.insertText("👀 Viewed: \(title)")
    }

    private func handleCopyEmojiUUID(_ messageBody: [String: Any]) {
        guard let emojiUUID = messageBody["emojiUUID"] as? String,
              let originalUUID = messageBody["originalUUID"] as? String else {
            print("Missing emoji UUID data for copying")
            return
        }

        let productTitle = messageBody["productTitle"] as? String ?? "Unknown Product"

        print("✅ Copying emojicoded UUID for \(productTitle): \(emojiUUID)")

        // Insert the emojicoded UUID into the text field
        let proxy = self.textDocumentProxy
        proxy.insertText(emojiUUID)

        print("📋 Inserted emojicoded UUID into text field")
    }

    private func handleCopyError(_ messageBody: [String: Any]) {
        guard let error = messageBody["error"] as? String else {
            print("Missing error data")
            return
        }

        let originalUUID = messageBody["originalUUID"] as? String ?? "N/A"

        print("❌ Copy error: \(error) (Original UUID: \(originalUUID))")

        // Insert error message into text field - NO FALLBACKS
        let proxy = self.textDocumentProxy
        proxy.insertText("❌ \(error)")

        print("📝 Inserted error message into text field")
    }

    @objc func decodeSelectedText() {
        print("🔍 Decode button tapped")

        // Get selected text from the current text input
        let proxy = self.textDocumentProxy
        guard let selectedText = proxy.selectedText, !selectedText.isEmpty else {
            let errorMessage = "No text selected"
            print("❌ \(errorMessage)")
            updateDebugLabel(emojicode: "N/A", decodedUUID: "❌ \(errorMessage)", error: true)
            return
        }

        print("📋 Selected text: \(selectedText)")
        updateDebugLabel(emojicode: selectedText, decodedUUID: "Decoding...", error: false)

        // Ensure products WebView is loaded with emojicoding.js before attempting decode
        if currentView != .products {
            print("🔍 Products WebView not loaded, loading it first...")
            showProductsView()

            // Wait a moment for the WebView to load, then try decode
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.performDecode(selectedText)
            }
        } else {
            print("🔍 Products WebView already loaded, attempting decode...")
            performDecode(selectedText)
        }
    }

    private func performDecode(_ selectedText: String) {
        // Decode emoji to hex UUID - NO FALLBACKS
        Task {
            do {
                let decodedHex = try await decodeEmojiToHex(selectedText)
                let formattedUUID = formatHexAsUUID(decodedHex)

                print("✅ Decoded UUID: \(formattedUUID)")
                updateDebugLabel(emojicode: selectedText, decodedUUID: formattedUUID, error: false)

                // Fetch product by UUID from Sanora
                fetchProductByUUID(formattedUUID)

            } catch {
                let errorMessage = "Decode failed: \(error.localizedDescription)"
                print("❌ \(errorMessage)")
                updateDebugLabel(emojicode: selectedText, decodedUUID: "❌ \(errorMessage)", error: true)
            }
        }
    }

    private func updateDebugLabel(emojicode: String, decodedUUID: String, error: Bool) {
        DispatchQueue.main.async {
            let truncatedEmoji = emojicode.count > 20 ? String(emojicode.prefix(20)) + "..." : emojicode
            self.debugLabel.text = "Emoji: \(truncatedEmoji)\nUUID: \(decodedUUID)"
            self.debugLabel.textColor = error ? UIColor.systemRed : UIColor.systemGray2
        }
    }

    private func decodeEmojiToHex(_ emojiString: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Debug the input
            print("🔍 Swift: Attempting to decode emoji string: '\(emojiString)'")
            print("🔍 Swift: String length: \(emojiString.count)")
            print("🔍 Swift: String characters: \(Array(emojiString))")

            // First check if the products WebView is ready by testing a simple script
            print("🔍 Swift: Testing products WebView readiness...")
            productsWebView.evaluateJavaScript("typeof window.Emojicoding") { readyResult, readyError in
                if let readyError = readyError {
                    print("❌ Swift: WebView not ready - error: \(readyError)")
                    continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "WebView not ready: \(readyError.localizedDescription)"
                    ]))
                    return
                }

                print("🔍 Swift: WebView readiness check result: \(String(describing: readyResult))")

                if readyResult as? String != "object" {
                    print("❌ Swift: Emojicoding not loaded - result: \(String(describing: readyResult))")
                    continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Emojicoding not loaded in WebView"
                    ]))
                    return
                }

                print("✅ Swift: WebView is ready, proceeding with decode...")

                // First test with a simple JavaScript call to verify bridge works
                print("🔍 Swift: Testing simple JavaScript call first...")
                self.productsWebView.evaluateJavaScript("42 + 8") { testResult, testError in
                    if let testError = testError {
                        print("❌ Swift: Simple JavaScript test failed: \(testError)")
                        continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 0, userInfo: [
                            NSLocalizedDescriptionKey: "JavaScript bridge broken: \(testError.localizedDescription)"
                        ]))
                        return
                    }

                    print("✅ Swift: Simple JavaScript test result: \(String(describing: testResult))")

                    // Test our simple test function first
                    print("🔍 Swift: Testing testFunction...")
                    self.productsWebView.evaluateJavaScript("testFunction()") { testFuncResult, testFuncError in
                        if let testFuncError = testFuncError {
                            print("❌ Swift: testFunction failed: \(testFuncError)")
                            continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 0, userInfo: [
                                NSLocalizedDescriptionKey: "testFunction failed: \(testFuncError.localizedDescription)"
                            ]))
                            return
                        }

                        print("✅ Swift: testFunction result: \(String(describing: testFuncResult))")

                        // Now try the emoji decode
                        // Escape the emoji string for JavaScript
                        let escapedEmoji = emojiString.replacingOccurrences(of: "\\", with: "\\\\")
                                                     .replacingOccurrences(of: "'", with: "\\'")

                        let script = "bridgeDecodeEmojiToHex('\(escapedEmoji)')"
                        print("🔍 Swift: Executing JavaScript: \(script)")

                        // Add timeout mechanism with better tracking
                        var timeoutCalled = false
                        var jsCallbackCalled = false

                        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
                            print("❌ Swift: JavaScript evaluation timed out after 5 seconds")
                            if !jsCallbackCalled {
                                timeoutCalled = true
                                continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 99, userInfo: [
                                    NSLocalizedDescriptionKey: "JavaScript evaluation timed out after 5 seconds"
                                ]))
                            }
                        }

                        print("🔍 Swift: About to call evaluateJavaScript...")
                        self.productsWebView.evaluateJavaScript(script) { result, error in
                            print("🔍 Swift: JavaScript callback triggered!")
                            jsCallbackCalled = true
                            timeoutTimer.invalidate() // Cancel timeout

                        if timeoutCalled {
                            print("⚠️ Swift: Timeout already fired, ignoring JavaScript callback")
                            return
                        }

                        print("🔍 Swift: JavaScript completed - result received")
                        if let error = error {
                            print("❌ JavaScript evaluation error: \(error)")
                            continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 1, userInfo: [
                                NSLocalizedDescriptionKey: "JavaScript evaluation failed: \(error.localizedDescription)"
                            ]))
                            return
                        }

                        print("🔍 Swift: JavaScript result: \(String(describing: result))")
                        print("🔍 Swift: Result type: \(type(of: result))")

                        guard let resultDict = result as? [String: Any] else {
                            print("❌ Invalid result format from JavaScript - expected dictionary, got: \(String(describing: result))")
                            continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 2, userInfo: [
                                NSLocalizedDescriptionKey: "Invalid result format from JavaScript bridge - got \(type(of: result))"
                            ]))
                            return
                        }

                        print("🔍 Swift: Result dictionary: \(resultDict)")

                        if let success = resultDict["success"] as? Bool, success,
                           let hex = resultDict["hex"] as? String {
                            print("✅ Successfully decoded emoji to hex: \(hex)")
                            if let detectedMagic = resultDict["detectedMagic"] as? String {
                                print("✨ Detected magic: \(detectedMagic)")
                            }
                            continuation.resume(returning: hex)
                        } else if let errorMessage = resultDict["error"] as? String {
                            print("❌ JavaScript decoding error: \(errorMessage)")
                            continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 3, userInfo: [
                                NSLocalizedDescriptionKey: "Emoji decoding failed: \(errorMessage)"
                            ]))
                        } else {
                            print("❌ Unknown error in JavaScript result - success: \(resultDict["success"] as Any), hex: \(resultDict["hex"] as Any), error: \(resultDict["error"] as Any)")
                            continuation.resume(throwing: NSError(domain: "EmojicodingError", code: 4, userInfo: [
                                NSLocalizedDescriptionKey: "Unknown error in emoji decoding - check console for details"
                            ]))
                        }
                    }
                }
            }
        }
    }
}

    private func formatHexAsUUID(_ hex: String) -> String {
        print("🔍 formatHexAsUUID input: '\(hex)' (length: \(hex.count))")

        let cleanHex = hex.lowercased()

        // With base64 encoding, we should get exactly 32 characters
        guard cleanHex.count == 32 else {
            print("⚠️ Unexpected hex length: \(cleanHex.count), expected 32")
            print("⚠️ Returning as-is: '\(cleanHex)'")
            return cleanHex
        }

        // Format as UUID with dashes
        let uuid = "\(cleanHex.prefix(8))-\(cleanHex.dropFirst(8).prefix(4))-\(cleanHex.dropFirst(12).prefix(4))-\(cleanHex.dropFirst(16).prefix(4))-\(cleanHex.dropFirst(20))"
        print("🔍 Final formatted UUID: '\(uuid)'")
        return uuid
    }

    private func fetchProductByUUID(_ uuid: String) {
        print("🔍 Fetching product for UUID: \(uuid)")

        Task {
            do {
                let product = try await sanoraService.fetchProductByUUID(uuid)
                print("✅ Found product: \(product.title)")

                // Display single product using template system
                DispatchQueue.main.async {
                    self.displaySingleProduct(product)
                }

            } catch {
                let errorMessage = "Product fetch failed: \(error.localizedDescription)"
                print("❌ \(errorMessage)")

                DispatchQueue.main.async {
                    self.updateDebugLabel(emojicode: self.debugLabel.text?.components(separatedBy: "\n").first?.replacingOccurrences(of: "Emoji: ", with: "") ?? "",
                                        decodedUUID: "❌ \(errorMessage)",
                                        error: true)
                }
            }
        }
    }

    private func displaySingleProduct(_ product: SanoraService.Product) {
        print("📦 Displaying single product: \(product.title)")

        // Show products view with single product
        currentView = .products
        productsWebView.isHidden = false
        paymentWebView.isHidden = true
        updateToggleButtonTitle()

        // Generate HTML for single product using existing template system
        do {
            let productsHTML = try HTMLTemplateService.generateProductsHTML(products: [product])

            productsWebView.loadHTMLString(productsHTML, baseURL: nil)
            print("✅ Single product displayed successfully")

        } catch {
            print("❌ Failed to generate single product HTML: \(error)")

            let errorHTML = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body{padding: 20px; background: #f0f0f0; font-family: -apple-system, BlinkMacSystemFont, sans-serif; text-align: center;}</style>
            </head>
            <body>
                <h1>❌ Product Display Error</h1>
                <p>\(error.localizedDescription)</p>
            </body>
            </html>
            """

            productsWebView.loadHTMLString(errorHTML, baseURL: nil)
        }
    }

    private func handleAddPayment() {
        print("Add payment method requested")

        // Here you would navigate to add payment flow
        // For now, just provide feedback
        let proxy = self.textDocumentProxy
        proxy.insertText("➕ Add payment requested")

        // Update payment WebView status
        let script = "updateStatus('Add payment functionality would open here');"
        paymentWebView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error updating WebView: \(error)")
            }
        }
    }

    private func handleCloseKeyboard() {
        print("Close keyboard requested")

        // Hide all WebViews
        hideAllViews()

        // Optionally dismiss the keyboard entirely
        // self.dismissKeyboard()
    }

    // MARK: - WebView Communication Helper
    func sendDataToWebView(_ data: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("Failed to serialize data for WebView")
            return
        }

        let script = "updatePaymentMethods(\(jsonString));"
        paymentWebView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error sending data to WebView: \(error)")
            } else {
                print("Successfully sent data to WebView")
            }
        }
    }
}

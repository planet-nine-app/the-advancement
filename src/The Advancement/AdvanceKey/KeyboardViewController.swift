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
        setupToggleButton()
        addStatusLabel()

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

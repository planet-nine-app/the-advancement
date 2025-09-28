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
    private let nexusURL = "http://127.0.0.1:3333"

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
        • Nexus server is running on localhost:3333
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

    private func storePaymentMethodForKeyboard(_ paymentMethod: [String: Any]) {
        // Store payment method data in shared UserDefaults for keyboard extension access
        let userDefaults = UserDefaults(suiteName: "group.com.planetnine.the-advancement")

        // Store the payment method with a timestamp
        var storedMethods = userDefaults?.array(forKey: "stored_payment_methods") as? [[String: Any]] ?? []

        var paymentMethodWithTimestamp = paymentMethod
        paymentMethodWithTimestamp["saved_at"] = Date().timeIntervalSince1970

        storedMethods.append(paymentMethodWithTimestamp)

        userDefaults?.set(storedMethods, forKey: "stored_payment_methods")
        userDefaults?.synchronize()

        NSLog("ADVANCEAPP: 💾 Payment method stored for keyboard extension access")
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
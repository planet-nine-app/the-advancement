//
//  ViewController.swift
//  Shared (App)
//
//  Created by Zach Babb on 8/23/25.
//

import WebKit

#if os(iOS)
import UIKit
typealias PlatformViewController = UIViewController
#elseif os(macOS)
import Cocoa
import SafariServices
typealias PlatformViewController = NSViewController
#endif

let extensionBundleIdentifier = "com.planetnine.the-advancement.The-Advancement.Extension"

class ViewController: PlatformViewController, WKNavigationDelegate, WKScriptMessageHandler {

    @IBOutlet var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.navigationDelegate = self

#if os(iOS)
        self.webView.scrollView.isScrollEnabled = false

        // Add floating navigation buttons since there's no navigation controller
        addFloatingNavigationButtons()
#endif

        self.webView.configuration.userContentController.add(self, name: "controller")

        // Test shared UserDefaults access on startup
        testSharedUserDefaults()

        self.webView.loadFileURL(Bundle.main.url(forResource: "Main", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    }

#if os(iOS)
    private func addFloatingNavigationButtons() {
        // Create a stack view to hold all navigation buttons
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        // Create the navigation buttons
        let cookbookButton = createNavigationButton(title: "🍪 Cookbook", action: #selector(showCookbook))
        let instantiationButton = createNavigationButton(title: "⚡ Instantiation", action: #selector(showInstantiation))
        let carrierBagButton = createNavigationButton(title: "🎒 Carrier Bag", action: #selector(showCarrierBag))
        let paymentButton = createNavigationButton(title: "💳 Payment", action: #selector(showPaymentMethods))
        let nexusButton = createNavigationButton(title: "🌐 Nexus", action: #selector(showNexus))
        let nfcButton = createNavigationButton(title: "📱 NFC Keys", action: #selector(showNFC))

        stackView.addArrangedSubview(cookbookButton)
        stackView.addArrangedSubview(instantiationButton)
        stackView.addArrangedSubview(carrierBagButton)
        stackView.addArrangedSubview(paymentButton)
        stackView.addArrangedSubview(nexusButton)
        stackView.addArrangedSubview(nfcButton)

        // Position in top-right corner
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalToConstant: 150)
        ])

        NSLog("ADVANCEAPP: 🧭 Added floating navigation buttons")
    }

    private func createNavigationButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 22
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
#endif

#if os(iOS)
    @objc private func showCookbook() {
        NSLog("ADVANCEAPP: 📚 Showing native cookbook")

        let cookbookVC = CookbookViewController()
        let navController = UINavigationController(rootViewController: cookbookVC)
        present(navController, animated: true)
    }

    @objc private func showInstantiation() {
        NSLog("ADVANCEAPP: ⚡ Showing instantiation (Fount user info)")

        let instantiationVC = InstantiationViewController()
        let navController = UINavigationController(rootViewController: instantiationVC)
        present(navController, animated: true)
    }

    @objc private func showCarrierBag() {
        NSLog("ADVANCEAPP: 🎒 Showing carrier bag contents")

        let carrierBagVC = CarrierBagViewController()
        let navController = UINavigationController(rootViewController: carrierBagVC)
        present(navController, animated: true)
    }

    @objc private func showPaymentMethods() {
        NSLog("ADVANCEAPP: 💳 Showing payment methods")

        let paymentVC = PaymentMethodViewController()
        let navController = UINavigationController(rootViewController: paymentVC)
        present(navController, animated: true)
    }

    @objc private func showNexus() {
        NSLog("ADVANCEAPP: 🌐 Showing Nexus portal")

        let nexusVC = NexusViewController()
        let navController = UINavigationController(rootViewController: nexusVC)
        present(navController, animated: true)
    }

    @objc private func showNFC() {
        NSLog("ADVANCEAPP: 📱 Showing NFC Keys")

        let nfcVC = NFCViewController()
        let navController = UINavigationController(rootViewController: nfcVC)
        present(navController, animated: true)
    }
#endif

    private func testSharedUserDefaults() {
        NSLog("ADVANCEAPP: 📚 Testing shared UserDefaults access using SharedUserDefaults...")

        // Test shared access
        let testResult = SharedUserDefaults.testAccess()
        NSLog("ADVANCEAPP: 📚 Shared access test: %@", testResult ? "✅ PASS" : "❌ FAIL")

        // Debug: Print current state
        SharedUserDefaults.debugPrint(prefix: "ADVANCEAPP")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
#if os(iOS)
        webView.evaluateJavaScript("show('ios')")
#elseif os(macOS)
        webView.evaluateJavaScript("show('mac')")

        SFSafariExtensionManager.getStateOfSafariExtension(withIdentifier: extensionBundleIdentifier) { (state, error) in
            guard let state = state, error == nil else {
                // Insert code to inform the user that something went wrong.
                return
            }

            DispatchQueue.main.async {
                if #available(macOS 13, *) {
                    webView.evaluateJavaScript("show('mac', \(state.isEnabled), true)")
                } else {
                    webView.evaluateJavaScript("show('mac', \(state.isEnabled), false)")
                }
            }
        }
#endif
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "controller" {
#if os(macOS)
            if (message.body as! String == "open-preferences") {
                SFSafariApplication.showPreferencesForExtension(withIdentifier: extensionBundleIdentifier) { error in
                    guard error == nil else {
                        // Insert code to inform the user that something went wrong.
                        return
                    }

                    DispatchQueue.main.async {
                        NSApp.terminate(self)
                    }
                }
            }
#endif
        }
    }

}

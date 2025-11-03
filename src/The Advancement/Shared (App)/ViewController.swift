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

#if os(iOS)
    // Status indicator views
    private let statusContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let statusCircle: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 15
        view.clipsToBounds = true
        return view
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()
#endif

    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.navigationDelegate = self

#if os(iOS)
        self.webView.scrollView.isScrollEnabled = false

        // Add floating navigation buttons since there's no navigation controller
        addFloatingNavigationButtons()

        // Add status indicator
        addStatusIndicator()
#endif

        self.webView.configuration.userContentController.add(self, name: "controller")

        // Test shared UserDefaults access on startup
        testSharedUserDefaults()

        self.webView.loadFileURL(Bundle.main.url(forResource: "Main", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    }

#if os(iOS)
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Update status indicator when view appears (in case cards were added)
        updateStatusIndicator()
    }
#endif

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

        // Prominent card display button
        let myCardButton = createNavigationButton(title: "💳 My Card", action: #selector(showMyCard), backgroundColor: UIColor(red: 0.91, green: 0.12, blue: 0.39, alpha: 1.0))

        // Payment management buttons
        let manageCardsButton = createNavigationButton(title: "⚙️ Manage Cards", action: #selector(showPaymentMethods), backgroundColor: UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1.0))

        let nexusButton = createNavigationButton(title: "🌐 Nexus", action: #selector(showNexus))
        let nfcButton = createNavigationButton(title: "📱 NFC Keys", action: #selector(showNFC))

        stackView.addArrangedSubview(cookbookButton)
        stackView.addArrangedSubview(instantiationButton)
        stackView.addArrangedSubview(carrierBagButton)
        stackView.addArrangedSubview(myCardButton)
        stackView.addArrangedSubview(manageCardsButton)
        stackView.addArrangedSubview(nexusButton)
        stackView.addArrangedSubview(nfcButton)

        // Position in top-right corner
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalToConstant: 180)
        ])

        NSLog("ADVANCEAPP: 🧭 Added floating navigation buttons")
    }

    private func createNavigationButton(title: String, action: Selector, backgroundColor: UIColor? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = backgroundColor ?? UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 22
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
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

    @objc private func showMyCard() {
        NSLog("ADVANCEAPP: 💳 Showing my card display")

        let cardDisplayVC = CardDisplayViewController()
        let navController = UINavigationController(rootViewController: cardDisplayVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }

    @objc private func showPaymentMethods() {
        NSLog("ADVANCEAPP: ⚙️ Showing payment methods management")

        let paymentVC = PaymentMethodViewController()
        let navController = UINavigationController(rootViewController: paymentVC)
        navController.modalPresentationStyle = .fullScreen
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

    private func addStatusIndicator() {
        // Add container to view
        view.addSubview(statusContainerView)
        statusContainerView.addSubview(statusCircle)
        statusContainerView.addSubview(statusLabel)

        // Setup constraints for container (top-left corner)
        NSLayoutConstraint.activate([
            statusContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            statusContainerView.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Setup constraints for circle
        NSLayoutConstraint.activate([
            statusCircle.leadingAnchor.constraint(equalTo: statusContainerView.leadingAnchor),
            statusCircle.centerYAnchor.constraint(equalTo: statusContainerView.centerYAnchor),
            statusCircle.widthAnchor.constraint(equalToConstant: 30),
            statusCircle.heightAnchor.constraint(equalToConstant: 30)
        ])

        // Setup constraints for label
        NSLayoutConstraint.activate([
            statusLabel.leadingAnchor.constraint(equalTo: statusCircle.trailingAnchor, constant: 8),
            statusLabel.centerYAnchor.constraint(equalTo: statusContainerView.centerYAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: statusContainerView.trailingAnchor)
        ])

        // Initial state
        updateStatusIndicator()

        NSLog("ADVANCEAPP: 🎨 Status indicator added to top-left")
    }

    private func updateStatusIndicator() {
        // Check if user has any saved cards
        let hasCards = checkIfUserHasCards()

        if hasCards {
            // Active state: green and purple gradient circle with "Post away"
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [
                UIColor(red: 0.16, green: 0.73, blue: 0.51, alpha: 1.0).cgColor, // #10b981 - Green
                UIColor(red: 0.61, green: 0.15, blue: 0.69, alpha: 1.0).cgColor  // #9c27b0 - Purple
            ]
            gradientLayer.startPoint = CGPoint(x: 0, y: 0)
            gradientLayer.endPoint = CGPoint(x: 1, y: 1)
            gradientLayer.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            gradientLayer.cornerRadius = 15

            // Remove existing gradient layers
            statusCircle.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            statusCircle.layer.insertSublayer(gradientLayer, at: 0)

            statusLabel.text = "Post away"
            statusLabel.textColor = UIColor(red: 0.16, green: 0.73, blue: 0.51, alpha: 1.0)

            NSLog("ADVANCEAPP: ✅ Status indicator updated to 'Post away' (user has cards)")
        } else {
            // Inactive state: gray circle with "Set up payment"
            statusCircle.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
            statusCircle.backgroundColor = UIColor.systemGray4

            statusLabel.text = "Set up payment"
            statusLabel.textColor = .systemGray

            NSLog("ADVANCEAPP: ⚠️ Status indicator updated to 'Set up payment' (no cards)")
        }
    }

    private func checkIfUserHasCards() -> Bool {
        // Check if user has any saved cards in UserDefaults
        if let cardsData = UserDefaults.standard.data(forKey: "stripe_saved_cards"),
           let cards = try? JSONSerialization.jsonObject(with: cardsData) as? [[String: Any]],
           !cards.isEmpty {
            return true
        }
        return false
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

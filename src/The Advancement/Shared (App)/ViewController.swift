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

        // Add floating cookbook button since there's no navigation controller
        addFloatingCookbookButton()
#endif

        self.webView.configuration.userContentController.add(self, name: "controller")

        // Test shared UserDefaults access on startup
        testSharedUserDefaults()

        self.webView.loadFileURL(Bundle.main.url(forResource: "Main", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    }

#if os(iOS)
    private func addFloatingCookbookButton() {
        let button = UIButton(type: .system)
        button.setTitle("🍪 Cookbook", for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)

        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)

        // Position in top-right corner
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            button.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 130)
        ])

        button.addTarget(self, action: #selector(showCookbook), for: .touchUpInside)

        NSLog("ADVANCEAPP: 📚 Added floating cookbook button")
    }
#endif

#if os(iOS)
    @objc private func showCookbook() {
        NSLog("ADVANCEAPP: 📚 Showing native cookbook")

        let cookbookVC = CookbookViewController()
        let navController = UINavigationController(rootViewController: cookbookVC)
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

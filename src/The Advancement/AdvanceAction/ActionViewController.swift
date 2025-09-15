//
//  ActionViewController.swift
//  AdvanceAction - Planet Nine Action Extension
//
//  Created by Zach Babb on 9/14/25.
//

import Cocoa
import WebKit

class ActionViewController: NSViewController {

    @IBOutlet var containerView: NSView!
    @IBOutlet var loadingLabel: NSTextField!
    @IBOutlet var errorLabel: NSTextField!

    private var webView: WKWebView!
    private let sessionless = Sessionless()

    override func viewDidLoad() {
        super.viewDidLoad()

        print("🎴 AdvanceAction: ViewDidLoad called")
        setupUI()
        setupWebView()

        // Show immediate feedback
        loadingLabel?.stringValue = "🎴 Action Extension is working!"

        processSelectedText()
    }

    private func setupUI() {
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor

        // Set window size
        preferredContentSize = NSSize(width: 500, height: 400)

        loadingLabel?.stringValue = "🎴 Loading Planet Nine card..."
        errorLabel?.stringValue = ""
        errorLabel?.isHidden = true
    }

    private func setupWebView() {
        guard let containerView = containerView else {
            print("❌ AdvanceAction: No container view found")
            return
        }

        webView = WKWebView(frame: containerView.bounds)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        containerView.addSubview(webView)
    }

    private func processSelectedText() {
        print("🎴 AdvanceAction: processSelectedText called")

        guard let inputItem = extensionContext?.inputItems.first as? NSExtensionItem else {
            showError("No input item found")
            return
        }

        print("🎴 AdvanceAction: Found input item: \(inputItem)")

        guard let itemProvider = inputItem.attachments?.first else {
            showError("No attachment found")
            return
        }

        print("🎴 AdvanceAction: Found item provider")

        if itemProvider.hasItemConformingToTypeIdentifier("public.plain-text") {
            print("🎴 AdvanceAction: Item provider has plain text")
            itemProvider.loadItem(forTypeIdentifier: "public.plain-text") { [weak self] (item, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        print("❌ AdvanceAction: Error loading text: \(error)")
                        self?.showError("Error loading text: \(error.localizedDescription)")
                        return
                    }

                    guard let selectedText = item as? String else {
                        print("❌ AdvanceAction: Could not cast item to String: \(String(describing: item))")
                        self?.showError("Could not read selected text")
                        return
                    }

                    print("🎴 AdvanceAction: Selected text: \(selectedText)")
                    self?.loadingLabel?.stringValue = "🎴 Found text: \(selectedText.prefix(50))..."
                    self?.handleSelectedText(selectedText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        } else {
            print("❌ AdvanceAction: Selected content is not text")
            showError("Selected content is not text")
        }
    }

    private func handleSelectedText(_ text: String) {
        // Check if text looks like a bdoPubKey (66 characters, hex)
        if isBDOPubKey(text) {
            print("🎴 AdvanceAction: Detected bdoPubKey: \(text)")
            fetchBDOCard(pubKey: text)
        } else {
            // Try to extract pubKey from text (maybe it's embedded)
            if let extractedPubKey = extractPubKeyFromText(text) {
                print("🎴 AdvanceAction: Extracted pubKey from text: \(extractedPubKey)")
                fetchBDOCard(pubKey: extractedPubKey)
            } else {
                showError("Selected text doesn't contain a valid Planet Nine pubKey")
            }
        }
    }

    private func isBDOPubKey(_ text: String) -> Bool {
        // Check if it's a 66-character hex string starting with 02 or 03 (compressed pubkey)
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanText.count == 66 else { return false }
        guard cleanText.hasPrefix("02") || cleanText.hasPrefix("03") else { return false }

        let hexCharacters = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return cleanText.unicodeScalars.allSatisfy { hexCharacters.contains($0) }
    }

    private func extractPubKeyFromText(_ text: String) -> String? {
        // Look for pubKey patterns in text
        let patterns = [
            #"pubKey[:\s]*([023][0-9a-fA-F]{64})"#,
            #"pubkey[:\s]*([023][0-9a-fA-F]{64})"#,
            #"publicKey[:\s]*([023][0-9a-fA-F]{64})"#,
            #"([023][0-9a-fA-F]{64})"# // Just find any 66-char hex starting with 02/03
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchRange = match.range(at: 1)
                    if matchRange.location != NSNotFound {
                        let pubKey = String(text[Range(matchRange, in: text)!])
                        if isBDOPubKey(pubKey) {
                            return pubKey
                        }
                    }
                }
            }
        }

        return nil
    }

    private func fetchBDOCard(pubKey: String) {
        print("🎴 AdvanceAction: Fetching BDO card for pubKey: \(pubKey)")

        // Use the same hardcoded working URL as the keyboard
        let bdoURL = "http://127.0.0.1:5114/user/3129c121-e443-4581-82c4-516fb0a2cc64/bdo?timestamp=1757775881380&hash=foo&signature=d2802f3e843b78e45b0940bc159094251dfe2c844300370e8c1019767f001eb720b46dc005552f9141c8e293584688064cca332dabc018db0247bdf7935838b0&pubKey=\(pubKey)"

        guard let url = URL(string: bdoURL) else {
            showError("Invalid BDO URL")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showError("BDO request failed: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    self?.showError("No data received from BDO")
                    return
                }

                self?.parseBDOResponse(data, pubKey: pubKey)
            }
        }.resume()
    }

    private func parseBDOResponse(_ data: Data, pubKey: String) {
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                showError("Invalid JSON response from BDO")
                return
            }

            // Parse the same way as keyboard extension
            if let bdoObject = jsonObject["bdo"] as? [String: Any],
               let svgContent = bdoObject["svgContent"] as? String {

                print("✅ AdvanceAction: Successfully parsed BDO card")
                displayCard(svgContent: svgContent, pubKey: pubKey)

            } else {
                showError("Invalid card data from BDO")
            }
        } catch {
            showError("Error parsing BDO response: \(error.localizedDescription)")
        }
    }

    private func displayCard(svgContent: String, pubKey: String) {
        loadingLabel?.isHidden = true

        let html = generateCardHTML(svgContent: svgContent, pubKey: pubKey)
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func generateCardHTML(svgContent: String, pubKey: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    margin: 0;
                    padding: 20px;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    min-height: calc(100vh - 40px);
                    display: flex;
                    flex-direction: column;
                }

                .card-container {
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 16px;
                    padding: 20px;
                    backdrop-filter: blur(10px);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    flex: 1;
                    display: flex;
                    flex-direction: column;
                }

                .card-header {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    margin-bottom: 16px;
                    padding-bottom: 16px;
                    border-bottom: 1px solid rgba(255, 255, 255, 0.2);
                }

                .card-title {
                    font-size: 20px;
                    font-weight: bold;
                    margin: 0;
                }

                .action-badge {
                    background: rgba(40, 167, 69, 0.3);
                    border: 1px solid rgba(40, 167, 69, 0.5);
                    border-radius: 20px;
                    padding: 6px 12px;
                    font-size: 12px;
                    font-weight: 500;
                }

                .card-content {
                    flex: 1;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    background: rgba(255, 255, 255, 0.05);
                    border-radius: 12px;
                    margin: 16px 0;
                    min-height: 200px;
                    overflow: hidden;
                }

                .card-content svg {
                    max-width: 100%;
                    max-height: 100%;
                }

                .pubkey-display {
                    background: rgba(0, 0, 0, 0.3);
                    border-radius: 6px;
                    padding: 8px;
                    font-family: 'SF Mono', monospace;
                    font-size: 10px;
                    word-break: break-all;
                    margin-top: 8px;
                }

                .action-info {
                    text-align: center;
                    margin-top: 16px;
                    font-size: 14px;
                    opacity: 0.9;
                }
            </style>
        </head>
        <body>
            <div class="card-container">
                <div class="card-header">
                    <h1 class="card-title">🎴 Planet Nine Card</h1>
                    <div class="action-badge">
                        ⚡ Action Extension
                    </div>
                </div>

                <div class="card-content">
                    \(svgContent)
                </div>

                <div class="pubkey-display">
                    <strong>PubKey:</strong> \(pubKey)
                </div>

                <div class="action-info">
                    Loaded via macOS Action Extension from selected text
                </div>
            </div>
        </body>
        </html>
        """
    }

    private func showError(_ message: String) {
        print("❌ AdvanceAction: \(message)")
        loadingLabel?.isHidden = true
        errorLabel?.stringValue = "❌ \(message)"
        errorLabel?.isHidden = false
    }

    @IBAction func done(_ sender: AnyObject?) {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    // MARK: - Services Message Handler
    @objc func showPlanetNineCard(_ pasteboard: NSPasteboard, userData: String, error: UnsafeMutablePointer<NSString>) {
        print("🎴 AdvanceAction: Service method called!")

        guard let text = pasteboard.string(forType: .string) else {
            print("❌ AdvanceAction: No text found in pasteboard")
            return
        }

        print("🎴 AdvanceAction: Service received text: \(text)")
        handleSelectedText(text.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
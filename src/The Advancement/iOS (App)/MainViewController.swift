//
//  MainViewController.swift
//  The Advancement
//
//  Main app screen with SVG-based WebView interface
//

import UIKit
import WebKit

class MainViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {

    private var webView: WKWebView!
    private var postedBDOs: [[String: Any]] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        NSLog("MAINVC: 🎬 viewDidLoad called")

        // Make view extend to full screen
        view.backgroundColor = .black

        setupWebView()
        loadMainPage()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        NSLog("MAINVC: 👀 viewWillAppear called")

        // Don't update button here - wait for WebView to finish loading
        // updatePostButtonAppearance() will be called from webView(_:didFinish:)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        NSLog("MAINVC: 🌐 WebView finished loading")

        // Fetch cards from backend, then update button appearance
        Task {
            await fetchCardsFromBackend()
            await MainActor.run {
                updatePostButtonAppearance()
            }
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    private func setupWebView() {
        // Configure WKWebView
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "mainApp")
        configuration.userContentController.add(self, name: "console")

        webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.scrollView.isScrollEnabled = true
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(webView)
    }

    private func loadMainPage() {
        let html = getMainHTML()
        webView.loadHTMLString(html, baseURL: nil)
    }

    private func getMainHTML() -> String {
        return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no">
    <style>
        * { margin: 0; padding: 0; -webkit-user-select: none; -webkit-user-drag: none; }
        html, body { width: 100%; min-height: 100%; overflow-x: hidden; background-color: #000000; }
        #mainSVG { width: 100vw; min-height: 100vh; display: block; }
        .button-group { cursor: pointer; }
        .button-group:active rect { fill: rgba(16, 185, 129, 0.3); }
        input { -webkit-user-select: text; }
    </style>
</head>
<body>
    <svg id="mainSVG" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 140" preserveAspectRatio="xMidYMin meet">
        <defs>
            <filter id="greenGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.8" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <filter id="purpleGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.5" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <filter id="pinkGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.6" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <filter id="yellowGlow" x="-50%" y="-50%" width="200%" height="200%">
                <feGaussianBlur stdDeviation="0.4" result="coloredBlur"/>
                <feMerge><feMergeNode in="coloredBlur"/><feMergeNode in="SourceGraphic"/></feMerge>
            </filter>
            <radialGradient id="bgGradient" cx="50%" cy="50%" r="70%">
                <stop offset="0%" style="stop-color:#1a0033; stop-opacity:1" />
                <stop offset="100%" style="stop-color:#000000; stop-opacity:1" />
            </radialGradient>
        </defs>

        <!-- Background -->
        <rect width="100" height="140" fill="url(#bgGradient)"/>

        <!-- Title -->
        <text x="50" y="22" text-anchor="middle" style="font-family: -apple-system; font-size: 5px; font-weight: 700; letter-spacing: 0.5px;" fill="#10b981" filter="url(#greenGlow)">
            THE ADVANCEMENT
        </text>

        <!-- Post Button (top left) -->
        <g id="postPaymentButton" class="button-group">
            <ellipse cx="15" cy="15" rx="12" ry="9" fill="rgba(233, 30, 99, 0.2)" stroke="#e91e63" stroke-width="0.3" filter="url(#pinkGlow)">
                <animate attributeName="opacity" values="0.6;1;0.6" dur="2.5s" repeatCount="indefinite"/>
            </ellipse>
            <text x="15" y="13" text-anchor="middle" style="font-family: -apple-system; font-size: 1.8px; font-weight: 700; letter-spacing: 0.1px;" fill="#e91e63" filter="url(#pinkGlow)">
                Push me
            </text>
            <text x="15" y="17" text-anchor="middle" style="font-family: -apple-system; font-size: 1.8px; font-weight: 700; letter-spacing: 0.1px;" fill="#e91e63" filter="url(#pinkGlow)">
                to post
            </text>
        </g>

        <!-- Carrier Bag Button (top right) -->
        <g id="bagButton" class="button-group">
            <ellipse cx="85" cy="15" rx="12" ry="9" fill="rgba(233, 30, 99, 0.2)" stroke="#e91e63" stroke-width="0.3" filter="url(#pinkGlow)">
                <animate attributeName="opacity" values="0.6;1;0.6" dur="2.5s" repeatCount="indefinite"/>
            </ellipse>
            <text x="85" y="17" text-anchor="middle" style="font-family: -apple-system; font-size: 3.5px; font-weight: 700; letter-spacing: 0.2px;" fill="#e91e63" filter="url(#pinkGlow)">
                BAG
            </text>
        </g>

        <!-- Posted BDOs Display Area (will be populated dynamically) -->
        <g id="bdoDisplayArea" transform="translate(0, 32)">
            <!-- BDOs will be inserted here -->
        </g>

        <!-- Input Area (at bottom) -->
        <g id="inputArea" transform="translate(0, 102)">
            <!-- POST Button -->
            <g id="postButton" class="button-group">
                <rect x="30" y="15" width="40" height="8" rx="1" fill="rgba(16, 185, 129, 0.15)" stroke="#10b981" stroke-width="0.25" filter="url(#greenGlow)" opacity="0.9">
                    <animate attributeName="opacity" values="0.7;1;0.7" dur="2s" repeatCount="indefinite"/>
                </rect>
                <text x="50" y="20" text-anchor="middle" style="font-family: -apple-system; font-size: 3px; font-weight: 600; letter-spacing: 0.3px;" fill="#10b981" filter="url(#greenGlow)">
                    POST
                </text>
            </g>

            <!-- Keyboard Installation Notice (hidden by default, moved down 20 units) -->
            <g id="keyboardNotice" class="button-group" opacity="0">
                <rect x="10" y="45" width="80" height="6" rx="1" fill="rgba(251, 191, 36, 0.1)" stroke="#fbbf24" stroke-width="0.2" opacity="0.8"/>
                <text x="50" y="49" text-anchor="middle" style="font-family: -apple-system; font-size: 2px; font-weight: 500; letter-spacing: 0.1px;" fill="#fbbf24" opacity="0.9">
                    ⌨️ Enable AdvanceKey in Settings
                </text>
            </g>
        </g>
    </svg>

    <!-- HTML input styled to look like the purple SVG rect -->
    <div style="position: absolute; top: calc(102 / 140 * 100vh); left: 10vw; width: 80vw; height: calc(10 / 140 * 100vh); pointer-events: auto;">
        <input type="text" id="textInput" placeholder="Enter text to post..." style="width: 100%; height: 100%; background: rgba(139, 92, 246, 0.15); border: 1px solid #8b5cf6; border-radius: 4px; outline: none; color: #8b5cf6; font-family: -apple-system; font-size: 2.5vh; font-weight: 500; pointer-events: auto; padding: 0 2vw; box-sizing: border-box; filter: drop-shadow(0 0 8px rgba(139, 92, 246, 0.5));" />
    </div>

    <script>
        // Override console.log to send to Swift
        (function() {
            const originalLog = console.log;
            const originalError = console.error;
            const originalWarn = console.warn;

            console.log = function(...args) {
                const message = args.map(arg =>
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                ).join(' ');
                webkit.messageHandlers.console.postMessage({level: 'log', message: message});
                originalLog.apply(console, args);
            };

            console.error = function(...args) {
                const message = args.map(arg =>
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                ).join(' ');
                webkit.messageHandlers.console.postMessage({level: 'error', message: message});
                originalError.apply(console, args);
            };

            console.warn = function(...args) {
                const message = args.map(arg =>
                    typeof arg === 'object' ? JSON.stringify(arg) : String(arg)
                ).join(' ');
                webkit.messageHandlers.console.postMessage({level: 'warn', message: message});
                originalWarn.apply(console, args);
            };
        })();

        console.log('🚀 Main view loaded');

        const textInput = document.getElementById('textInput');

        console.log('✅ Text input element:', textInput);

        // Log input changes
        textInput.addEventListener('input', function() {
            console.log('✏️ Input changed:', textInput.value);
        });

        textInput.addEventListener('focus', function() {
            console.log('🎯 Input focused');
        });

        textInput.addEventListener('blur', function() {
            console.log('👋 Input blurred');
        });

        // POST button click handler
        document.getElementById('postButton').addEventListener('click', function() {
            console.log('🔘 POST button clicked');
            const text = textInput.value.trim();
            if (!text) {
                console.warn('⚠️ No text entered');
                alert('Please enter some text first');
                return;
            }

            console.log('📤 Posting text:', text);

            // Check if user has a card first
            webkit.messageHandlers.mainApp.postMessage({
                action: 'checkCard',
                text: text
            });
        });

        // Post Payment button click handler
        document.getElementById('postPaymentButton').addEventListener('click', function() {
            console.log('💳 Push me to post button clicked');

            // Send to Swift
            webkit.messageHandlers.mainApp.postMessage({
                action: 'openPayment'
            });
        });

        // BAG button click handler
        document.getElementById('bagButton').addEventListener('click', function() {
            console.log('🎒 BAG button clicked');

            // Send to Swift
            webkit.messageHandlers.mainApp.postMessage({
                action: 'openBag'
            });
        });

        // Keyboard Notice click handler
        document.getElementById('keyboardNotice').addEventListener('click', function() {
            console.log('⌨️ Keyboard notice clicked');

            // Send to Swift
            webkit.messageHandlers.mainApp.postMessage({
                action: 'openKeyboardSettings'
            });
        });

        // Check keyboard installation status
        function checkKeyboardInstallation() {
            webkit.messageHandlers.mainApp.postMessage({
                action: 'checkKeyboard'
            });
        }

        // Function to show/hide keyboard notice
        function setKeyboardNoticeVisible(visible) {
            const notice = document.getElementById('keyboardNotice');
            notice.setAttribute('opacity', visible ? '1' : '0');
        }

        // Check keyboard status on load
        checkKeyboardInstallation();

        // Function to show "no dice" animation and arrow
        function showNoDiceAnimation() {
            console.log('🎲 Showing no dice animation');

            // Create "no dice" text element
            const noDice = document.createElementNS('http://www.w3.org/2000/svg', 'text');
            noDice.setAttribute('x', '50');
            noDice.setAttribute('y', '115');
            noDice.setAttribute('text-anchor', 'middle');
            noDice.setAttribute('style', 'font-family: -apple-system; font-size: 4px; font-weight: 700; fill: #f44336; filter: url(#pinkGlow);');
            noDice.textContent = 'no dice';

            document.getElementById('mainSVG').appendChild(noDice);

            // Animate falling with gravity
            let y = 115;
            let velocity = 0;
            const gravity = 0.5;
            const ground = 135;

            const fallInterval = setInterval(() => {
                velocity += gravity;
                y += velocity;

                if (y >= ground) {
                    y = ground;
                    velocity = -velocity * 0.5; // Bounce with energy loss

                    if (Math.abs(velocity) < 0.5) {
                        clearInterval(fallInterval);
                        // Fade out after settling
                        setTimeout(() => {
                            noDice.remove();
                        }, 1500);
                    }
                }

                noDice.setAttribute('y', y);
            }, 20);

            // Create arrow pointing to card button
            const arrow = document.createElementNS('http://www.w3.org/2000/svg', 'g');
            arrow.setAttribute('id', 'arrow-indicator');

            // Arrow path (pointing up-left towards card button)
            const arrowPath = document.createElementNS('http://www.w3.org/2000/svg', 'path');
            arrowPath.setAttribute('d', 'M 50 110 Q 30 90 15 30');
            arrowPath.setAttribute('stroke', '#e91e63');
            arrowPath.setAttribute('stroke-width', '0.5');
            arrowPath.setAttribute('fill', 'none');
            arrowPath.setAttribute('stroke-dasharray', '2,1');
            arrowPath.setAttribute('filter', 'url(#pinkGlow)');

            // Arrowhead
            const arrowHead = document.createElementNS('http://www.w3.org/2000/svg', 'polygon');
            arrowHead.setAttribute('points', '15,30 13,33 17,33');
            arrowHead.setAttribute('fill', '#e91e63');
            arrowHead.setAttribute('filter', 'url(#pinkGlow)');

            arrow.appendChild(arrowPath);
            arrow.appendChild(arrowHead);

            document.getElementById('mainSVG').appendChild(arrow);

            // Animate arrow growing
            let scale = 0;
            const growInterval = setInterval(() => {
                scale += 0.05;
                if (scale >= 1) {
                    scale = 1;
                    clearInterval(growInterval);

                    // Pulse the arrow
                    let opacity = 1;
                    let direction = -0.05;
                    const pulseInterval = setInterval(() => {
                        opacity += direction;
                        if (opacity <= 0.3 || opacity >= 1) {
                            direction = -direction;
                        }
                        arrow.setAttribute('opacity', opacity);
                    }, 50);

                    // Remove arrow after a few seconds
                    setTimeout(() => {
                        clearInterval(pulseInterval);
                        arrow.remove();
                    }, 3000);
                }

                arrow.setAttribute('transform', `scale(${scale})`);
                arrow.setAttribute('transform-origin', '15 30');
            }, 20);
        }

        // Function called from Swift to add posted BDO to display
        function addPostedBDO(bdoData) {
            const displayArea = document.getElementById('bdoDisplayArea');
            const currentBDOs = displayArea.querySelectorAll('g').length;
            const yOffset = currentBDOs * 25;

            // Create SVG for this BDO
            const bdoGroup = document.createElementNS('http://www.w3.org/2000/svg', 'g');
            bdoGroup.setAttribute('transform', `translate(0, ${yOffset})`);

            // BDO Container
            const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
            rect.setAttribute('x', '10');
            rect.setAttribute('y', '0');
            rect.setAttribute('width', '80');
            rect.setAttribute('height', '20');
            rect.setAttribute('rx', '1');
            rect.setAttribute('fill', 'rgba(236, 72, 153, 0.15)');
            rect.setAttribute('stroke', '#ec4899');
            rect.setAttribute('stroke-width', '0.25');
            rect.setAttribute('filter', 'url(#pinkGlow)');
            bdoGroup.appendChild(rect);

            // BDO Text
            const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
            text.setAttribute('x', '50');
            text.setAttribute('y', '8');
            text.setAttribute('text-anchor', 'middle');
            text.setAttribute('style', 'font-family: -apple-system; font-size: 3px; font-weight: 600;');
            text.setAttribute('fill', '#ec4899');
            text.textContent = bdoData.text;
            bdoGroup.appendChild(text);

            displayArea.appendChild(bdoGroup);

            // Add HTML overlay for selectable emojicode
            const emojiOverlay = document.createElement('div');
            const totalYOffset = 32 + yOffset; // Base offset (32 for BDO display area) + BDO offset
            emojiOverlay.style.cssText = `
                position: absolute;
                top: calc(${totalYOffset} / 140 * 100vh + 12vh);
                left: 50%;
                transform: translateX(-50%);
                color: #fbbf24;
                font-family: -apple-system;
                font-size: 4vh;
                font-weight: 400;
                text-align: center;
                user-select: text;
                -webkit-user-select: text;
                pointer-events: auto;
                filter: drop-shadow(0 0 8px rgba(251, 191, 36, 0.6));
                letter-spacing: 0.2em;
            `;
            emojiOverlay.textContent = bdoData.emojicode || '🌟';
            document.body.appendChild(emojiOverlay);

            // Update SVG height to accommodate new BDO
            const newHeight = 140 + (currentBDOs * 10);
            document.getElementById('mainSVG').setAttribute('viewBox', `0 0 100 ${newHeight}`);
        }
    </script>
</body>
</html>
"""
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Handle console logging
        if message.name == "console" {
            if let logMessage = message.body as? String {
                NSLog("🌐 WebView: %@", logMessage)
            } else if let logDict = message.body as? [String: Any] {
                if let level = logDict["level"] as? String, let msg = logDict["message"] as? String {
                    NSLog("🌐 WebView [%@]: %@", level.uppercased(), msg)
                }
            }
            return
        }

        // Handle main app messages
        guard message.name == "mainApp",
              let messageBody = message.body as? [String: Any],
              let action = messageBody["action"] as? String else {
            return
        }

        if action == "checkCard", let text = messageBody["text"] as? String {
            checkCardBeforePosting(text: text)
        } else if action == "post", let text = messageBody["text"] as? String {
            postBDO(text: text)
        } else if action == "openBag" {
            openCarrierBag()
        } else if action == "openPayment" {
            handlePaymentButtonClick()
        } else if action == "checkKeyboard" {
            checkKeyboardInstallation()
        } else if action == "openKeyboardSettings" {
            openKeyboardSettings()
        }
    }

    // MARK: - Card Check

    private func fetchCardsFromBackend() async {
        NSLog("MAINVC: 📡 Fetching cards from Addie backend...")

        guard let homeBase = getHomeBaseURL() else {
            NSLog("MAINVC: ⚠️ No home base URL configured")
            return
        }

        let sessionless = Sessionless()
        guard let keys = sessionless.getKeys() else {
            NSLog("MAINVC: ⚠️ No sessionless keys available")
            return
        }

        // Get user UUID from Addie
        // First we need to get/create the user by pubKey
        guard let userUUID = await getOrCreateAddieUser(pubKey: keys.publicKey) else {
            NSLog("MAINVC: ⚠️ Failed to get user UUID")
            return
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + userUUID
        guard let signature = sessionless.sign(message: message) else {
            NSLog("MAINVC: ⚠️ Failed to sign request")
            return
        }

        let endpoint = "\(homeBase)/saved-payment-methods?uuid=\(userUUID)&timestamp=\(timestamp)&processor=stripe&signature=\(signature)"

        guard let url = URL(string: endpoint) else {
            NSLog("MAINVC: ⚠️ Invalid URL: \(endpoint)")
            return
        }

        NSLog("MAINVC: 📡 Fetching from: \(url.absoluteString)")

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                NSLog("MAINVC: ⚠️ Invalid response type")
                return
            }

            NSLog("MAINVC: 📡 Response status: \(httpResponse.statusCode)")

            if let responseString = String(data: data, encoding: .utf8) {
                NSLog("MAINVC: 📦 Response body: \(responseString)")
            }

            guard httpResponse.statusCode == 200 else {
                NSLog("MAINVC: ⚠️ Failed to fetch cards: HTTP \(httpResponse.statusCode)")
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let paymentMethods = json["paymentMethods"] as? [[String: Any]] {
                NSLog("MAINVC: ✅ Fetched \(paymentMethods.count) payment methods from backend")

                // Save to UserDefaults
                if let cardsData = try? JSONSerialization.data(withJSONObject: paymentMethods) {
                    UserDefaults.standard.set(cardsData, forKey: "stripe_saved_cards")
                    NSLog("MAINVC: 💾 Saved cards to UserDefaults")
                } else {
                    NSLog("MAINVC: ⚠️ Failed to serialize cards")
                }
            } else {
                NSLog("MAINVC: ⚠️ Failed to parse payment methods from response")
            }
        } catch {
            NSLog("MAINVC: ⚠️ Error fetching cards: \(error.localizedDescription)")
        }
    }

    private func getOrCreateAddieUser(pubKey: String) async -> String? {
        // Check if we already have an Addie UUID cached in UserDefaults
        if let cachedUUID = UserDefaults.standard.string(forKey: "addie_user_uuid") {
            NSLog("MAINVC: ✅ Using cached Addie UUID: \(cachedUUID)")
            return cachedUUID
        }

        guard let homeBase = getHomeBaseURL() else {
            return nil
        }

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let message = timestamp + pubKey

        let sessionless = Sessionless()
        guard let signature = sessionless.sign(message: message) else {
            NSLog("MAINVC: ⚠️ Failed to sign user creation request")
            return nil
        }

        let endpoint = "\(homeBase)/user/create"
        guard let url = URL(string: endpoint) else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "pubKey": pubKey,
            "timestamp": timestamp,
            "signature": signature
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                NSLog("MAINVC: ⚠️ Failed to create/get Addie user")
                return nil
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let uuid = json["uuid"] as? String {
                NSLog("MAINVC: ✅ Got Addie user UUID: \(uuid)")

                // Cache the UUID in UserDefaults for future use
                UserDefaults.standard.set(uuid, forKey: "addie_user_uuid")
                NSLog("MAINVC: 💾 Cached Addie UUID in UserDefaults")

                return uuid
            }
        } catch {
            NSLog("MAINVC: ⚠️ Error getting Addie user: \(error.localizedDescription)")
        }

        return nil
    }

    private func getHomeBaseURL() -> String? {
        // Use Configuration to get the Addie base URL
        return Configuration.addieBaseURL
    }

    private func updatePostButtonAppearance() {
        NSLog("MAINVC: 🎨 Updating post button appearance...")

        let hasCards = checkIfUserHasCards()

        if hasCards {
            NSLog("MAINVC: ✅ User has cards - updating button to green")
            // Change button to green gradient
            let jsCode = """
            (function() {
                const button = document.getElementById('postPaymentButton');
                const ellipse = button.querySelector('ellipse');
                const texts = button.querySelectorAll('text');

                // Update ellipse to green
                ellipse.setAttribute('fill', 'rgba(16, 185, 129, 0.2)');
                ellipse.setAttribute('stroke', '#10b981');
                ellipse.setAttribute('filter', 'url(#greenGlow)');

                // Update text to green
                texts.forEach(text => {
                    text.setAttribute('fill', '#10b981');
                    text.setAttribute('filter', 'url(#greenGlow)');
                });

                // Update text content
                texts[0].textContent = 'Post';
                texts[1].textContent = 'away';

                console.log('✅ Updated button to green (user has cards)');
            })();
            """
            webView.evaluateJavaScript(jsCode) { _, error in
                if let error = error {
                    NSLog("MAINVC: ⚠️ Failed to update button color: %@", error.localizedDescription)
                }
            }
        } else {
            NSLog("MAINVC: ⚠️ User has no cards - keeping button red")
            // Button is already red/pink by default, just log
        }
    }

    private func checkCardBeforePosting(text: String) {
        NSLog("💳 Checking if user has saved cards...")

        let hasCards = checkIfUserHasCards()

        if hasCards {
            NSLog("✅ User has cards, proceeding with post")
            postBDO(text: text)
        } else {
            NSLog("❌ No cards found, showing animation")
            showNoDiceAnimation()
        }
    }

    private func checkIfUserHasCards() -> Bool {
        NSLog("🔍 Checking if user has cards...")

        // Check for saved payment methods (credit/debit cards)
        if let cardsData = UserDefaults.standard.data(forKey: "stripe_saved_cards") {
            NSLog("📊 Found stripe_saved_cards data in UserDefaults")
            if let cards = try? JSONSerialization.jsonObject(with: cardsData) as? [[String: Any]] {
                NSLog("💳 Saved payment methods count: %d", cards.count)
                if !cards.isEmpty {
                    NSLog("✅ User has saved payment methods")
                    // Log details of first card for debugging
                    if let firstCard = cards.first {
                        NSLog("📝 First card: %@", firstCard.description)
                    }
                    return true
                }
            } else {
                NSLog("⚠️ Failed to parse stripe_saved_cards data")
            }
        } else {
            NSLog("ℹ️ No stripe_saved_cards data found in UserDefaults")
        }

        // Check for issued virtual cards
        if let issuedCardsData = UserDefaults.standard.data(forKey: "stripe_issued_cards") {
            NSLog("📊 Found stripe_issued_cards data in UserDefaults")
            if let issuedCards = try? JSONSerialization.jsonObject(with: issuedCardsData) as? [[String: Any]] {
                NSLog("💳 Issued virtual cards count: %d", issuedCards.count)
                if !issuedCards.isEmpty {
                    NSLog("✅ User has issued virtual cards")
                    // Log details of first card for debugging
                    if let firstCard = issuedCards.first {
                        NSLog("📝 First virtual card: %@", firstCard.description)
                    }
                    return true
                }
            } else {
                NSLog("⚠️ Failed to parse stripe_issued_cards data")
            }
        } else {
            NSLog("ℹ️ No stripe_issued_cards data found in UserDefaults")
        }

        NSLog("❌ User has no cards (neither payment methods nor issued cards)")
        return false
    }

    private func showNoDiceAnimation() {
        let jsCode = "showNoDiceAnimation();"
        webView.evaluateJavaScript(jsCode) { _, error in
            if let error = error {
                NSLog("⚠️ Failed to show no dice animation: %@", error.localizedDescription)
            }
        }
    }

    // MARK: - Carrier Bag

    public func openCarrierBag() {
        NSLog("🎒 Opening Carrier Bag")

        let carrierBagVC = CarrierBagViewController()
        let navController = UINavigationController(rootViewController: carrierBagVC)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true)
    }

    // MARK: - Payment Methods

    private func handlePaymentButtonClick() {
        NSLog("💳 Payment button clicked - checking card status...")

        let hasCards = checkIfUserHasCards()

        if hasCards {
            NSLog("✅ User has cards - opening CardDisplayViewController")
            openCardDisplay()
        } else {
            NSLog("⚠️ User has no cards - opening PaymentMethodViewController to add card")
            openPaymentMethods()
        }
    }

    private func openCardDisplay() {
        NSLog("💳 Opening Card Display")

        let cardDisplayVC = CardDisplayViewController()
        let navController = UINavigationController(rootViewController: cardDisplayVC)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true)
    }

    private func openPaymentMethods() {
        NSLog("💳 Opening Payment Methods")

        let paymentVC = PaymentMethodViewController()
        let navController = UINavigationController(rootViewController: paymentVC)
        navController.modalPresentationStyle = .fullScreen

        present(navController, animated: true)
    }

    // MARK: - Keyboard Installation Check

    private func checkKeyboardInstallation() {
        NSLog("⌨️ Checking keyboard installation status")

        // Check for keyboard flag in shared UserDefaults (App Group)
        let sharedDefaults = UserDefaults(suiteName: "group.app.planetnine.theadvancement")
        let keyboardInstalled = sharedDefaults?.bool(forKey: "keyboardFirstUsed") ?? false

        NSLog("⌨️ Keyboard installed: %@", keyboardInstalled ? "YES" : "NO")

        // Update UI to show/hide notice
        let jsCode = "setKeyboardNoticeVisible(\(!keyboardInstalled));"
        webView.evaluateJavaScript(jsCode) { _, error in
            if let error = error {
                NSLog("⚠️ Failed to update keyboard notice: %@", error.localizedDescription)
            }
        }
    }

    private func openKeyboardSettings() {
        NSLog("⌨️ Opening keyboard settings")

        // Show alert with helpful hint
        let alert = UIAlertController(
            title: "⌨️ Enable AdvanceKey",
            message: "We can't link you directly to KEYBOARDS, but we believe in you...GENERALly.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Take Me There", style: .default) { _ in
            // Open Settings app
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url) { success in
                    if success {
                        NSLog("✅ Opened Settings app")
                        // User will need to navigate: Settings > General > Keyboard > Keyboards
                    } else {
                        NSLog("❌ Failed to open Settings app")
                    }
                }
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    // MARK: - BDO Posting

    private func postBDO(text: String) {
        NSLog("📝 Posting BDO with text: %@", text)

        Task {
            do {
                let bdoData = try await createTextBDO(text: text)

                await MainActor.run {
                    addBDOToDisplay(bdoData)
                }
            } catch {
                NSLog("❌ Failed to post BDO: %@", error.localizedDescription)
                await MainActor.run {
                    showError("Failed to post: \\(error.localizedDescription)")
                }
            }
        }
    }

    private func createTextBDO(text: String) async throws -> [String: Any] {
        // Get BDO user UUID
        guard let bdoUserData = UserDefaults.standard.data(forKey: "bdoUser"),
              let bdoUser = try? JSONSerialization.jsonObject(with: bdoUserData) as? [String: Any],
              let uuid = bdoUser["uuid"] as? String else {
            NSLog("❌ No BDO user found in UserDefaults")
            // Try to check if it exists at all
            if let keys = Array(UserDefaults.standard.dictionaryRepresentation().keys) as? [String] {
                NSLog("📋 Available UserDefaults keys: %@", keys.joined(separator: ", "))
            }
            throw NSError(domain: "BDOError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No BDO user found"])
        }

        NSLog("✅ Using BDO user UUID: %@", uuid)

        // Create SVG from text
        let svg = createTextSVG(text: text)

        let timestamp = String(Int(Date().timeIntervalSince1970 * 1000))
        let hash = "the-advancement"
        let sessionless = Sessionless()

        guard let keys = sessionless.getKeys() else {
            throw NSError(domain: "KeyError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No keys available"])
        }

        NSLog("🔑 Using pubKey: %@", keys.publicKey)

        // The message format for BDO posting should be: timestamp + bdoUUID + hash
        let message = timestamp + uuid + hash
        NSLog("📝 Signing message: timestamp(%@) + uuid(%@) + hash(%@)", timestamp, uuid, hash)

        guard let signature = sessionless.sign(message: message) else {
            throw NSError(domain: "SignatureError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to sign"])
        }

        NSLog("✍️ Generated signature: %@...", String(signature.prefix(20)))

        let bdoPayload: [String: Any] = [
            "timestamp": timestamp,
            "signature": signature,
            "hash": hash,
            "pubKey": keys.publicKey,
            "bdo": [
                "type": "text-post",
                "text": text,
                "svgContent": svg,
                "created": timestamp
            ]
        ]

        let url = URL(string: Configuration.BDO.putBDO(userUUID: uuid))!
        NSLog("📡 Sending BDO to: %@", url.absoluteString)

        if let payloadData = try? JSONSerialization.data(withJSONObject: bdoPayload),
           let payloadString = String(data: payloadData, encoding: .utf8) {
            NSLog("📦 BDO payload: %@", payloadString)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: bdoPayload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "InvalidResponse", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "BDOError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "BDO creation failed: \\(errorMessage)"])
        }

        let responseJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Log the full response to see what we got
        if let responseString = String(data: data, encoding: .utf8) {
            NSLog("📦 BDO creation response: %@", responseString)
        }

        NSLog("✅ BDO created successfully")

        // Check if emojiShortcode is already in the response (preferred method)
        if let emojiShortcode = responseJSON?["emojiShortcode"] as? String {
            NSLog("✅ Got emojiShortcode from response: %@", emojiShortcode)
            return [
                "text": text,
                "emojicode": emojiShortcode
            ]
        }

        // Fallback: Try to get emojicode by fetching with pubKey
        if let bdoPubKey = responseJSON?["pubKey"] as? String {
            NSLog("🔑 BDO pubKey from response: %@", bdoPubKey)
            do {
                let emojicode = try await fetchEmojicode(pubKey: bdoPubKey)
                NSLog("✅ Got emojicode: %@", emojicode)
                return [
                    "text": text,
                    "emojicode": emojicode,
                    "pubKey": bdoPubKey
                ]
            } catch {
                NSLog("⚠️ Failed to fetch emojicode: %@", error.localizedDescription)
            }
        } else {
            NSLog("⚠️ No pubKey in BDO response, checking other fields")
            NSLog("📋 Response keys: %@", responseJSON?.keys.joined(separator: ", ") ?? "none")
        }

        return ["text": text, "emojicode": "🌟"]
    }

    private func createTextSVG(text: String) -> String {
        return """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 100">
            <rect width="200" height="100" fill="#1a0033"/>
            <text x="100" y="50" text-anchor="middle" fill="#ec4899" font-size="16" font-family="Arial">\(text)</text>
        </svg>
        """
    }

    private func fetchEmojicode(pubKey: String) async throws -> String {
        let url = URL(string: Configuration.BDO.getEmojicode(pubKey: pubKey))!
        NSLog("🔍 Fetching emojicode from: %@", url.absoluteString)

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            NSLog("📡 Emojicode fetch status: %d", httpResponse.statusCode)
        }

        if let responseString = String(data: data, encoding: .utf8) {
            NSLog("📄 Emojicode response: %@", responseString)
        }

        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            NSLog("📋 Emojicode JSON keys: %@", json.keys.joined(separator: ", "))

            if let emojicode = json["emojicode"] as? String {
                NSLog("📱 Got emojicode: %@", emojicode)
                return emojicode
            }
        }

        NSLog("⚠️ No emojicode found in response, returning default")
        return "🌟"
    }

    private func addBDOToDisplay(_ bdoData: [String: Any]) {
        postedBDOs.append(bdoData)

        guard let jsonData = try? JSONSerialization.data(withJSONObject: bdoData),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            NSLog("⚠️ Failed to serialize BDO data")
            return
        }

        let jsCode = """
        (function() {
            try {
                const bdoData = \(jsonString);
                console.log('📥 Received BDO data:', bdoData);
                addPostedBDO(bdoData);
            } catch(e) {
                console.error('❌ Error adding BDO:', e.message, e.stack);
            }
        })();
        """

        NSLog("📤 Executing JavaScript to add BDO")

        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                NSLog("⚠️ Failed to add BDO to display: %@", error.localizedDescription)
            } else {
                NSLog("✅ BDO added to display successfully")
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

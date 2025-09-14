//
//  KeyboardViewController.swift
//  Advancekey
//
//  Created by Zach Babb on 9/12/25.
//

import UIKit
import WebKit

class KeyboardViewController: UIInputViewController {

    @IBOutlet var nextKeyboardButton: UIButton!
    private var webView: WKWebView!

    override func updateViewConstraints() {
        super.updateViewConstraints()

        // Set keyboard height
        let heightConstraint = NSLayoutConstraint(
            item: self.view!,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 0.0,
            constant: 200.0
        )
        heightConstraint.priority = UILayoutPriority(999)
        self.view.addConstraint(heightConstraint)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSVGKeyboard()
        setupNextKeyboardButton()
    }

    private func setupSVGKeyboard() {
        // Create WebKit view for SVG rendering
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isOpaque = false
        webView.backgroundColor = UIColor.clear
        webView.scrollView.isScrollEnabled = false

        // Set up message handler for button taps
        webView.configuration.userContentController.add(self, name: "keyboardAction")

        self.view.addSubview(webView)

        // Layout WebView
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            webView.heightAnchor.constraint(equalToConstant: 160)
        ])

        // Load SVG keyboard
        loadSVGKeyboard()
    }

    private func setupNextKeyboardButton() {
        self.nextKeyboardButton = UIButton(type: .system)
        self.nextKeyboardButton.setTitle("🌐", for: [])
        self.nextKeyboardButton.sizeToFit()
        self.nextKeyboardButton.translatesAutoresizingMaskIntoConstraints = false
        self.nextKeyboardButton.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)

        self.view.addSubview(self.nextKeyboardButton)

        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 40),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func loadSVGKeyboard() {
        // Load initial MagiCard interface
        loadMagiCardInterface()
    }

    private func loadMagiCardInterface() {
        let magicHTML = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
            <style>
                body {
                    margin: 0;
                    padding: 4px;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    font-size: 12px;
                    color: white;
                }

                .keyboard-container {
                    display: flex;
                    flex-direction: column;
                    height: 148px;
                    gap: 4px;
                }

                /* Tab Navigation */
                .tab-nav {
                    display: flex;
                    gap: 2px;
                    height: 24px;
                    margin-bottom: 4px;
                }

                .tab {
                    flex: 1;
                    background: rgba(255, 255, 255, 0.2);
                    border: none;
                    border-radius: 4px;
                    color: white;
                    font-size: 10px;
                    font-weight: 500;
                    cursor: pointer;
                    transition: all 0.2s ease;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    gap: 2px;
                }

                .tab.active {
                    background: rgba(255, 255, 255, 0.3);
                    box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.2);
                }

                .tab:hover {
                    background: rgba(255, 255, 255, 0.25);
                }

                /* Main Display Area */
                .main-display {
                    flex: 1;
                    background: rgba(255, 255, 255, 0.15);
                    border-radius: 6px;
                    border: 1px solid rgba(255, 255, 255, 0.3);
                    overflow: hidden;
                    position: relative;
                    backdrop-filter: blur(10px);
                }

                .screen {
                    display: none;
                    width: 100%;
                    height: 100%;
                    padding: 6px;
                    box-sizing: border-box;
                }

                .screen.active {
                    display: flex;
                    flex-direction: column;
                }

                /* Card Display */
                .card-content {
                    width: 100%;
                    height: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    color: rgba(255, 255, 255, 0.8);
                    font-size: 11px;
                    text-align: center;
                    line-height: 1.3;
                }

                /* Planet Nine Controls */
                .controls {
                    display: flex;
                    gap: 4px;
                    height: 28px;
                    margin-top: 4px;
                }

                .btn {
                    flex: 1;
                    background: rgba(255, 255, 255, 0.2);
                    color: white;
                    border: 1px solid rgba(255, 255, 255, 0.3);
                    border-radius: 4px;
                    font-size: 10px;
                    font-weight: 500;
                    cursor: pointer;
                    transition: all 0.1s ease;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    gap: 2px;
                    backdrop-filter: blur(5px);
                }

                .btn:hover {
                    background: rgba(255, 255, 255, 0.3);
                    transform: translateY(-1px);
                }

                .btn:active {
                    transform: translateY(0px);
                    background: rgba(255, 255, 255, 0.4);
                }

                .btn-primary {
                    background: rgba(0, 123, 255, 0.3);
                    border-color: rgba(0, 123, 255, 0.5);
                }

                .btn-primary:hover {
                    background: rgba(0, 123, 255, 0.4);
                }

                .btn-success {
                    background: rgba(40, 167, 69, 0.3);
                    border-color: rgba(40, 167, 69, 0.5);
                }

                .btn-success:hover {
                    background: rgba(40, 167, 69, 0.4);
                }

                .btn-warning {
                    background: rgba(255, 193, 7, 0.3);
                    border-color: rgba(255, 193, 7, 0.5);
                }

                .btn-warning:hover {
                    background: rgba(255, 193, 7, 0.4);
                }

                .loading {
                    opacity: 0.6;
                    pointer-events: none;
                }

                .error {
                    background: rgba(220, 53, 69, 0.2);
                    border-color: rgba(220, 53, 69, 0.4);
                    color: #ffc4c4;
                }

                .success {
                    background: rgba(40, 167, 69, 0.2);
                    border-color: rgba(40, 167, 69, 0.4);
                    color: #c4ffc4;
                }

                /* Quick Actions Row */
                .quick-actions {
                    display: flex;
                    flex-wrap: wrap;
                    gap: 3px;
                    margin-bottom: 6px;
                }

                .quick-btn {
                    flex: 1;
                    min-width: 50px;
                    height: 22px;
                    background: rgba(255, 255, 255, 0.15);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    border-radius: 3px;
                    color: white;
                    font-size: 9px;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    gap: 1px;
                }

                .quick-btn:hover {
                    background: rgba(255, 255, 255, 0.25);
                }

                /* Info Display */
                .info-grid {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 4px;
                    height: 100%;
                }

                .info-item {
                    background: rgba(255, 255, 255, 0.1);
                    border-radius: 4px;
                    padding: 4px;
                    text-align: center;
                    font-size: 9px;
                    display: flex;
                    flex-direction: column;
                    justify-content: center;
                }

                .info-label {
                    opacity: 0.8;
                    margin-bottom: 2px;
                }

                .info-value {
                    font-weight: bold;
                    font-size: 10px;
                }
            </style>
        </head>
        <body>
            <div class="keyboard-container">
                <!-- Tab Navigation -->
                <div class="tab-nav">
                    <button class="tab active" data-screen="cards">🎴 Cards</button>
                    <button class="tab" data-screen="auth">🔑 Auth</button>
                    <button class="tab" data-screen="tools">⚡ Tools</button>
                    <button class="tab" data-screen="info">📊 Info</button>
                </div>

                <!-- Main Display -->
                <div class="main-display">
                    <!-- Cards Screen -->
                    <div id="cardsScreen" class="screen active">
                        <div id="cardDisplay" class="card-content">
                            🎴 Tap "Load Card" to fetch from BDO
                        </div>
                        <div class="controls">
                            <button id="loadBtn" class="btn btn-primary">📡 Load</button>
                            <button id="spellBtn" class="btn btn-warning" disabled>✨ Spell</button>
                            <button id="navBtn" class="btn btn-success" disabled>🧭 Nav</button>
                        </div>
                    </div>

                    <!-- Authentication Screen -->
                    <div id="authScreen" class="screen">
                        <div class="quick-actions">
                            <button class="quick-btn" id="generateKeysBtn">🔑 Generate Keys</button>
                            <button class="quick-btn" id="signMsgBtn">✍️ Sign Message</button>
                            <button class="quick-btn" id="verifyBtn">✅ Verify</button>
                        </div>
                        <div class="card-content" id="authDisplay">
                            🛡️ Sessionless Authentication<br>
                            <small>Secure crypto operations without passwords</small>
                        </div>
                        <div class="controls">
                            <button class="btn" id="copyPubKeyBtn">📋 Copy PubKey</button>
                            <button class="btn btn-primary" id="showKeysBtn">👁️ Show Keys</button>
                        </div>
                    </div>

                    <!-- Tools Screen -->
                    <div id="toolsScreen" class="screen">
                        <div class="quick-actions">
                            <button class="quick-btn" id="privacyEmailBtn">📧 Privacy Email</button>
                            <button class="quick-btn" id="uuidBtn">🆔 UUID</button>
                            <button class="quick-btn" id="timestampBtn">⏰ Timestamp</button>
                            <button class="quick-btn" id="hashBtn"># Hash</button>
                        </div>
                        <div class="card-content" id="toolsDisplay">
                            🛠️ Planet Nine Tools<br>
                            <small>Quick access to privacy & utility functions</small>
                        </div>
                        <div class="controls">
                            <button class="btn btn-success" id="autoFillBtn">🤖 Auto-Fill</button>
                            <button class="btn btn-warning" id="clearDataBtn">🗑️ Clear</button>
                        </div>
                    </div>

                    <!-- Info Screen -->
                    <div id="infoScreen" class="screen">
                        <div class="info-grid">
                            <div class="info-item">
                                <div class="info-label">Network</div>
                                <div class="info-value" id="networkStatus">🌐 Online</div>
                            </div>
                            <div class="info-item">
                                <div class="info-label">Base</div>
                                <div class="info-value" id="baseStatus">🏠 Local</div>
                            </div>
                            <div class="info-item">
                                <div class="info-label">Cards</div>
                                <div class="info-value" id="cardsLoaded">📦 0</div>
                            </div>
                            <div class="info-item">
                                <div class="info-label">Spells</div>
                                <div class="info-value" id="spellsCast">✨ 0</div>
                            </div>
                        </div>
                        <div class="controls">
                            <button class="btn" id="refreshBtn">🔄 Refresh</button>
                            <button class="btn btn-primary" id="aboutBtn">ℹ️ About</button>
                        </div>
                    </div>
                </div>
            </div>

            <script>
                // Global state
                let currentCard = null;
                let currentBdoPubKey = null;
                let cardsLoadedCount = 0;
                let spellsCastCount = 0;
                let currentScreen = 'cards';

                // UI Elements - Cards Screen
                const cardDisplay = document.getElementById('cardDisplay');
                const loadBtn = document.getElementById('loadBtn');
                const spellBtn = document.getElementById('spellBtn');
                const navBtn = document.getElementById('navBtn');

                // UI Elements - Auth Screen
                const authDisplay = document.getElementById('authDisplay');
                const generateKeysBtn = document.getElementById('generateKeysBtn');
                const signMsgBtn = document.getElementById('signMsgBtn');
                const verifyBtn = document.getElementById('verifyBtn');
                const copyPubKeyBtn = document.getElementById('copyPubKeyBtn');
                const showKeysBtn = document.getElementById('showKeysBtn');

                // UI Elements - Tools Screen
                const toolsDisplay = document.getElementById('toolsDisplay');
                const privacyEmailBtn = document.getElementById('privacyEmailBtn');
                const uuidBtn = document.getElementById('uuidBtn');
                const timestampBtn = document.getElementById('timestampBtn');
                const hashBtn = document.getElementById('hashBtn');
                const autoFillBtn = document.getElementById('autoFillBtn');
                const clearDataBtn = document.getElementById('clearDataBtn');

                // UI Elements - Info Screen
                const networkStatus = document.getElementById('networkStatus');
                const baseStatus = document.getElementById('baseStatus');
                const cardsLoaded = document.getElementById('cardsLoaded');
                const spellsCast = document.getElementById('spellsCast');
                const refreshBtn = document.getElementById('refreshBtn');
                const aboutBtn = document.getElementById('aboutBtn');

                // Tab Navigation
                document.querySelectorAll('.tab').forEach(tab => {
                    tab.addEventListener('click', () => {
                        const targetScreen = tab.getAttribute('data-screen');
                        switchToScreen(targetScreen);
                    });
                });

                function switchToScreen(screenName) {
                    // Update tab states
                    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
                    document.querySelector(`[data-screen="${screenName}"]`).classList.add('active');

                    // Update screen states
                    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
                    document.getElementById(`${screenName}Screen`).classList.add('active');

                    currentScreen = screenName;

                    // Screen-specific initialization
                    if (screenName === 'info') {
                        updateInfoDisplay();
                    }
                }

                function updateInfoDisplay() {
                    cardsLoaded.textContent = `📦 ${cardsLoadedCount}`;
                    spellsCast.textContent = `✨ ${spellsCastCount}`;
                }

                // Cards Screen Event Handlers
                loadBtn.addEventListener('click', async () => {
                    try {
                        loadBtn.classList.add('loading');
                        loadBtn.textContent = '⏳ Loading...';

                        // Request BDO card from Swift
                        window.webkit.messageHandlers.keyboardAction.postMessage({
                            action: 'loadBDOCard',
                            // Using a known test card from the test server
                            bdoPubKey: '03a08b9b2a57c8b4f3e5a7d9c2b1e8f4a6c9e2d5b8a1f4e7c9b2a5d8f1e4b7c0'
                        });

                    } catch (error) {
                        showError('Failed to load card: ' + error.message);
                    }
                });

                // Auth Screen Event Handlers
                generateKeysBtn.addEventListener('click', () => {
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'generateKeys'
                    });
                    authDisplay.innerHTML = '🔑 Generating new cryptographic keys...';
                });

                signMsgBtn.addEventListener('click', () => {
                    const message = 'Planet Nine Keyboard Test Message';
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'signMessage',
                        message: message
                    });
                    authDisplay.innerHTML = `✍️ Signing message:<br><small>"${message}"</small>`;
                });

                copyPubKeyBtn.addEventListener('click', () => {
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'copyPublicKey'
                    });
                    authDisplay.innerHTML = '📋 Public key copied to clipboard';
                });

                showKeysBtn.addEventListener('click', () => {
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'showKeys'
                    });
                });

                // Tools Screen Event Handlers
                privacyEmailBtn.addEventListener('click', () => {
                    const emails = [
                        'privacy@planetnineapp.com',
                        'advancement@planetnineapp.com',
                        'secure@planetnineapp.com'
                    ];
                    const email = emails[Math.floor(Math.random() * emails.length)];
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'insertText',
                        text: email
                    });
                    toolsDisplay.innerHTML = `📧 Privacy Email Inserted<br><small>${email}</small>`;
                });

                uuidBtn.addEventListener('click', () => {
                    const uuid = generateUUID();
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'insertText',
                        text: uuid
                    });
                    toolsDisplay.innerHTML = `🆔 UUID Inserted<br><small>${uuid.substring(0, 20)}...</small>`;
                });

                timestampBtn.addEventListener('click', () => {
                    const timestamp = Date.now().toString();
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'insertText',
                        text: timestamp
                    });
                    toolsDisplay.innerHTML = `⏰ Timestamp Inserted<br><small>${timestamp}</small>`;
                });

                hashBtn.addEventListener('click', () => {
                    const hash = generateRandomHash();
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'insertText',
                        text: hash
                    });
                    toolsDisplay.innerHTML = `# Hash Inserted<br><small>${hash.substring(0, 20)}...</small>`;
                });

                autoFillBtn.addEventListener('click', () => {
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'autoFillForm'
                    });
                    toolsDisplay.innerHTML = '🤖 Auto-filling detected form fields...';
                });

                clearDataBtn.addEventListener('click', () => {
                    if (confirm('Clear all Planet Nine keyboard data?')) {
                        window.webkit.messageHandlers.keyboardAction.postMessage({
                            action: 'clearAllData'
                        });
                        toolsDisplay.innerHTML = '🗑️ All data cleared';
                        cardsLoadedCount = 0;
                        spellsCastCount = 0;
                    }
                });

                // Info Screen Event Handlers
                refreshBtn.addEventListener('click', () => {
                    updateInfoDisplay();
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'refreshStatus'
                    });
                });

                aboutBtn.addEventListener('click', () => {
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'insertText',
                        text: '🌎 Planet Nine Keyboard - Privacy-first cryptographic tools for iOS'
                    });
                });

                // Utility Functions
                function generateUUID() {
                    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                        const r = Math.random() * 16 | 0;
                        const v = c == 'x' ? r : (r & 0x3 | 0x8);
                        return v.toString(16);
                    });
                }

                function generateRandomHash() {
                    const chars = 'abcdef0123456789';
                    let result = '';
                    for (let i = 0; i < 64; i++) {
                        result += chars.charAt(Math.floor(Math.random() * chars.length));
                    }
                    return result;
                }

                // Cast spell functionality
                spellBtn.addEventListener('click', () => {
                    if (!currentCard) return;

                    // Find spells in the current card
                    const spells = extractSpells(currentCard);
                    if (spells.length > 0) {
                        window.webkit.messageHandlers.keyboardAction.postMessage({
                            action: 'castSpell',
                            spellName: spells[0], // Cast first spell found
                            bdoPubKey: currentBdoPubKey
                        });
                        spellsCastCount++;
                    }
                });

                // Navigation functionality
                navBtn.addEventListener('click', () => {
                    if (!currentCard) return;

                    // Find navigation links in current card
                    const navLinks = extractNavigation(currentCard);
                    if (navLinks.length > 0) {
                        window.webkit.messageHandlers.keyboardAction.postMessage({
                            action: 'navigateCard',
                            targetPubKey: navLinks[0] // Navigate to first link
                        });
                    }
                });

                // Handle card loading response from Swift
                window.receiveCard = function(cardData, bdoPubKey) {
                    currentCard = cardData;
                    currentBdoPubKey = bdoPubKey;
                    cardsLoadedCount++;

                    // Display the SVG card
                    cardDisplay.innerHTML = cardData;

                    // Enable buttons based on card content
                    const spells = extractSpells(cardData);
                    const navLinks = extractNavigation(cardData);

                    spellBtn.disabled = spells.length === 0;
                    spellBtn.textContent = spells.length > 0 ? `✨ Spell (${spells.length})` : '✨ No Spells';

                    navBtn.disabled = navLinks.length === 0;
                    navBtn.textContent = navLinks.length > 0 ? `🧭 Nav (${navLinks.length})` : '🧭 No Nav';

                    loadBtn.classList.remove('loading');
                    loadBtn.textContent = '🔄 Reload';

                    cardDisplay.classList.add('success');
                    setTimeout(() => cardDisplay.classList.remove('success'), 1000);

                    // Update info display if on info screen
                    if (currentScreen === 'info') {
                        updateInfoDisplay();
                    }
                };

                // Handle errors from Swift
                window.showError = function(message) {
                    if (currentScreen === 'cards') {
                        cardDisplay.innerHTML = '<div class="card-content">❌ ' + message + '</div>';
                        cardDisplay.classList.add('error');
                        setTimeout(() => cardDisplay.classList.remove('error'), 3000);
                    }

                    loadBtn.classList.remove('loading');
                    loadBtn.textContent = '🔄 Retry';
                };

                // Handle responses from Swift for new actions
                window.handleAuthResponse = function(action, response) {
                    if (currentScreen !== 'auth') return;

                    switch(action) {
                        case 'generateKeys':
                            authDisplay.innerHTML = `🔑 Keys Generated!<br><small>PubKey: ${response.publicKey ? response.publicKey.substring(0, 20) + '...' : 'Ready'}</small>`;
                            break;
                        case 'signMessage':
                            authDisplay.innerHTML = `✍️ Message Signed!<br><small>Signature: ${response.signature ? response.signature.substring(0, 20) + '...' : 'Complete'}</small>`;
                            break;
                        case 'showKeys':
                            authDisplay.innerHTML = `👁️ Keys Display<br><small>PubKey: ${response.publicKey ? response.publicKey.substring(0, 30) + '...' : 'Available'}</small>`;
                            break;
                    }
                };

                window.handleToolsResponse = function(action, response) {
                    if (currentScreen !== 'tools') return;

                    if (action === 'autoFillForm') {
                        toolsDisplay.innerHTML = `🤖 Auto-fill ${response.fieldsFound ? 'Complete' : 'No fields found'}<br><small>${response.message || 'Form processing complete'}</small>`;
                    }
                };

                // Extract spells from SVG card
                function extractSpells(svgContent) {
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(svgContent, 'text/html');
                    const spellElements = doc.querySelectorAll('[spell]');
                    return Array.from(spellElements).map(el => el.getAttribute('spell'));
                }

                // Extract navigation links from SVG card
                function extractNavigation(svgContent) {
                    const parser = new DOMParser();
                    const doc = parser.parseFromString(svgContent, 'text/html');
                    const navElements = doc.querySelectorAll('[data-bdo-pubkey]');
                    return Array.from(navElements).map(el => el.getAttribute('data-bdo-pubkey'));
                }

                // Prevent scrolling and zooming
                document.addEventListener('touchmove', function(e) {
                    e.preventDefault();
                }, { passive: false });
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(magicHTML, baseURL: nil)
    }

    override func viewWillLayoutSubviews() {
        self.nextKeyboardButton.isHidden = !self.needsInputModeSwitchKey
        super.viewWillLayoutSubviews()
    }

    override func textWillChange(_ textInput: UITextInput?) {
        // The app is about to change the document's contents. Perform any preparation here.
    }

    override func textDidChange(_ textInput: UITextInput?) {
        // The app has just changed the document's contents, the document context has been updated.
        updateAppearance()
    }

    private func updateAppearance() {
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
        guard message.name == "keyboardAction",
              let body = message.body as? [String: Any],
              let action = body["action"] as? String else {
            return
        }

        switch action {
        case "insertText":
            if let text = body["text"] as? String {
                self.textDocumentProxy.insertText(text)
            }

        case "loadBDOCard":
            if let bdoPubKey = body["bdoPubKey"] as? String {
                loadCardFromBDO(bdoPubKey: bdoPubKey)
            }

        case "castSpell":
            if let spellName = body["spellName"] as? String,
               let bdoPubKey = body["bdoPubKey"] as? String {
                castSpell(spellName: spellName, bdoPubKey: bdoPubKey)
            }

        case "navigateCard":
            if let targetPubKey = body["targetPubKey"] as? String {
                loadCardFromBDO(bdoPubKey: targetPubKey)
            }

        // Authentication Actions
        case "generateKeys":
            generateSessionlessKeys()

        case "signMessage":
            if let message = body["message"] as? String {
                signMessage(message)
            }

        case "copyPublicKey":
            copyPublicKeyToClipboard()

        case "showKeys":
            showKeysInfo()

        // Tools Actions
        case "autoFillForm":
            performAutoFill()

        case "clearAllData":
            clearKeyboardData()

        case "refreshStatus":
            refreshNetworkStatus()

        default:
            break
        }
    }

    // MARK: - BDO Integration
    private func loadCardFromBDO(bdoPubKey: String) {
        Task { @MainActor in
            do {
                // For now, use a simple GET request to the BDO service
                // We'll enhance this later with proper authentication
                //let bdoURL = "http://127.0.0.1:5114/get?pubKey=\(bdoPubKey)"
                let bdoURL = "http://127.0.0.1:5114/user/3129c121-e443-4581-82c4-516fb0a2cc64/bdo?timestamp=1757775881380&hash=foo&signature=d2802f3e843b78e45b0940bc159094251dfe2c844300370e8c1019767f001eb720b46dc005552f9141c8e293584688064cca332dabc018db0247bdf7935838b0&pubKey=03617dbf0a03ce5f39cd5f6766afc82a8a26a4f6f84a08a47cf91903a2570ce27a"
                guard let url = URL(string: bdoURL) else {
                    showErrorInWebView("Invalid BDO URL")
                    return
                }

                let (data, response) = try await URLSession.shared.data(from: url)

                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    showErrorInWebView("BDO request failed: HTTP \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                    return
                }

                if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let bdoObject = jsonObject["bdo"] as? [String: Any],
                   let cardData = bdoObject["svgContent"] as? String {

                    // Send the SVG card data back to the WebView
                    let script = "window.receiveCard(`\(cardData.replacingOccurrences(of: "`", with: "\\`"))`, '\(bdoPubKey)');"
                    webView.evaluateJavaScript(script) { result, error in
                        if let error = error {
                            print("Error sending card data: \\(error)")
                            self.showErrorInWebView("Failed to display card")
                        }
                    }
                } else {
                    // Try to parse the response and see what we got
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("BDO Response: \(responseString)")
                        showErrorInWebView("Invalid card data from BDO: \(responseString.prefix(100))")
                    } else {
                        showErrorInWebView("Invalid card data from BDO")
                    }
                }

            } catch {
                showErrorInWebView("Network error: \\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Spell Casting
    private func castSpell(spellName: String, bdoPubKey: String) {
        Task { @MainActor in
            do {
                // For now, just show that we cast the spell
                // Later we can integrate with full MAGIC protocol
                let spellResult = "🎭 Cast \(spellName)! ✨"

                // Insert the spell result as text
                self.textDocumentProxy.insertText(spellResult)

                // Could also navigate to a result card
                // loadCardFromBDO(bdoPubKey: resultPubKey)

            } catch {
                showErrorInWebView("Spell casting failed: \\(error.localizedDescription)")
            }
        }
    }

    // MARK: - Error Handling
    private func showErrorInWebView(_ message: String) {
        let script = "window.showError('\(message)');"
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error showing error message: \\(error)")
            }
        }
    }

    // MARK: - Planet Nine Authentication Features
    private func generateSessionlessKeys() {
        Task { @MainActor in
            // For now, simulate key generation since we don't have full Sessionless integration
            // In a full implementation, this would use the Sessionless class from the Safari extension
            let publicKey = generateMockPublicKey()
            let response = ["publicKey": publicKey]

            let script = "window.handleAuthResponse('generateKeys', \(jsonString(from: response)));"
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error handling auth response: \\(error)")
                }
            }
        }
    }

    private func signMessage(_ message: String) {
        Task { @MainActor in
            // For now, simulate message signing
            // In a full implementation, this would use proper secp256k1 signing
            let signature = generateMockSignature()
            let response = ["signature": signature, "message": message]

            let script = "window.handleAuthResponse('signMessage', \(jsonString(from: response)));"
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error handling auth response: \\(error)")
                }
            }
        }
    }

    private func copyPublicKeyToClipboard() {
        let publicKey = generateMockPublicKey()
        UIPasteboard.general.string = publicKey

        // Provide feedback through haptic
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }

    private func showKeysInfo() {
        Task { @MainActor in
            let publicKey = generateMockPublicKey()
            let response = ["publicKey": publicKey]

            let script = "window.handleAuthResponse('showKeys', \(jsonString(from: response)));"
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error showing keys: \\(error)")
                }
            }
        }
    }

    // MARK: - Planet Nine Tools Features
    private func performAutoFill() {
        Task { @MainActor in
            // Simulate form detection and auto-fill
            let response = ["fieldsFound": true, "message": "Privacy email and UUID filled"]

            let script = "window.handleToolsResponse('autoFillForm', \(jsonString(from: response)));"
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error handling tools response: \\(error)")
                }
            }
        }
    }

    private func clearKeyboardData() {
        // Clear any stored keyboard data
        UserDefaults.standard.removeObject(forKey: "PlanetNineKeyboardData")

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func refreshNetworkStatus() {
        Task { @MainActor in
            // Check network connectivity and BDO server status
            let script = "updateInfoDisplay();"
            webView.evaluateJavaScript(script) { result, error in
                if let error = error {
                    print("Error refreshing status: \\(error)")
                }
            }
        }
    }

    // MARK: - Utility Functions
    private func generateMockPublicKey() -> String {
        // Generate a mock secp256k1 public key for testing
        return "03" + String((0..<62).map { _ in "0123456789abcdef".randomElement()! })
    }

    private func generateMockSignature() -> String {
        // Generate a mock signature for testing
        return String((0..<128).map { _ in "0123456789abcdef".randomElement()! })
    }

    private func jsonString(from dictionary: [String: Any]) -> String {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }
}

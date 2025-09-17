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

    // UIKit Context Display
    private var contextButton: UIButton!
    private var contextLabel: UILabel!

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
        setupContextDisplay()
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

        // Layout WebView - leave space at top for context label
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 40),
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

    private func setupContextDisplay() {
        // Create Context Analysis Button
        contextButton = UIButton(type: .system)
        contextButton.setTitle("🔍 Context", for: .normal)
        contextButton.setTitleColor(.white, for: .normal)
        contextButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        contextButton.backgroundColor = UIColor(red: 0.4, green: 0.47, blue: 0.92, alpha: 0.8) // Planet Nine gradient color
        contextButton.layer.cornerRadius = 6
        contextButton.translatesAutoresizingMaskIntoConstraints = false
        contextButton.addTarget(self, action: #selector(contextButtonTapped), for: .touchUpInside)

        // Create Context Display Label
        contextLabel = UILabel()
        contextLabel.numberOfLines = 0
        contextLabel.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        contextLabel.textColor = .white
        contextLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        contextLabel.layer.cornerRadius = 4
        contextLabel.layer.masksToBounds = true
        contextLabel.textAlignment = .left
        contextLabel.text = "Tap 🔍 Context to analyze"
        contextLabel.translatesAutoresizingMaskIntoConstraints = false

        // Add padding to label
        contextLabel.layer.borderWidth = 1
        contextLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor

        self.view.addSubview(contextButton)
        self.view.addSubview(contextLabel)

        NSLayoutConstraint.activate([
            // Context button - top right
            contextButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            contextButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -10),
            contextButton.widthAnchor.constraint(equalToConstant: 80),
            contextButton.heightAnchor.constraint(equalToConstant: 30),

            // Context label - in the top 40px space
            contextLabel.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10),
            contextLabel.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10),
            contextLabel.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 5),
            contextLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    @objc private func contextButtonTapped() {
        contextButton.setTitle("TAPPER", for: .normal)
        analyzeContextForUIKit()
        contextButton.backgroundColor = .orange
    }

    private func analyzeContextForUIKit() {
        let proxy = self.textDocumentProxy

        // Get text around cursor (iOS provides limited context for privacy)
        let beforeText = proxy.documentContextBeforeInput ?? "bef"
        let afterText = proxy.documentContextAfterInput ?? "aft"
        let selectedText = proxy.selectedText ?? "sel"

        // Combine all available text
        let fullContext = beforeText + selectedText + afterText

        // Analyze for Planet Nine content
        let detectedPubKey = extractPubKey(from: fullContext)

        // Create display strings
        let firstChars = fullContext.count >= 16 ?
            String(fullContext.prefix(16)) : fullContext
        let lastChars = fullContext.count >= 16 ?
            String(fullContext.suffix(16)) : ""

        let pubKeyStatus = detectedPubKey != nil ? "✅ Contains pubKey" : "❌ No pubKey"

        // Format the display text
        let displayText = """
        First: \(firstChars.isEmpty ? "(empty)" : firstChars)
        Last: \(lastChars.isEmpty ? "(same)" : lastChars)
        \(pubKeyStatus)
        """

        // Update the UIKit label
        DispatchQueue.main.async {
            self.contextLabel.text = displayText

            // Provide haptic feedback
            //let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            //impactFeedback.impactOccurred()

            // Print debug info
            print("🔍 UIKit Context Analysis:")
            print("   Full context length: \(fullContext.count)")
            print("   First 16: '\(firstChars)'")
            print("   Last 16: '\(lastChars)'")
            print("   Contains pubKey: \(detectedPubKey != nil)")
            if let pubKey = detectedPubKey {
                print("   Detected pubKey: \(pubKey)")
            }
        }

        // Also trigger the WebView context analysis which will switch to context screen
        analyzeCurrentContext()
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
                    <button class="tab" data-screen="context">🔍 Context</button>
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

                    <!-- Context Screen -->
                    <div id="contextScreen" class="screen">
                        <div class="quick-actions">
                            <button class="quick-btn" id="refreshContextBtn">🔄 Refresh</button>
                            <button class="quick-btn" id="analyzeBtn">🔍 Analyze</button>
                        </div>
                        <div class="card-content" id="contextDisplay">
                            🔍 Context Analysis<br>
                            <small>Detecting Planet Nine content around cursor</small>
                        </div>
                        <div id="detectedContent" style="display: none;">
                            <div id="pubkeySection" style="display: none;">
                                <strong>🎴 Detected pubKey:</strong><br>
                                <div id="detectedPubkey" style="font-family: monospace; font-size: 10px; word-break: break-all; margin: 4px 0; background: rgba(255,255,255,0.1); padding: 4px; border-radius: 4px;"></div>
                                <div class="controls">
                                    <button class="btn btn-primary" id="fetchCardBtn">🎴 Fetch Card</button>
                                    <button class="btn btn-success" id="respondBtn">💬 Respond</button>
                                </div>
                            </div>
                            <div id="signatureSection" style="display: none;">
                                <strong>🔐 Detected Signature:</strong><br>
                                <div id="detectedSignature" style="font-family: monospace; font-size: 10px; word-break: break-all; margin: 4px 0; background: rgba(255,255,255,0.1); padding: 4px; border-radius: 4px;"></div>
                                <div class="controls">
                                    <button class="btn btn-warning" id="verifyBtn">✅ Verify</button>
                                </div>
                            </div>
                            <div id="contextPreviewSection" style="margin-top: 8px;">
                                <strong>📄 Context:</strong><br>
                                <div id="contextPreview" style="font-size: 10px; max-height: 40px; overflow-y: auto; background: rgba(255,255,255,0.1); padding: 4px; border-radius: 4px; margin: 4px 0;"></div>
                            </div>
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

                // UI Elements - Context Screen
                const contextDisplay = document.getElementById('contextDisplay');
                const refreshContextBtn = document.getElementById('refreshContextBtn');
                const analyzeBtn = document.getElementById('analyzeBtn');
                const detectedContent = document.getElementById('detectedContent');
                const pubkeySection = document.getElementById('pubkeySection');
                const signatureSection = document.getElementById('signatureSection');
                const contextPreviewSection = document.getElementById('contextPreviewSection');
                const detectedPubkey = document.getElementById('detectedPubkey');
                const detectedSignature = document.getElementById('detectedSignature');
                const contextPreview = document.getElementById('contextPreview');
                const fetchCardBtn = document.getElementById('fetchCardBtn');
                const respondBtn = document.getElementById('respondBtn');
                const verifyBtn = document.getElementById('verifyBtn');

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
                    } else if (screenName === 'context') {
                        analyzeContext();
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

                // Context Screen Event Handlers
                refreshContextBtn.addEventListener('click', () => {
                    analyzeContext();
                });

                analyzeBtn.addEventListener('click', () => {
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'analyzeContext'
                    });
                });

                fetchCardBtn.addEventListener('click', () => {
                    if (window.detectedPubKey) {
                        window.webkit.messageHandlers.keyboardAction.postMessage({
                            action: 'fetchCard',
                            pubKey: window.detectedPubKey
                        });
                    }
                });

                respondBtn.addEventListener('click', () => {
                    if (window.detectedPubKey) {
                        window.webkit.messageHandlers.keyboardAction.postMessage({
                            action: 'respondToPubKey',
                            pubKey: window.detectedPubKey
                        });
                    }
                });

                verifyBtn.addEventListener('click', () => {
                    if (window.detectedSignature) {
                        window.webkit.messageHandlers.keyboardAction.postMessage({
                            action: 'verifySignature',
                            signature: window.detectedSignature
                        });
                    }
                });

                // Context analysis function
                function analyzeContext() {
                    contextDisplay.innerHTML = '🔍 Analyzing context...<br><small>Checking surrounding text</small>';
                    console.log('🔍 Context analysis triggered');
                    window.webkit.messageHandlers.keyboardAction.postMessage({
                        action: 'getContext'
                    });
                }

                // Handle context analysis results
                window.handleContextResponse = function(contextData) {
                    if (currentScreen !== 'context') return;

                    const { beforeText, afterText, selectedText } = contextData;
                    const fullContext = (beforeText || '') + (selectedText || '') + (afterText || '');

                    // Show context preview
                    contextPreview.textContent = fullContext.length > 100 ?
                        fullContext.substring(0, 100) + '...' : fullContext;

                    if (contextData.detectedPubKey) {
                        // Show detected pubKey
                        window.detectedPubKey = contextData.detectedPubKey;
                        detectedPubkey.textContent = contextData.detectedPubKey;
                        pubkeySection.style.display = 'block';
                        detectedContent.style.display = 'block';
                        contextDisplay.innerHTML = '🎴 Planet Nine pubKey detected!<br><small>Ready for card fetch or response</small>';
                    } else if (contextData.detectedSignature) {
                        // Show detected signature
                        window.detectedSignature = contextData.detectedSignature;
                        detectedSignature.textContent = contextData.detectedSignature;
                        signatureSection.style.display = 'block';
                        detectedContent.style.display = 'block';
                        contextDisplay.innerHTML = '🔐 Signature detected!<br><small>Ready for verification</small>';
                    } else if (fullContext.length > 0) {
                        // Show context but no Planet Nine content
                        detectedContent.style.display = 'block';
                        pubkeySection.style.display = 'none';
                        signatureSection.style.display = 'none';
                        contextDisplay.innerHTML = '📄 Text context detected<br><small>No Planet Nine content found</small>';
                    } else {
                        // No context
                        detectedContent.style.display = 'none';
                        contextDisplay.innerHTML = '🔍 No context available<br><small>Move cursor or try different field</small>';
                    }
                };

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

        // Context Actions
        case "getContext":
            analyzeCurrentContext()
        case "analyzeContext":
            analyzeCurrentContext()
        case "fetchCard":
            if let pubKey = body["pubKey"] as? String {
                loadCardFromBDO(bdoPubKey: pubKey)
            }
        case "respondToPubKey":
            if let pubKey = body["pubKey"] as? String {
                generateResponseToPubKey(pubKey)
            }
        case "verifySignature":
            if let signature = body["signature"] as? String {
                verifyContextSignature(signature)
            }

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

    // MARK: - Context Analysis Features
    private func analyzeCurrentContext() {
        // First, switch to the context screen in the WebView so the response will be processed
        let switchToContextScript = "showScreen('context');"
        webView.evaluateJavaScript(switchToContextScript) { result, error in
            if let error = error {
                print("❌ Keyboard: Error switching to context screen: \(error)")
            } else {
                print("✅ Keyboard: Switched to context screen")

                // Small delay to ensure screen switch completes, then trigger analysis
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.performContextAnalysis()
                }
            }
        }
    }

    private func performContextAnalysis() {
        let proxy = self.textDocumentProxy

        // Get text around cursor (iOS provides limited context for privacy)
        let beforeText = proxy.documentContextBeforeInput ?? ""
        let afterText = proxy.documentContextAfterInput ?? ""
        let selectedText = proxy.selectedText ?? ""

        print("🔍 Keyboard: Analyzing context - before: '\(beforeText)', after: '\(afterText)', selected: '\(selectedText)'")

        // Combine all available text
        let fullContext = beforeText + selectedText + afterText

        // Analyze for Planet Nine content
        let detectedPubKey = extractPubKey(from: fullContext)
        let detectedSignature = extractSignature(from: fullContext)

        print("🔍 Keyboard: Detected pubKey: \(detectedPubKey ?? "none"), signature: \(detectedSignature ?? "none")")

        // Automatically verify signature if detected
        if let signature = detectedSignature {
            print("🔍 Auto-verifying detected signature...")
            verifyContextSignature(signature)
        }

        // Send results back to JavaScript
        let contextData: [String: Any?] = [
            "beforeText": beforeText,
            "afterText": afterText,
            "selectedText": selectedText,
            "detectedPubKey": detectedPubKey,
            "detectedSignature": detectedSignature,
            "fullContext": fullContext
        ]

        let script = "window.handleContextResponse(\(jsonString(from: contextData.compactMapValues { $0 })));"
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Keyboard: Error sending context response: \(error)")
            } else {
                print("✅ Keyboard: Context analysis sent to UI")
            }
        }
    }

    private func extractPubKey(from text: String) -> String? {
        // Same logic as Action Extension - look for 66-character hex starting with 02/03
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
                    if matchRange.location != NSNotFound,
                       let range = Range(matchRange, in: text) {
                        let pubKey = String(text[range])
                        if isValidBDOPubKey(pubKey) {
                            print("🎴 Keyboard: Found valid pubKey: \(pubKey)")
                            return pubKey
                        }
                    }
                }
            }
        }
        return nil
    }

    private func extractSignature(from text: String) -> String? {
        // Look for hex signatures (typically 128 characters for secp256k1)
        let patterns = [
            #"signature[:\s]*([0-9a-fA-F]{128})"#,
            #"sig[:\s]*([0-9a-fA-F]{128})"#,
            #"([0-9a-fA-F]{128})"# // Just find any 128-char hex
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: text.count)
                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchRange = match.range(at: 1)
                    if matchRange.location != NSNotFound,
                       let range = Range(matchRange, in: text) {
                        let signature = String(text[range])
                        print("🔐 Keyboard: Found potential signature: \(signature.prefix(20))...")
                        return signature
                    }
                }
            }
        }
        return nil
    }

    private func isValidBDOPubKey(_ pubKey: String) -> Bool {
        // Check if it's a 66-character hex string starting with 02 or 03 (compressed pubkey)
        let cleanPubKey = pubKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanPubKey.count == 66 else { return false }
        guard cleanPubKey.hasPrefix("02") || cleanPubKey.hasPrefix("03") else { return false }

        let hexCharacters = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        return cleanPubKey.unicodeScalars.allSatisfy { hexCharacters.contains($0) }
    }

    private func generateResponseToPubKey(_ pubKey: String) {
        print("💬 Keyboard: Generating response to pubKey: \(pubKey)")

        // Generate a signed response message
        let message = "Response to \(pubKey.prefix(20))... from Planet Nine Keyboard"
        let signature = generateMockSignature()
        let response = "Signed response: \(message)\nSignature: \(signature)"

        // Insert the response into the text field
        textDocumentProxy.insertText(response)

        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func verifyContextSignature(_ signature: String) {
        print("✅ Keyboard: Verifying signature: \(signature.prefix(20))...")

        // Alice's public key for verification (configured for demo)
        let ALICE_PUBLIC_KEY = "027f68e0f4dfa964ebca3b9f90a15b8ffde8e91ebb0e2e36907fb0cc7aec48448e"

        // Get the message from context to verify against
        let proxy = self.textDocumentProxy
        let beforeText = proxy.documentContextBeforeInput ?? ""
        let afterText = proxy.documentContextAfterInput ?? ""
        let selectedText = proxy.selectedText ?? ""
        let fullContext = beforeText + selectedText + afterText

        // Extract message from context (look for patterns like "Message: ...")
        let message = extractMessageFromContext(fullContext) ?? "Demo verification message"

        // Verify signature using Alice's demo verification logic
        let isValid = verifySignatureForAlice(signature: signature, message: message)

        // Create red/green light feedback
        let statusEmoji = isValid ? "🟢" : "🔴"
        let result = isValid ? "✅ VALID (Alice)" : "❌ INVALID"
        let lightStatus = isValid ? "GREEN LIGHT" : "RED LIGHT"

        let feedback = "\(statusEmoji) \(lightStatus)\n\(result)\nSignature: \(signature.prefix(40))..."

        // Insert verification result
        textDocumentProxy.insertText(feedback)

        // Provide strong haptic feedback for red/green result
        let impactFeedback = UIImpactFeedbackGenerator(style: isValid ? .heavy : .medium)
        impactFeedback.impactOccurred()

        // Additional feedback for invalid signatures
        if !isValid {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let secondFeedback = UIImpactFeedbackGenerator(style: .light)
                secondFeedback.impactOccurred()
            }
        }

        // Update context screen with red/green visual feedback
        updateContextScreenWithVerificationResult(isValid: isValid, signature: signature)
    }

    private func extractMessageFromContext(_ context: String) -> String? {
        // Look for message patterns in the context
        let patterns = [
            #"Message:\s*"([^"]+)""#,
            #"message\s+(\d+)\s+at\s+(\d+)"#,
            #"Demo message\s+(\d+)\s+at\s+(\d+)"#
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: context.count)
                if let match = regex.firstMatch(in: context, options: [], range: range) {
                    let fullMatchRange = match.range(at: 0)
                    if fullMatchRange.location != NSNotFound,
                       let range = Range(fullMatchRange, in: context) {
                        let extractedMessage = String(context[range])
                        print("📝 Extracted message: \(extractedMessage)")
                        return extractedMessage
                    }
                }
            }
        }

        return nil
    }

    private func verifySignatureForAlice(signature: String, message: String) -> Bool {
        // Alice's private key for signature generation (demo purposes only)
        let ALICE_PRIVATE_KEY = "574102268f66ae19bda4c4fb08fa4fe705381b68e608f17516e70ce20f60e66d"

        // Generate what Alice's signature should be for this message
        let expectedSignature = generateDemoSignature(privateKey: ALICE_PRIVATE_KEY, message: message)

        print("🔍 Expected signature: \(expectedSignature.prefix(20))...")
        print("🔍 Received signature: \(signature.prefix(20))...")

        // Check if signatures match
        let isValid = signature == expectedSignature
        print("✅ Signature validation: \(isValid ? "VALID" : "INVALID")")

        return isValid
    }

    private func generateDemoSignature(privateKey: String, message: String) -> String {
        // Demo signature generation matching the browser implementation
//        let combinedInput = privateKey + message
//
//        var hash = 0
//        for char in combinedInput {
//            let charValue = Int(char.asciiValue ?? 0)
//            hash = ((hash << 5) - hash) + charValue
//            hash = hash & hash // Convert to 32-bit
//        }
//
//        let baseSignature = String(format: "%08x", abs(hash))
//        let messageHex = message.compactMap { String(format: "%02x", $0.asciiValue ?? 0) }.joined()
//
//        let signature = (baseSignature + privateKey.prefix(56) + baseSignature + messageHex.prefix(32))
//            .prefix(128)
//            .padding(toLength: 128, withPad: "0", startingAt: 0)

        let signature = "here is where the signature goes"
        return String(signature)
    }

    private func updateContextScreenWithVerificationResult(isValid: Bool, signature: String) {
        let statusColor = isValid ? "green" : "red"
        let statusText = isValid ? "VALID ✅" : "INVALID ❌"
        let lightEmoji = isValid ? "🟢" : "🔴"

        let script = """
        if (currentScreen === 'context') {
            const contextDisplay = document.getElementById('contextDisplay');
            if (contextDisplay) {
                contextDisplay.innerHTML = '\(lightEmoji) Signature \(statusText)<br><small>\(signature.prefix(40))...</small>';
                contextDisplay.style.backgroundColor = 'rgba(\(isValid ? "40, 167, 69" : "220, 53, 69"), 0.3)';
                contextDisplay.style.borderColor = 'rgba(\(isValid ? "40, 167, 69" : "220, 53, 69"), 0.5)';
            }
        }
        """

        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ Error updating context screen: \(error)")
            } else {
                print("✅ Context screen updated with \(isValid ? "green" : "red") status")
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

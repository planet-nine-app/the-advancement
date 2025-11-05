//
//  ShareViewController.swift
//  AdvanceShare
//
//  Created by Zach Babb on 10/6/25.
//

import Cocoa
import WebKit

class ShareViewController: NSViewController {

    var contentView: NSView!
    var webView: WKWebView!
    var sessionless: Sessionless!
    var debugLabel: NSTextField!
    var messageLabel: NSTextField!
    var bdoService: BDOService!

    override var nibName: NSNib.Name? {
        return NSNib.Name("ShareViewController")
    }

    override func loadView() {
        super.loadView()

        // Set background color so it's not black
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set preferred content size (100px wider, 600px taller than default)
        self.preferredContentSize = NSSize(width: 540, height: 940)

        // Set up Sessionless
        setupSessionless()

        // Setup debug label at top
        let labelY = self.view.frame.height - 60
        debugLabel = NSTextField(frame: NSRect(x: 20, y: labelY, width: self.view.frame.width - 40, height: 30))
        debugLabel.isEditable = false
        debugLabel.isBordered = false
        debugLabel.backgroundColor = NSColor.clear
        debugLabel.textColor = NSColor.labelColor
        debugLabel.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        debugLabel.stringValue = "Loading emojicoded content..."
        debugLabel.alignment = .center
        self.view.addSubview(debugLabel)

        // Setup content view with WebView
        let contentY: CGFloat = 60
        let contentHeight = self.view.frame.height - 120
        contentView = NSView(frame: NSRect(x: 20, y: contentY, width: self.view.frame.width - 40, height: contentHeight))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.view.addSubview(contentView)

        // Setup WKWebView inside content view
        webView = WKWebView(frame: contentView.bounds)
        webView.autoresizingMask = [.width, .height]
        contentView.addSubview(webView)

        // Setup message label on top of WebView (initially visible)
        let messageFrame = NSRect(x: 20, y: (contentHeight - 100) / 2, width: contentView.frame.width - 40, height: 100)
        messageLabel = NSTextField(frame: messageFrame)
        messageLabel.isEditable = false
        messageLabel.isBordered = false
        messageLabel.backgroundColor = NSColor.clear
        messageLabel.textColor = NSColor.secondaryLabelColor
        messageLabel.font = NSFont.systemFont(ofSize: 16)
        messageLabel.stringValue = "🔄 Processing emojicoded content..."
        messageLabel.alignment = .center
        messageLabel.maximumNumberOfLines = 0
        contentView.addSubview(messageLabel)

        // Process shared content after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.processSharedContent()
        }
    }

    func showMessage(_ message: String, icon: String = "ℹ️") {
        DispatchQueue.main.async { [weak self] in
            self?.messageLabel.stringValue = "\(icon)\n\n\(message)"
        }
    }

    func setupSessionless() {
        NSLog("ADVANCESHARE: 🔧 Setting up Sessionless...")
        sessionless = Sessionless()
        bdoService = BDOService(sessionless: sessionless)
        NSLog("ADVANCESHARE: 📝 Sessionless and BDOService instances created")

        // Try to get existing keys
        NSLog("ADVANCESHARE: 🔑 Attempting to retrieve keys from keychain...")
        let keys = sessionless.getKeys()
        if keys == nil {
            NSLog("ADVANCESHARE: ⚠️ No Sessionless keys found - keys will be generated if needed")
            DispatchQueue.main.async { [weak self] in
                self?.debugLabel?.stringValue = "No keys found - will generate"
            }
        } else {
            NSLog("ADVANCESHARE: ✅ Sessionless initialized with keys: %@", keys!.publicKey)
            DispatchQueue.main.async { [weak self] in
                self?.debugLabel?.stringValue = "Keys loaded successfully"
            }
        }
        NSLog("ADVANCESHARE: ✅ Setup complete")
    }

    func processSharedContent() {
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem else {
            NSLog("ADVANCESHARE: ❌ No input items")
            debugLabel.stringValue = "No content shared"
            showMessage("No content was shared with AdvanceShare.\n\nPlease select text containing emojicoded content and share it.", icon: "⚠️")
            return
        }

        // First try to get attributed content text (this is what Messages uses)
        if let attributedContent = item.attributedContentText {
            NSLog("ADVANCESHARE: 📝 Found attributed content text")
            let plainText = attributedContent.string
            processSharedText(plainText)
            return
        }

        // Fall back to checking attachments
        guard let attachments = item.attachments, attachments.count > 0 else {
            NSLog("ADVANCESHARE: ❌ No attachments and no attributed content")
            NSLog("ADVANCESHARE: Item looks like \(item)")
            debugLabel.stringValue = "No content found"
            showMessage("The shared content has no text.\n\nPlease share text containing emojicoded content.", icon: "⚠️")
            return
        }

        NSLog("ADVANCESHARE: 📎 Processing %d attachments", attachments.count)

        // Look for text content in attachments
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier("public.plain-text") {
                attachment.loadItem(forTypeIdentifier: "public.plain-text", options: nil) { [weak self] (data, error) in
                    DispatchQueue.main.async {
                        if let text = data as? String {
                            self?.processSharedText(text)
                        } else if let textData = data as? Data, let text = String(data: textData, encoding: .utf8) {
                            self?.processSharedText(text)
                        }
                    }
                }
            }
        }
    }

    func processSharedText(_ text: String) {
        NSLog("ADVANCESHARE: 📝 Received text: %@", String(text.prefix(100)))

        // Look for emojicode (starts and ends with ✨)
        if let emojicode = extractEmojicode(from: text) {
            NSLog("ADVANCESHARE: 🎨 Found emojicode: %@", String(emojicode.prefix(30)))
            DispatchQueue.main.async { [weak self] in
                self?.debugLabel?.stringValue = "Decoding emojicode..."
            }

            // Decode emojicode and fetch BDO
            decodeAndFetchBDO(emojicode: emojicode)
        } else {
            NSLog("ADVANCESHARE: ❌ No emojicode found in shared text")
            DispatchQueue.main.async { [weak self] in
                self?.debugLabel?.stringValue = "No emojicode found"
            }
            showMessage("The shared text doesn't contain an emojicoded sequence (✨...✨).\n\nPlease share text that contains emojicoded content.", icon: "⚠️")
        }
    }

    func decodeAndFetchBDO(emojicode: String) {
        // Load emojicoding JavaScript using Sessionless JSContext
        guard let jsContext = sessionless.jsContext else {
            NSLog("ADVANCESHARE: ❌ No JavaScript context available")
            showMessage("JavaScript context not available", icon: "❌")
            return
        }

        // Load emojicoding.js
        guard let emojicodingPath = Bundle.main.path(forResource: "emojicoding", ofType: "js"),
              let emojicodingJS = try? String(contentsOfFile: emojicodingPath) else {
            NSLog("ADVANCESHARE: ❌ Could not load emojicoding.js")
            showMessage("Could not load emojicoding library", icon: "❌")
            return
        }

        // Check if atob/btoa are available, if not provide polyfills
        let checkAtob = jsContext.evaluateScript("typeof atob")
        NSLog("ADVANCESHARE: 🔍 typeof atob: %@", checkAtob?.toString() ?? "nil")

        if checkAtob?.toString() == "undefined" {
            NSLog("ADVANCESHARE: 📝 Adding atob/btoa polyfills")
            // Add atob/btoa polyfills for JavaScriptCore
            let polyfill = """
            function atob(base64) {
                const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
                let str = base64.replace(/=+$/, '');
                let output = '';

                for (let bc = 0, bs = 0, buffer, i = 0; (buffer = str.charAt(i++));) {
                    buffer = chars.indexOf(buffer);
                    if (buffer === -1) continue;
                    bs = bc % 4 ? bs * 64 + buffer : buffer;
                    if (bc++ % 4) {
                        output += String.fromCharCode(255 & bs >> (-2 * bc & 6));
                    }
                }
                return output;
            }

            function btoa(input) {
                const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
                let str = input;
                let output = '';

                for (let block = 0, charCode, i = 0, map = chars; str.charAt(i | 0) || (map = '=', i % 1); output += map.charAt(63 & block >> 8 - i % 1 * 8)) {
                    charCode = str.charCodeAt(i += 3/4);
                    if (charCode > 0xFF) {
                        throw new Error("'btoa' failed: The string to be encoded contains characters outside of the Latin1 range.");
                    }
                    block = block << 8 | charCode;
                }
                return output;
            }
            """
            jsContext.evaluateScript(polyfill)
        }

        // Execute the emojicoding library
        jsContext.evaluateScript(emojicodingJS)

        // Decode the emojicode
        guard let simpleDecodeEmoji = jsContext.objectForKeyedSubscript("simpleDecodeEmoji") else {
            NSLog("ADVANCESHARE: ❌ simpleDecodeEmoji function not found")
            showMessage("Decoding function not available", icon: "❌")
            return
        }

        let result = simpleDecodeEmoji.call(withArguments: [emojicode])

        NSLog("ADVANCESHARE: 🔍 Result object: %@", result?.toString() ?? "nil")

        guard let hexValue = result?.objectForKeyedSubscript("hex") else {
            NSLog("ADVANCESHARE: ❌ No hex property in result")
            showMessage("Failed to decode emojicode", icon: "❌")
            return
        }

        guard !hexValue.isUndefined, let hex = hexValue.toString(), hex != "undefined" else {
            NSLog("ADVANCESHARE: ❌ Hex value is undefined")
            showMessage("Failed to decode emojicode", icon: "❌")
            return
        }

        NSLog("ADVANCESHARE: 🔓 Decoded hex: %@", hex)
        DispatchQueue.main.async { [weak self] in
            self?.debugLabel?.stringValue = "Fetching BDO..."
        }

        // Fetch the BDO
        Task {
            do {
                let bdoData = try await self.bdoService.fetchBDO(bdoPubKey: hex)
                NSLog("ADVANCESHARE: ✅ BDO fetched successfully")

                DispatchQueue.main.async { [weak self] in
                    self?.displayBDO(bdoData)
                }
            } catch {
                NSLog("ADVANCESHARE: ❌ Failed to fetch BDO: %@", error.localizedDescription)
                DispatchQueue.main.async { [weak self] in
                    self?.showMessage("Failed to fetch BDO:\n\(error.localizedDescription)", icon: "❌")
                }
            }
        }
    }

    func displayBDO(_ bdoData: [String: Any]) {
        NSLog("ADVANCESHARE: 📦 Displaying BDO...")
        debugLabel?.stringValue = "BDO loaded!"

        // Extract SVG content from the BDO data - try different possible paths
        var svgContent: String?

        // Path 1: Direct svgContent
        if let svg = bdoData["svgContent"] as? String {
            svgContent = svg
            NSLog("ADVANCESHARE: Found SVG in bdoData[svgContent]")
        }
        // Path 2: data.svgContent
        else if let data = bdoData["data"] as? [String: Any],
                let svg = data["svgContent"] as? String {
            svgContent = svg
            NSLog("ADVANCESHARE: Found SVG in bdoData[data][svgContent]")
        }
        // Path 3: bdo.svgContent
        else if let bdo = bdoData["bdo"] as? [String: Any],
                let svg = bdo["svgContent"] as? String {
            svgContent = svg
            NSLog("ADVANCESHARE: Found SVG in bdoData[bdo][svgContent]")
        }
        // Path 4: successful[0].bdo.svgContent
        else if let successful = bdoData["successful"] as? [[String: Any]],
                let firstResult = successful.first,
                let bdo = firstResult["bdo"] as? [String: Any],
                let svg = bdo["svgContent"] as? String {
            svgContent = svg
            NSLog("ADVANCESHARE: Found SVG in bdoData[successful][0][bdo][svgContent]")
        }

        if let svg = svgContent {
            NSLog("ADVANCESHARE: 🎨 Rendering SVG content (\(svg.count) characters)")

            // Hide the message label
            messageLabel.isHidden = true

            // Create HTML wrapper for SVG
            let html = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="UTF-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    body {
                        margin: 0;
                        padding: 20px;
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        min-height: 100vh;
                        background-color: #1a1a1a;
                    }
                    svg {
                        max-width: 100%;
                        max-height: 100%;
                        width: auto;
                        height: auto;
                    }
                    svg rect[spell], svg text[spell], svg [spell] {
                        transition: opacity 0.2s;
                        cursor: pointer;
                    }
                    svg rect[spell]:hover, svg text[spell]:hover, svg [spell]:hover {
                        opacity: 0.8;
                    }
                    /* Tooltip styling */
                    .spell-tooltip {
                        position: fixed;
                        background: rgba(0, 0, 0, 0.9);
                        color: white;
                        padding: 8px 12px;
                        border-radius: 6px;
                        font-size: 12px;
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                        white-space: nowrap;
                        pointer-events: none;
                        z-index: 1000;
                        opacity: 0;
                        transition: opacity 0.2s;
                    }
                </style>
            </head>
            <body>
                \(svg)
                <script>
                    // Spell descriptions for tooltips
                    const spellDescriptions = {
                        'collect': 'Save to your collection',
                        'save': 'Save to your collection',
                        'add-to-cart': 'Add to shopping cart',
                        'sign': 'Sign this contract step',
                        'decline': 'Decline this contract',
                        'share': 'Share with others',
                        'magic': 'Cast magical spell',
                        'buy': 'Purchase this item',
                        'purchaseLesson': 'Purchase this lesson',
                        'signInMoney': 'Complete payment and sign contract',
                        'purchase': 'Process payment',
                        'selection': 'Add to magistack selection',
                        'magicard': 'Navigate to another card',
                        'lookup': 'Find product from selections'
                    };

                    // Create tooltip element
                    const tooltip = document.createElement('div');
                    tooltip.className = 'spell-tooltip';
                    document.body.appendChild(tooltip);

                    // Show tooltip on hover
                    document.addEventListener('mouseover', function(e) {
                        const spell = e.target.getAttribute('spell');
                        const spellDescription = e.target.getAttribute('spell-description');

                        if (spell) {
                            let tooltipText = spellDescription || spellDescriptions[spell] || `Will cast ${spell}`;
                            tooltip.textContent = tooltipText;
                            tooltip.style.opacity = '1';

                            // Position tooltip near cursor
                            const rect = e.target.getBoundingClientRect();
                            tooltip.style.left = rect.left + (rect.width / 2) - (tooltip.offsetWidth / 2) + 'px';
                            tooltip.style.top = (rect.top - tooltip.offsetHeight - 5) + 'px';
                        }
                    });

                    // Hide tooltip
                    document.addEventListener('mouseout', function(e) {
                        const spell = e.target.getAttribute('spell');
                        if (spell) {
                            tooltip.style.opacity = '0';
                        }
                    });

                    // Handle spell clicks
                    document.addEventListener('click', function(e) {
                        const spell = e.target.getAttribute('spell');
                        if (spell) {
                            const spellComponents = e.target.getAttribute('spell-components');
                            console.log('Spell clicked in AdvanceShare:', spell, 'components:', spellComponents);
                            alert('🪄 Spell cast: ' + spell + '\\n\\nNote: Full spell handling not yet implemented in AdvanceShare.\\nUse AdvanceKey for complete spell casting functionality.');
                        }
                    });
                </script>
            </body>
            </html>
            """

            webView.loadHTMLString(html, baseURL: nil)
            NSLog("ADVANCESHARE: ✅ SVG loaded into WebView")
        } else {
            NSLog("ADVANCESHARE: ⚠️ No SVG content found in BDO")
            NSLog("ADVANCESHARE: BDO data keys: %@", bdoData.keys.joined(separator: ", "))

            // Fallback: show BDO info as text
            var displayText = "✨ BDO Content ✨\n\n"

            if let title = bdoData["title"] as? String {
                displayText += "Title: \(title)\n\n"
            }

            if let type = bdoData["type"] as? String {
                displayText += "Type: \(type)\n\n"
            }

            if let pubKey = bdoData["pubKey"] as? String {
                displayText += "PubKey: \(String(pubKey.prefix(16)))...\n\n"
            }

            displayText += "No SVG content available\n\n"
            displayText += "Available keys: \(bdoData.keys.joined(separator: ", "))"

            messageLabel.isHidden = false
            showMessage(displayText, icon: "⚠️")
        }
    }

    func extractEmojicode(from text: String) -> String? {
        // Look for text between ✨ markers
        guard let startRange = text.range(of: "✨"),
              let endRange = text.range(of: "✨", options: .backwards),
              startRange.upperBound < endRange.lowerBound else {
            return nil
        }

        return String(text[startRange.lowerBound..<endRange.upperBound])
    }


    // MARK: - Actions

    @IBAction func send(_ sender: AnyObject?) {
        let outputItem = NSExtensionItem()
        let outputItems = [outputItem]
        self.extensionContext!.completeRequest(returningItems: outputItems, completionHandler: nil)
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        self.extensionContext!.cancelRequest(withError: cancelError)
    }
}

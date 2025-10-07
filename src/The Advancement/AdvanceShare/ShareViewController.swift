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
    var sessionless: Sessionless!
    var debugLabel: NSTextField!
    var messageLabel: NSTextField!

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

        // Setup content view (simple view instead of WebView)
        let contentY: CGFloat = 60
        let contentHeight = self.view.frame.height - 120
        contentView = NSView(frame: NSRect(x: 20, y: contentY, width: self.view.frame.width - 40, height: contentHeight))
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.view.addSubview(contentView)

        // Setup message label in the middle
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
        let sharedDefaults = UserDefaults(suiteName: "group.com.planetnine.Planet-Nine")

        guard let savedKeys = sharedDefaults?.string(forKey: "sessionless_keys") else {
            NSLog("ADVANCESHARE: ❌ No Sessionless keys found in shared defaults")
            // Don't show error yet - wait until we actually need it
            return
        }

        guard let savedKeysData = savedKeys.data(using: .utf8),
              let keysDict = try? JSONSerialization.jsonObject(with: savedKeysData, options: []) as? [String: String],
              let publicKey = keysDict["publicKey"],
              let privateKey = keysDict["privateKey"] else {
            NSLog("ADVANCESHARE: ❌ Failed to parse Sessionless keys")
            return
        }

        sessionless = Sessionless()
        NSLog("ADVANCESHARE: ✅ Sessionless initialized")
    }

    func processSharedContent() {
        guard let item = self.extensionContext?.inputItems.first as? NSExtensionItem else {
            NSLog("ADVANCESHARE: ❌ No input items")
            debugLabel.stringValue = "No content shared"
            showMessage("No content was shared with AdvanceShare.\n\nPlease select text containing emojicoded content and share it.", icon: "⚠️")
            return
        }

        guard let attachments = item.attachments, attachments.count > 0 else {
            NSLog("ADVANCESHARE: ❌ No attachments")
            debugLabel.stringValue = "No attachments found"
            showMessage("The shared content has no attachments.\n\nPlease share text containing emojicoded content.", icon: "⚠️")
            return
        }

        NSLog("ADVANCESHARE: 📎 Processing %d attachments", attachments.count)

        // Look for text content
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
            debugLabel.stringValue = "Emojicode found!"
            showMessage("Found emojicoded content!\n\n\(emojicode)\n\nThis feature will be completed soon to display the decoded content.", icon: "✨")
        } else {
            NSLog("ADVANCESHARE: ❌ No emojicode found in shared text")
            debugLabel.stringValue = "No emojicode found"
            showMessage("The shared text doesn't contain an emojicoded sequence (✨...✨).\n\nPlease share text that contains emojicoded content.", icon: "⚠️")
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

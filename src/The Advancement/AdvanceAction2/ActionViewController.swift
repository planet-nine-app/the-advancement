//
//  ActionViewController.swift
//  AdvanceAction2
//
//  Created by Zach Babb on 9/16/25.
//

import Cocoa

class ActionViewController: NSViewController {

    @IBOutlet var myTextView: NSTextView!

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        NSLog("🚨🚨🚨 AdvanceAction2 EMERGENCY INIT")
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        NSLog("🚨🚨🚨 AdvanceAction2 EMERGENCY INIT COMPLETE")
    }

    required init?(coder: NSCoder) {
        NSLog("🚨🚨🚨 AdvanceAction2 EMERGENCY INIT CODER")
        super.init(coder: coder)
        NSLog("🚨🚨🚨 AdvanceAction2 EMERGENCY INIT CODER COMPLETE")
    }

    override var nibName: NSNib.Name? {
        NSLog("🚨 AdvanceAction2 nibName requested")
        return NSNib.Name("ActionViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("🚨 AdvanceAction2 viewDidLoad called")

        guard let extensionContext = self.extensionContext else {
            NSLog("🚨 AdvanceAction2 ERROR: No extension context")
            return
        }

        NSLog("🚨 AdvanceAction2 Input Items = %@", extensionContext.inputItems as NSArray)

        guard !extensionContext.inputItems.isEmpty,
              let sharedItem = extensionContext.inputItems[0] as? NSExtensionItem else {
            NSLog("🚨 AdvanceAction2 ERROR: No input items")
            return
        }

        let text = sharedItem.attributedContentText?.string
        NSLog("🚨 AdvanceAction2 Extracted text: %@", text ?? "nil")

        if let text = text, !text.isEmpty, let textView = self.myTextView {
            textView.string = text
            NSLog("🚨 AdvanceAction2 Text set in text view")
        } else {
            NSLog("🚨 AdvanceAction2 ERROR: Could not set text - text:%@ textView:%@", text ?? "nil", myTextView?.description ?? "nil")
        }
    }

    @IBAction func send(_ sender: AnyObject?) {
        NSLog("🚨 AdvanceAction2 send button clicked")

        guard let context = extensionContext else {
            NSLog("🚨 AdvanceAction2 ERROR: No extension context in send")
            return
        }

        guard context.inputItems.count == 1,
              let inputItem = context.inputItems[0] as? NSExtensionItem else {
            NSLog("🚨 AdvanceAction2 ERROR: Expected exactly one extension item")
            return
        }

        let processedText = "🌍 Planet Nine: \(myTextView.string)"
        NSLog("🚨 AdvanceAction2 Processed text: %@", processedText)

        let outputItem = NSExtensionItem()
        outputItem.attributedContentText = NSAttributedString(string: processedText)

        let outputItems = [outputItem]
        context.completeRequest(returningItems: outputItems, completionHandler: nil)
        NSLog("🚨 AdvanceAction2 Request completed successfully")
    }

    @IBAction func cancel(_ sender: AnyObject?) {
        NSLog("🚨 AdvanceAction2 cancel button clicked")

        guard let context = extensionContext else {
            NSLog("🚨 AdvanceAction2 ERROR: No extension context in cancel")
            return
        }

        let cancelError = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        context.cancelRequest(withError: cancelError)
        NSLog("🚨 AdvanceAction2 Request cancelled")
    }

    // NSServices method handler
    @objc func showPlanetNineCard(_ pboard: NSPasteboard, userData: String, error: NSErrorPointer) {
        NSLog("🚨🚨🚨 AdvanceAction2 NSServices method called!")

        guard let text = pboard.string(forType: .string) else {
            NSLog("🚨 AdvanceAction2 NSServices: No text on pasteboard")
            return
        }

        NSLog("🚨 AdvanceAction2 NSServices received text: %@", text)

        // For now, just log that the service was called
        // This should help us determine if NSServices works when extension doesn't
    }
}

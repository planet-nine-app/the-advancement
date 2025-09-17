//
//  ActionRequestHandler.swift
//  AdvanceAction2
//
//  Created by Zach Babb on 9/16/25.
//

import Foundation

@objc(ActionRequestHandler)
public class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    public func beginRequest(with context: NSExtensionContext) {
        NSLog("🚨 AdvanceAction2 ActionRequestHandler beginRequest called")

        // For an Action Extension there will only ever be one extension item
        guard context.inputItems.count == 1,
              let inputItem = context.inputItems[0] as? NSExtensionItem else {
            NSLog("🚨 AdvanceAction2 ERROR: Expected exactly one extension item")
            context.cancelRequest(withError: NSError(domain: "AdvanceAction2Error", code: 1, userInfo: nil))
            return
        }

        NSLog("🚨 AdvanceAction2 Processing extension item")

        // First, check for text content in the extension item itself
        if let inputContent = inputItem.attributedContentText {
            NSLog("🚨 AdvanceAction2 Found attributed content text: %@", inputContent.string)

            // Process the text - for now, just add a Planet Nine prefix
            let processedText = "🌍 Planet Nine: \(inputContent.string)"

            let outputItem = NSExtensionItem()
            outputItem.attributedContentText = NSAttributedString(string: processedText)

            NSLog("🚨 AdvanceAction2 Returning processed text: %@", processedText)
            context.completeRequest(returningItems: [outputItem], completionHandler: nil)

        } else if let inputAttachments = inputItem.attachments {
            NSLog("🚨 AdvanceAction2 Found %d attachments", inputAttachments.count)

            // Use a dispatch group to synchronize asynchronous calls
            let dispatchGroup = DispatchGroup()
            var outputAttachments: [NSItemProvider] = []

            // Process text in each attachment
            for (index, attachment) in inputAttachments.enumerated() {
                NSLog("🚨 AdvanceAction2 Processing attachment %d", index)
                dispatchGroup.enter()

                attachment.loadObject(ofClass: NSString.self as NSItemProviderReading.Type) { (object, error) in
                    if let string = object as? String {
                        NSLog("🚨 AdvanceAction2 Loaded string from attachment: %@", string)
                        let processedText = "🌍 Planet Nine: \(string)"
                        let outputItemProvider = NSItemProvider(object: processedText as NSItemProviderWriting)
                        outputAttachments.append(outputItemProvider)
                    } else {
                        NSLog("🚨 AdvanceAction2 ERROR loading attachment: %@", error?.localizedDescription ?? "Unknown error")
                    }
                    dispatchGroup.leave()
                }
            }

            dispatchGroup.notify(queue: DispatchQueue.main) {
                let outputItem = NSExtensionItem()
                outputItem.attachments = outputAttachments

                NSLog("🚨 AdvanceAction2 Returning %d processed attachments", outputAttachments.count)
                context.completeRequest(returningItems: [outputItem], completionHandler: nil)
            }

        } else {
            NSLog("🚨 AdvanceAction2 ERROR: No text content found in extension item")
            context.cancelRequest(withError: NSError(domain: "AdvanceAction2Error", code: 2, userInfo: [NSLocalizedDescriptionKey: "No text content found"]))
        }
    }
}
//
//  ShareViewController.swift
//  toolsextension
//
//  Created by john val on 12/8/24.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    // Validate the content to enable/disable the Post button
    override func isContentValid() -> Bool {
        // Ensure there's text content to share
        return !contentText.isEmpty
    }

    // Called when the user taps "Post"
    override func didSelectPost() {
        guard let sharedText = self.contentText else {
            // If no content is provided, exit gracefully
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        // Save the shared text to the App Group UserDefaults
        if let userDefaults = UserDefaults(suiteName: "group.red.tools") {
            userDefaults.set(sharedText, forKey: "sharedContent")
            userDefaults.synchronize()
            print("Shared text saved successfully: \(sharedText)")
        } else {
            print("Failed to access App Group UserDefaults")
        }

        // Notify the host that the action is complete
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    // Add additional configuration items if needed (optional)
    override func configurationItems() -> [Any]! {
        return []
    }
}

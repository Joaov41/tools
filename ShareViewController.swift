import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        return !contentText.isEmpty
    }

    override func didSelectPost() {
        guard let sharedText = self.contentText else {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        if let userDefaults = UserDefaults(suiteName: "group.red.tools") {
            userDefaults.set(sharedText, forKey: "sharedContent")
            // No synchronize call here.

            // Post a notification so when the app becomes active, it can fetch updates
            NotificationCenter.default.post(name: Notification.Name("com.red.tools.sharedContentUpdated"), object: nil)
            print("Shared text saved successfully: \(sharedText)")
        } else {
            print("Failed to access App Group UserDefaults")
        }

        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}

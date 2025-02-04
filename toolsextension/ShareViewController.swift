//
//  ShareViewController.swift
//  YourShareExtension
//
//  Created by You on 2025-01-01.
//

import UIKit
import Social
import SwiftSoup

class ShareViewController: SLComposeServiceViewController {

    // MARK: - Share Extension Entry Point

    override func isContentValid() -> Bool {
        // Always allow content; we handle different types below.
        return true
    }

    override func didSelectPost() {
        // 1. Check for JavaScript preprocessing results (provided by Safari)
        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
           let results = extensionItem.userInfo?["NSExtensionJavaScriptPreprocessingResultsKey"] as? [String: Any] {
            print("Found JavaScript preprocessing results: \(results)")
            if let urlString = results["URL"] as? String,
               let url = URL(string: urlString) {
                print("Extracted URL from JS preprocessing: \(url.absoluteString)")
                fetchHTML(from: url)
                return
            } else {
                print("No valid URL in JS preprocessing results.")
            }
        }
        
        // 2. Fallback: Check for an attachment with type public.url.
        if let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
           let attachments = extensionItem.attachments {
            for provider in attachments {
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    print("Found a provider for public.url")
                    provider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] item, error in
                        guard let self = self else { return }
                        if let error = error {
                            print("Error loading URL: \(error)")
                            self.completeExtension()
                            return
                        }
                        var validURL: URL?
                        if let urlItem = item as? URL {
                            validURL = urlItem
                        } else if let urlString = item as? String {
                            validURL = URL(string: urlString)
                        }
                        guard let url = validURL else {
                            print("No valid URL extracted from the provider.")
                            self.completeExtension()
                            return
                        }
                        print("Valid URL received from attachments: \(url.absoluteString)")
                        self.fetchHTML(from: url)
                    }
                    return
                }
            }
            print("No attachment with type public.url found in attachments.")
        }
        
        // 3. Fallback: No URL found—use the plain text from contentText.
        print("Falling back to contentText: \(contentText)")
        self.saveSharedContent(contentText)
        self.completeExtension()
    }

    // MARK: - Fetching and Parsing HTML

    /// Fetches the HTML content from the given URL, removes unwanted tags, extracts the plain text from the <body>, and saves it.
    private func fetchHTML(from url: URL) {
        print("Fetching HTML from URL: \(url.absoluteString)")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { self.completeExtension() }
            
            if let error = error {
                print("Error fetching URL: \(error)")
                return
            }
            
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("Failed to retrieve HTML content")
                return
            }
            
            print("HTML content fetched (length \(htmlString.count) characters)")
            
            do {
                // Parse the HTML using SwiftSoup.
                let document = try SwiftSoup.parse(htmlString)
                // Remove script, noscript, and style tags to avoid unwanted content.
                try document.select("script, noscript, style").remove()
                
                if let bodyElement = document.body() {
                    // Extract only the plain text.
                    let bodyText = try bodyElement.text()
                    print("Extracted body text (length \(bodyText.count) characters)")
                    self.saveSharedContent(bodyText)
                } else {
                    print("No <body> element found in the HTML.")
                }
            } catch {
                print("Error parsing HTML with SwiftSoup: \(error)")
            }
        }
        task.resume()
    }
    
    // MARK: - Saving Shared Content

    /// Saves the provided content and an updated timestamp to the shared UserDefaults, then posts a notification.
    private func saveSharedContent(_ content: String) {
        if let userDefaults = UserDefaults(suiteName: "group.red.tools") {
            userDefaults.set(content, forKey: "sharedContent")
            // Update the timestamp so the main app knows new content is available.
            let now = Date().timeIntervalSince1970
            userDefaults.set(now, forKey: "lastUpdateTimestamp")
            userDefaults.synchronize()
            // Post a notification so the main app can update its UI.
            NotificationCenter.default.post(name: Notification.Name("com.red.tools.sharedContentUpdated"), object: nil)
            print("Shared content saved: \(content)")
        } else {
            print("Failed to access shared UserDefaults (group.red.tools)")
        }
    }
    
    // MARK: - Completing the Extension Request

    /// Signals that the extension has finished its work.
    private func completeExtension() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        // No additional configuration items for this share extension.
        return []
    }
}



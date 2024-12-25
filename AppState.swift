// AppState.swift

import SwiftUI

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var geminiProvider: GeminiProvider
    @Published var customInstruction: String = ""
    @Published var selectedText: String = ""
    @Published var isProcessing: Bool = false
    @Published var showOnboarding: Bool = false
    @Published var showSettings: Bool = false
    @Published var showAbout: Bool = false
    @Published var showCustomInput: Bool = false

    // Add the following line:
    @Published var showChat: Bool = false  // <--- New line

    @Published var activeResponse: ResponseData? = nil
    @Published var sharedContent: String? = nil

    private init() {
        let apiKey = UserDefaults.standard.string(forKey: "gemini_api_key")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let modelName = UserDefaults.standard.string(forKey: "gemini_model") ?? GeminiModel.flash.rawValue

        if apiKey.isEmpty {
            print("Warning: Gemini API key is not configured.")
        }

        let config = GeminiConfig(apiKey: apiKey, modelName: modelName)
        self.geminiProvider = GeminiProvider(config: config)

        NotificationCenter.default.addObserver(self, selector: #selector(handleSharedContentUpdate), name: Notification.Name("com.red.tools.sharedContentUpdated"), object: nil)
        updateSharedContent()
    }

    func saveConfig(apiKey: String, model: GeminiModel) {
        UserDefaults.standard.setValue(apiKey, forKey: "gemini_api_key")
        UserDefaults.standard.setValue(model.rawValue, forKey: "gemini_model")

        let config = GeminiConfig(apiKey: apiKey, modelName: model.rawValue)
        geminiProvider = GeminiProvider(config: config)
    }

    @objc private func handleSharedContentUpdate() {
        updateSharedContent()
    }

    func updateSharedContent() {
        if let userDefaults = UserDefaults(suiteName: "group.red.tools") {
            let newContent = userDefaults.string(forKey: "sharedContent")
            if newContent != sharedContent {
                sharedContent = newContent
                print("AppState updated sharedContent: \(sharedContent ?? "nil")")
            }
        } else {
            print("Failed to access App Group UserDefaults in AppState.")
        }
    }
}

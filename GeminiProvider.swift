// GeminiProvider.swift (Corrected)
import Foundation

struct GeminiConfig: Codable {
    var apiKey: String
    var modelName: String
}

enum GeminiModel: String, CaseIterable {
    case flash8b = "gemini-1.5-flash-8b-latest"
    case flash = "gemini-1.5-flash-latest"
    case pro = "gemini-2.0-flash-exp"

    var displayName: String {
        switch self {
        case .flash8b: return "Gemini 1.5 Flash 8B"
        case .flash: return "Gemini 1.5 Flash"
        case .pro: return "gemini-2.0-flash"
        }
    }
}

class GeminiProvider: ObservableObject {
    @Published var isProcessing = false
    private var config: GeminiConfig

    init(config: GeminiConfig) {
        self.config = config
    }

    func processText(userPrompt: String) async throws -> String {
        guard !config.apiKey.isEmpty else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key is missing."])
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(config.modelName):generateContent?key=\(config.apiKey)") else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."])
        }

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": userPrompt]
                    ]
                ]
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: .fragmentsAllowed)

        await MainActor.run { self.isProcessing = true }
        defer { Task { await MainActor.run { self.isProcessing = false } } }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server returned an error."])
        }

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON."])
        }

        if let candidates = json["candidates"] as? [[String: Any]],
           !candidates.isEmpty,
           let content = candidates.first?["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]],
           let text = parts.first?["text"] as? String {
            return text
        }

        throw NSError(domain: "GeminiAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "No valid content in response."])
    }

    func cancel() {
        isProcessing = false
    }
}

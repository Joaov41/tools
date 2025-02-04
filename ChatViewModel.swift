// ChatViewModel.swift (NEW FILE)

import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var conversation: [Message] = []
    @Published var inputText: String = ""
    @Published var isProcessing = false

    struct Message: Identifiable {
        let id = UUID()
        let role: Role
        let text: String
    }

    enum Role {
        case user
        case assistant
    }

    func sendMessage() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // 1) Add new user message
        let userMsg = Message(role: .user, text: trimmed)
        conversation.append(userMsg)
        inputText = ""

        // 2) Build a combined prompt with all history
        let conversationContext = buildConversationContext()

        // 3) Send entire conversation to the LLM
        Task {
            do {
                isProcessing = true
                let result = try await AppState.shared.geminiProvider.processText(userPrompt: conversationContext)
                // 4) Add the assistant's reply
                let assistantMsg = Message(role: .assistant, text: result)
                conversation.append(assistantMsg)
            } catch {
                let errorMsg = Message(role: .assistant, text: "Error: \(error.localizedDescription)")
                conversation.append(errorMsg)
            }
            isProcessing = false
        }
    }

    private func buildConversationContext() -> String {
        // Builds a prompt that includes the entire conversation history
        var conversationText = ""
        for msg in conversation {
            switch msg.role {
            case .user:
                conversationText += "User: \(msg.text)\n\n"
            case .assistant:
                conversationText += "Assistant: \(msg.text)\n\n"
            }
        }

        let prompt = """
        You are a helpful AI assistant in a multi-turn conversation.
        The conversation so far:

        \(conversationText)

        Please continue the conversation. Do NOT restate the user's last question; respond directly, referencing the entire conversation.
        """

        return prompt
    }
}

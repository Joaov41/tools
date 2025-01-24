import SwiftUI
import Combine
import UIKit

final class ResponseViewModel: ObservableObject {
    @Published var content: String
    @Published var fontSize: CGFloat = 14
    @Published var showingQADialog = false
    @Published var question = ""
    @Published var isProcessingQuestion = false
    @Published var qaHistory: [(question: String, answer: String)] = []

    let selectedText: String
    let option: WritingOption
    let appState: AppState

    init(content: String, selectedText: String, option: WritingOption, appState: AppState) {
        self.content = content
        self.selectedText = selectedText
        self.option = option
        self.appState = appState
    }

    /// Regenerates the content based on the selected writing option and original text.
    func regenerateContent() async {
        do {
            let prompt = "\(option.systemPrompt)\n\n\(selectedText)"
            let result = try await appState.geminiProvider.processText(userPrompt: prompt)
            await MainActor.run {
                self.content = result
                self.qaHistory.removeAll() // Reset Q&A history on regeneration
            }
        } catch {
            print("Error regenerating content: \(error.localizedDescription)")
        }
    }

    /// Handles the Q&A process by sending the original text and the user's question to the LLM.
    func askQuestion() async {
        guard !question.isEmpty else { return }
        isProcessingQuestion = true
        defer { isProcessingQuestion = false }

        do {
            let prompt = """
            Original Text:
            \(selectedText)

            Question:
            \(question)

            Please provide a direct answer based solely on the original text above.
            """

            let result = try await appState.geminiProvider.processText(userPrompt: prompt)
            await MainActor.run {
                qaHistory.append((question: question, answer: result))
                question = ""
                showingQADialog = false
            }
        } catch {
            print("Error processing question: \(error.localizedDescription)")
        }
    }

    /// Compiles the entire conversation (original response + Q&A history) for copying to the clipboard.
    func getFullContent() -> String {
        var fullContent = "Original Response:\n\(content)\n\n"

        if !qaHistory.isEmpty {
            fullContent += "Q&A History:\n"
            for (index, qa) in qaHistory.enumerated() {
                fullContent += "\nQ\(index + 1): \(qa.question)\nA\(index + 1): \(qa.answer)\n"
            }
        }

        return fullContent
    }

    /// Copies the entire conversation to the clipboard.
    func copyToClipboard() {
        UIPasteboard.general.string = getFullContent()
        print("Content copied to clipboard.")
    }
}

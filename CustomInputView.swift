// CustomInputView.swift

import SwiftUI

struct CustomInputView: View {
    @ObservedObject var appState: AppState
    @State private var customText: String = ""
    let onCancel: () -> Void
    let onResult: (String) -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Enter Custom Instruction")
                    .font(.headline)
                
                TextField("Describe your change...", text: $customText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    // Press Enter to submit
                    .onSubmit {
                        processCustomChange()
                    }
                    .submitLabel(.send)
                
                HStack {
                    Button("Cancel", action: onCancel)
                    Button("Apply") {
                        processCustomChange()
                    }
                    .disabled(customText.isEmpty)
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Custom Instruction", displayMode: .inline)
        }
    }
    
    private func processCustomChange() {
        guard !customText.isEmpty else { return }
        appState.isProcessing = true
        
        Task {
            do {
                let prompt = """
                You are a writing assistant. Apply the user's custom changes:
                \(customText)
                
                Text:
                \(appState.selectedText)
                """
                
                let result = try await appState.geminiProvider.processText(userPrompt: prompt)
                onResult(result)
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            appState.isProcessing = false
        }
    }
}

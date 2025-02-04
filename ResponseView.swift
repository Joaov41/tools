// ResponseView.swift (Corrected to allow Enter-to-submit in Q&A)

import SwiftUI
import MarkdownUI
import UIKit

struct ResponseView: View {
    @StateObject private var viewModel: ResponseViewModel
    let onClose: () -> Void

    init(content: String, selectedText: String, option: WritingOption, onClose: @escaping () -> Void) {
        // Access the shared AppState
        let appState = AppState.shared
        _viewModel = StateObject(wrappedValue: ResponseViewModel(
            content: content,
            selectedText: selectedText,
            option: option,
            appState: appState
        ))
        self.onClose = onClose
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Original Response
                        if !viewModel.qaHistory.isEmpty {
                            Text("Original Response")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        Markdown(viewModel.content)
                            .markdownTheme(.gitHub)
                            .font(.system(size: viewModel.fontSize))
                            .padding()

                        // Q&A History
                        if !viewModel.qaHistory.isEmpty {
                            Divider()
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(viewModel.qaHistory.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Q: \(viewModel.qaHistory[index].question)")
                                            .font(.headline)
                                            .foregroundColor(.blue)

                                        Markdown(viewModel.qaHistory[index].answer)
                                            .markdownTheme(.gitHub)
                                            .font(.system(size: viewModel.fontSize))
                                    }
                                    .padding()
                                    .background(Color(UIColor.secondarySystemBackground))
                                    .cornerRadius(8)
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }

                Divider()

                HStack {
                    // Regenerate Button
                    Button(action: {
                        Task {
                            await viewModel.regenerateContent()
                        }
                    }) {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }

                    // Ask Question Button
                    Button(action: {
                        viewModel.showingQADialog = true
                    }) {
                        Label("Ask Question", systemImage: "questionmark.bubble")
                    }
                    .sheet(isPresented: $viewModel.showingQADialog) {
                        VStack(spacing: 16) {
                            Text("Ask a question about this content")
                                .font(.headline)

                            // TextField for Q&A
                            TextField("Your question...", text: $viewModel.question)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .disabled(viewModel.isProcessingQuestion)
                                // 1) Tells iOS to label the Return key as "Send"
                                .submitLabel(.send)
                                // 2) Pressing Enter calls `askQuestion()`
                                .onSubmit {
                                    Task {
                                        await viewModel.askQuestion()
                                    }
                                }

                            HStack {
                                Button("Cancel") {
                                    viewModel.showingQADialog = false
                                    viewModel.question = ""
                                }
                                .keyboardShortcut(.escape)

                                Button("Ask") {
                                    Task {
                                        await viewModel.askQuestion()
                                    }
                                }
                                .keyboardShortcut(.return)
                                .disabled(viewModel.question.isEmpty || viewModel.isProcessingQuestion)
                            }
                            .padding(.bottom)
                        }
                        .padding()
                    }

                    Spacer()

                    // Font size adjustment + Copy to Clipboard
                    HStack(spacing: 8) {
                        Button(action: {
                            viewModel.fontSize = max(10, viewModel.fontSize - 2)
                        }) {
                            Image(systemName: "minus")
                        }
                        .disabled(viewModel.fontSize <= 10)

                        Button(action: {
                            viewModel.fontSize = 14
                        }) {
                            Image(systemName: "textformat.size")
                        }

                        Button(action: {
                            viewModel.fontSize = min(24, viewModel.fontSize + 2)
                        }) {
                            Image(systemName: "plus")
                        }
                        .disabled(viewModel.fontSize >= 24)

                        Divider()
                            .frame(height: 16)

                        // Copy entire conversation
                        Button(action: {
                            viewModel.copyToClipboard()
                        }) {
                            Image(systemName: "doc.on.doc")
                        }
                        .help("Copy entire conversation to clipboard")
                    }
                }
                .padding()
            }
            .navigationTitle("\(viewModel.option.rawValue) Result")
            .navigationBarItems(
                leading: Button("Close") {
                    onClose()
                }
            )
        }
    }
}

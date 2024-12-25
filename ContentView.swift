// ContentView.swift

import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    
    // MARK: - NEW: Detect size class
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var inputText: String = ""
    @State private var selectedOption: WritingOption? = nil

    var body: some View {
        // MARK: - CHANGED: Apply a StackNavigationViewStyle for better iPhone usage
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Writing Tools (iOS)")
                    .font(.title)

                // Main Text Field:
                TextField("Enter text to process", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    // 1) Pressing Enter will call `onSubmit`
                    .onSubmit {
                        // Example: if user selected an option, process it on Enter
                        if let option = selectedOption {
                            processOption(option)
                        }
                    }
                    // 2) Label the return key as "Send"
                    .submitLabel(.send)
                    .onReceive(appState.$sharedContent) { newSharedContent in
                        if let content = newSharedContent {
                            inputText = content
                            print("Input text updated with shared content: \(content)")
                        }
                    }

                // New button to paste from clipboard
                Button("Paste from Clipboard") {
                    if let clipboardString = UIPasteboard.general.string {
                        inputText = clipboardString
                    }
                }

                // ScrollView containing the LazyVGrid:
                ScrollView {
                    // MARK: - CHANGED: Use dynamic columns based on size class
                    LazyVGrid(columns: layoutColumns, spacing: 20) {
                        // Show writing options
                        ForEach(WritingOption.allCases, id: \.self) { option in
                            Button(action: {
                                selectedOption = option
                                processOption(option)
                            }) {
                                VStack {
                                    Image(systemName: option.icon)
                                    Text(option.rawValue)
                                        .font(.footnote)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                            .disabled(inputText.isEmpty && !option.isCustomOption)
                        }

                        // “Chat” button in the same grid
                        Button(action: {
                            appState.showChat = true
                        }) {
                            VStack {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                Text("Chat")
                                    .font(.footnote)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }

                HStack {
                    Button("Settings") {
                        appState.showSettings = true
                    }
                    Button("About") {
                        appState.showAbout = true
                    }
                }

                Spacer()

                Button("Refresh Shared Content") {
                    appState.updateSharedContent()
                }
                .padding()
            }
            .navigationTitle("Tools")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appState.isProcessing {
                        ProgressView()
                    }
                }
            }
            .onAppear {
                appState.updateSharedContent()
            }
            // Listen for when the app becomes active to refresh shared content
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                appState.updateSharedContent()
            }
        }
        // MARK: - CHANGED: Force StackNavigationViewStyle to optimize phone layout
        .navigationViewStyle(StackNavigationViewStyle())
        // Show the ChatConversationView as a sheet
        .sheet(isPresented: $appState.showChat) {
            ChatConversationView()
        }
    }

    // MARK: - NEW: Computed property for dynamic layout columns
    private var layoutColumns: [GridItem] {
        if horizontalSizeClass == .compact {
            // Single column on iPhone in portrait
            return [GridItem(.flexible())]
        } else {
            // Two columns on iPad or iPhone in landscape
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    func processOption(_ option: WritingOption) {
        Task {
            if option.isCustomOption {
                appState.selectedText = inputText
                appState.showCustomInput = true
            } else {
                appState.isProcessing = true
                do {
                    let prompt = "\(option.systemPrompt)\n\n\(inputText)"
                    let result = try await appState.geminiProvider.processText(userPrompt: prompt)
                    let responseData = ResponseData(
                        title: "\(option.rawValue) Result",
                        content: result,
                        selectedText: inputText,
                        option: option
                    )
                    appState.activeResponse = responseData
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
                appState.isProcessing = false
            }
        }
    }
}

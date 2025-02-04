import SwiftUI

// Global variable for the TextField's accessibility identifier
let textEditorAccessibilityIdentifier = "mainTextField"

struct ContentView: View {
    @ObservedObject var appState: AppState
    @State private var inputText: String = ""
    @State private var selectedOption: WritingOption? = nil
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Writing Tools (iOS)")
                    .font(.title)

                // TextField with accessibility identifier
                TextField("Enter text to process", text: $inputText, axis: .vertical)
                    .id("mainTextField")
                    .accessibilityIdentifier(textEditorAccessibilityIdentifier)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        if let option = selectedOption {
                            processOption(option)
                        }
                    }
                    .submitLabel(.send)
                    // Always update inputText when new sharedContent arrives.
                    .onReceive(appState.$sharedContent) { newSharedContent in
                        if let content = newSharedContent {
                            inputText = content
                            print("Input text updated with shared content: \(content)")
                        }
                    }

                Button("Paste from Clipboard") {
                    if let clipboardString = UIPasteboard.general.string {
                        inputText = clipboardString
                    }
                }

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(WritingOption.allCases, id: \.self) { option in
                            Button {
                                selectedOption = option
                                processOption(option)
                            } label: {
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

                        Button {
                            appState.showChat = true
                        } label: {
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

                        Button {
                            appState.showImageProcessing = true
                        } label: {
                            VStack {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Analyze Image")
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

                // Manual refresh button if needed
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
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    appState.updateSharedContent()
                }
            }
            .onAppear {
                appState.updateSharedContent()
            }
        }
        // Sheets for Chat, Image Processing, Settings, About, Custom Input, and Response.
        .sheet(isPresented: $appState.showChat) {
            ChatConversationView()
        }
        .sheet(isPresented: $appState.showImageProcessing) {
            ImageProcessingView(appState: appState)
        }
        .sheet(isPresented: $appState.showSettings) {
            SettingsView(appState: appState, showOnlyApiSetup: false) {
                appState.showSettings = false
            }
        }
        .sheet(isPresented: $appState.showAbout) {
            AboutView {
                appState.showAbout = false
            }
        }
        .sheet(isPresented: $appState.showCustomInput) {
            CustomInputView(appState: appState) {
                appState.showCustomInput = false
            } onResult: { result in
                let responseData = ResponseData(
                    title: "Custom Changes",
                    content: result,
                    selectedText: appState.selectedText,
                    option: .custom
                )
                appState.showCustomInput = false
                appState.activeResponse = responseData
            }
        }
        .sheet(item: $appState.activeResponse) { responseData in
            ResponseView(
                content: responseData.content,
                selectedText: responseData.selectedText,
                option: responseData.option
            ) {
                appState.activeResponse = nil
            }
        }
    }

    func processOption(_ option: WritingOption) {
        // Determine if any text is selected.
        let selectedRange = getSelectedRange(in: textEditorAccessibilityIdentifier)
        let isTextSelected = selectedRange.length > 0

        Task {
            if option.isCustomOption {
                appState.selectedText = inputText
                appState.showCustomInput = true
            } else {
                appState.isProcessing = true
                do {
                    // Use the selected text if available; otherwise, use the full inputText.
                    let textToProcess = isTextSelected ? (inputText as NSString).substring(with: selectedRange) : inputText
                    let prompt = "\(option.systemPrompt)\n\n\(textToProcess)"
                    let result = try await appState.geminiProvider.processText(userPrompt: prompt)

                    if isTextSelected {
                        // Replace the selected text directly.
                        DispatchQueue.main.async {
                            inputText = (inputText as NSString).replacingCharacters(in: selectedRange, with: result)
                        }
                    } else {
                        // Show result in a ResponseView.
                        let responseData = ResponseData(
                            title: "\(option.rawValue) Result",
                            content: result,
                            selectedText: inputText,
                            option: option
                        )
                        appState.activeResponse = responseData
                    }
                } catch {
                    print("Error: \(error.localizedDescription)")
                }
                appState.isProcessing = false
            }
        }
    }

    // Helper function to get the selected range in the TextField.
    private func getSelectedRange(in textViewId: String) -> NSRange {
        guard let textEditor = findFirstResponder(in: UIApplication.shared.keyWindow!) as? UITextView,
              textEditor.accessibilityIdentifier == textViewId else {
            return NSRange(location: 0, length: 0)
        }
        return textEditor.selectedRange
    }

    // Helper function to recursively find the first responder.
    private func findFirstResponder(in view: UIView) -> UIView? {
        if view.isFirstResponder {
            return view
        }
        for subview in view.subviews {
            if let firstResponder = findFirstResponder(in: subview) {
                return firstResponder
            }
        }
        return nil
    }
}



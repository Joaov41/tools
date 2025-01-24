import SwiftUI

struct ContentView: View {
    @ObservedObject var appState: AppState
    
    // For adaptive layout
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @State private var inputText: String = ""
    @State private var selectedOption: WritingOption? = nil

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Writing Tools (iOS)")
                    .font(.title)
                
                // MAIN TEXT FIELD
                TextField("Enter text to process", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        if let option = selectedOption {
                            processOption(option)
                        }
                    }
                    .submitLabel(.send)
                    .onReceive(appState.$sharedContent) { newSharedContent in
                        if let content = newSharedContent {
                            inputText = content
                            print("Input text updated with shared content: \(content)")
                        }
                    }

                // PASTE FROM CLIPBOARD
                Button("Paste from Clipboard") {
                    if let clipboardString = UIPasteboard.general.string {
                        inputText = clipboardString
                    }
                }

                // BUTTON GRID
                ScrollView {
                    LazyVGrid(columns: layoutColumns, spacing: 20) {
                        // Writing options
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

                        // Chat Button
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
                        
                        // Image Analysis
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

                // FOOTER BUTTONS
                HStack {
                    Button("Settings") {
                        appState.showSettings = true
                    }
                    Button("About") {
                        appState.showAbout = true
                    }
                }

                Spacer()

                // REFRESH SHARED CONTENT
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
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                appState.updateSharedContent()
            }
        }
        // iPhone-friendly Navigation style
        .navigationViewStyle(StackNavigationViewStyle())
        
        // Present Chat & Image sheets
        .sheet(isPresented: $appState.showChat) {
            ChatConversationView()
        }
        .sheet(isPresented: $appState.showImageProcessing) {
            ImageProcessingView(appState: appState)
        }
    }

    private var layoutColumns: [GridItem] {
        // Single column in compact width (portrait iPhone),
        // two columns otherwise (e.g., iPad or landscape).
        if horizontalSizeClass == .compact {
            return [GridItem(.flexible())]
        } else {
            return [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    func processOption(_ option: WritingOption) {
        Task {
            if option.isCustomOption {
                // If the user picks the "Custom" option, open the custom input sheet
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


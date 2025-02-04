// ChatConversationView.swift (NEW FILE)

import SwiftUI

struct ChatConversationView: View {
    @StateObject private var viewModel = ChatViewModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Scrollable conversation
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.conversation) { message in
                                if message.role == .user {
                                    // User message on the right
                                    HStack {
                                        Spacer()
                                        Text(message.text)
                                            .padding(8)
                                            .background(Color.blue.opacity(0.2))
                                            .cornerRadius(8)
                                    }
                                    .id(message.id)
                                } else {
                                    // Assistant message on the left
                                    HStack {
                                        Text(message.text)
                                            .padding(8)
                                            .background(Color.gray.opacity(0.2))
                                            .cornerRadius(8)
                                        Spacer()
                                    }
                                    .id(message.id)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.conversation.count) { _ in
                        // Auto-scroll to latest
                        if let lastId = viewModel.conversation.last?.id {
                            withAnimation {
                                scrollProxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                HStack {
                    TextField("Type here...", text: $viewModel.inputText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            viewModel.sendMessage()
                        }
                        .disabled(viewModel.isProcessing)

                    Button("Send") {
                        viewModel.sendMessage()
                    }
                    .disabled(viewModel.isProcessing || viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isProcessing {
                        ProgressView()
                    }
                }
            }
        }
    }
}

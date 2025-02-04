// ImageProcessingView.swift

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ImageProcessingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @ObservedObject var appState: AppState
    
    // Focus tracking for the prompt TextField
    @FocusState private var isPromptFocused: Bool

    // Image properties
    @State private var selectedImage: UIImage? = nil
    @State private var prompt: String = ""
    @State private var result: String? = nil
    @State private var isProcessing: Bool = false
    @State private var showPasteError = false

    // Q&A
    @State private var showingQADialog = false
    @State private var question = ""
    @State private var isProcessingQuestion = false
    @State private var qaHistory: [(question: String, answer: String)] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - Image Preview or Placeholder
                    Group {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 300)
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 200)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray)
                                        Text("No image selected")
                                            .foregroundColor(.gray)
                                    }
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Paste Image Button
                    Button(action: checkAndPasteImage) {
                        Label("Paste Image", systemImage: "doc.on.clipboard")
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                    
                    // MARK: - Clear Button
                    if selectedImage != nil {
                        Button(action: {
                            selectedImage = nil
                            result = nil
                            qaHistory.removeAll()
                        }) {
                            Label("Clear", systemImage: "trash")
                                .frame(minWidth: 150)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                    
                    // MARK: - Prompt Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prompt")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Enter prompt for image analysis...", text: $prompt, axis: .vertical)
                            .focused($isPromptFocused)      // <--- Focus binding
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Analyze Image
                    Button(action: {
                        Task {
                            await analyzeImage()
                        }
                    }) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Text("Analyze Image")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedImage == nil || prompt.isEmpty || isProcessing)
                    .frame(minWidth: 200)
                    
                    // MARK: - Results
                    if let result = result {
                        VStack(alignment: .leading, spacing: 10) {
                            // If Q&A has begun, label the original result
                            if !qaHistory.isEmpty {
                                Text("Original Analysis")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text(result)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(8)
                            
                            // Copy & Ask Question
                            HStack {
                                Button(action: {
                                    UIPasteboard.general.string = result
                                }) {
                                    Label("Copy Result", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)
                                
                                Button(action: {
                                    showingQADialog = true
                                }) {
                                    Label("Ask Question", systemImage: "questionmark.bubble")
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        
                        // MARK: - Q&A History
                        if !qaHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(qaHistory.indices, id: \.self) { index in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Q: \(qaHistory[index].question)")
                                            .font(.headline)
                                            .foregroundColor(.blue)
                                        
                                        Text(qaHistory[index].answer)
                                            .padding()
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(Color(UIColor.secondarySystemBackground))
                                            .cornerRadius(8)
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
                // Tapping outside the text field dismisses the keyboard
                .onTapGesture {
                    isPromptFocused = false
                }
            }
            .navigationTitle("Image Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // Force the keyboard to dismiss if iOS tries to auto-focus
            .onAppear {
                DispatchQueue.main.async {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            }
            // Q&A Dialog
            .sheet(isPresented: $showingQADialog) {
                NavigationView {
                    VStack(spacing: 16) {
                        Text("Ask a question about this image")
                            .font(.headline)
                        
                        TextField("Your question...", text: $question)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                            .disabled(isProcessingQuestion)
                            .submitLabel(.send)
                            .onSubmit {
                                Task {
                                    await askQuestion()
                                }
                            }
                        
                        HStack {
                            Button("Cancel") {
                                showingQADialog = false
                                question = ""
                            }
                            
                            Button("Ask") {
                                Task {
                                    await askQuestion()
                                }
                            }
                            .disabled(question.isEmpty || isProcessingQuestion)
                        }
                        .padding(.bottom)
                    }
                    .padding()
                    .navigationTitle("Ask Question")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .alert("No Image Available", isPresented: $showPasteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("No image found in clipboard. Please copy an image first.")
            }
        }
    }
    
    // MARK: - Copy/Paste
    private func checkAndPasteImage() {
        if UIPasteboard.general.hasImages {
            if let image = UIPasteboard.general.image {
                selectedImage = image
                result = nil
                qaHistory.removeAll()
            } else {
                showPasteError = true
            }
        } else {
            // fallback for older pasteboards
            if let types = UIPasteboard.general.types as? [String],
               let imageType = types.first(where: { $0.starts(with: "public.image") }),
               let imageData = UIPasteboard.general.data(forPasteboardType: imageType),
               let image = UIImage(data: imageData) {
                selectedImage = image
                result = nil
                qaHistory.removeAll()
            } else {
                showPasteError = true
            }
        }
    }
    
    // MARK: - Analyze
    private func analyzeImage() async {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let response = try await appState.geminiProvider.processImageAndText(
                image: image,
                prompt: prompt
            )
            await MainActor.run {
                self.result = response
                self.qaHistory.removeAll()
            }
        } catch {
            await MainActor.run {
                self.result = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Q&A
    private func askQuestion() async {
        guard let image = selectedImage, !question.isEmpty else { return }
        
        let currentQuestion = question
        showingQADialog = false
        isProcessingQuestion = true
        
        do {
            let prompt = """
            Based on the image I shared earlier, please answer this question:
            \(currentQuestion)
            
            Please provide a direct answer based solely on what you can see in the image.
            """
            
            let response = try await appState.geminiProvider.processImageAndText(
                image: image,
                prompt: prompt
            )
            
            await MainActor.run {
                qaHistory.append((question: currentQuestion, answer: response))
                question = ""
                isProcessingQuestion = false
            }
        } catch {
            await MainActor.run {
                qaHistory.append((question: currentQuestion, answer: "Error: \(error.localizedDescription)"))
                question = ""
                isProcessingQuestion = false
            }
        }
    }
}


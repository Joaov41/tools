import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var apiKey = ""
    @State private var selectedModel = GeminiModel(rawValue: UserDefaults.standard.string(forKey: "gemini_model") ?? GeminiModel.flash.rawValue) ?? .flash
    let showOnlyApiSetup: Bool
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                if !showOnlyApiSetup {
                    Section("General Settings") {
                        Toggle("Use Gradient Theme", isOn: .constant(false))
                            .disabled(true) // Example only
                    }
                }
                
                Section("Gemini AI Settings") {
                    TextField("API Key", text: $apiKey)
                    Picker("Model", selection: $selectedModel) {
                        ForEach(GeminiModel.allCases, id: \.self) { model in
                            Text(model.displayName).tag(model)
                        }
                    }
                    Button("Get API Key") {
                        if let url = URL(string: "https://aistudio.google.com/app/apikey") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                Button(showOnlyApiSetup ? "Complete Setup" : "Save") {
                    saveSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Close") {
                onClose()
            })
            .onAppear {
                self.apiKey = UserDefaults.standard.string(forKey: "gemini_api_key") ?? ""
            }
        }
    }
    
    private func saveSettings() {
        print("saveSettings() with API Key: \(apiKey)")
        appState.saveConfig(apiKey: apiKey, model: selectedModel)
        onClose()
    }
}//
//  SettingsView.swift
//  tools
//
//  Created by john val on 12/8/24.
//


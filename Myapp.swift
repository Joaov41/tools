
// MyApp.swift

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView(appState: appState)
                .sheet(isPresented: $appState.showOnboarding) {
                    OnboardingView(appState: appState) {
                        // On finishing onboarding
                        UserDefaults.standard.set(true, forKey: "has_completed_onboarding")
                        appState.showOnboarding = false
                        appState.showSettings = true
                    }
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
                .sheet(item: $appState.activeResponse) { responseData in
                    ResponseView(content: responseData.content, selectedText: responseData.selectedText, option: responseData.option) {
                        appState.activeResponse = nil
                    }
                }
                .sheet(isPresented: $appState.showCustomInput) {
                    CustomInputView(appState: appState) {
                        appState.showCustomInput = false
                    } onResult: { result in
                        appState.activeResponse = ResponseData(
                            title: "Custom Changes",
                            content: result,
                            selectedText: appState.selectedText,
                            option: .custom
                        )
                    }
                }
                .onAppear {
                    // Show onboarding if needed
                    if !UserDefaults.standard.bool(forKey: "has_completed_onboarding") {
                        appState.showOnboarding = true
                    }
                }
        }
    }
}


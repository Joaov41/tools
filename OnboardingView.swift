import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    let onFinish: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Writing Tools!")
                    .font(.largeTitle)
                    .bold()
                
                Text("Improve your writing with AI-powered suggestions.")
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button("Next") {
                    onFinish()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationBarHidden(true)
        }
    }
}//
//  OnboardingView.swift
//  tools
//
//  Created by john val on 12/8/24.
//


// AboutView.swift

import SwiftUI

struct AboutView: View {
    let onClose: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("About Writing Tools")
                    .font(.largeTitle)
                    .bold()

                Text("A lightweight tool to improve your writing with AI on iOS.")
                    .multilineTextAlignment(.center)
                    .padding()

                Text("Port by JVal of the theJayTea/WritingTools work ") // Replace with your actual name or organization

                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button("Close") {
                onClose()
            })
        }
    }
}

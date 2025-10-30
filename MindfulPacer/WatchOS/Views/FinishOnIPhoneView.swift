//
//  FinishOnIPhoneView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 29.10.2025.
//

import SwiftUI

struct FinishOnIPhoneView: View {
    @State private var ticking = false

    var body: some View {
        VStack(spacing: 8) {
            Label("Finish Setup on iPhone", systemImage: "ipod.and.applewatch")
                .font(.headline)
                .lineLimit(2)
                .layoutPriority(1)
            
            Text("Open MindfulPacer on your iPhone and complete onboarding.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .layoutPriority(1)

            ProgressView()
        }
        .padding()
        .onAppear { ticking = true }
    }
}

#Preview {
    FinishOnIPhoneView()
}

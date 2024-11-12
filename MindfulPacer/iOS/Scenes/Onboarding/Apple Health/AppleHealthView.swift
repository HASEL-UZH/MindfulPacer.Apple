//
//  AppleHealthView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - AppleHealthView

extension OnboardingView {
    struct AppleHealthView: View {
        
        // MARK: Properties

        @Bindable var viewModel: OnboardingViewModel

        // MARK: Body

        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: "Connect to Apple Health"
            ) {
                VStack(spacing: 16) {
                    Image("Apple Health Icon Official")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)

                    Group {
                        Text("MindfulPacer can visualize your biometric data (as measured by your Apple Watch) and visualize it together with your diary entries in the Analysis page.")
                        Text("Please allow MindfulPacer to access your Apple Health data. Select the biometric data that you want to share (e.g. heart rate and/or steps).")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    InfoBox(text: "You can always change this permission later, by navigating to Settings > Privacy & Security > Health > MindfulPacer.")
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()

    OnboardingView.AppleHealthView(viewModel: viewModel)
}

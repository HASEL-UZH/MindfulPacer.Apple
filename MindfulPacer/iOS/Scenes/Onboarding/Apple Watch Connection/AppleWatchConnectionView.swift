//
//  AppleWatchConnectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - AppleWatchConnectionView

extension OnboardingView {
    struct AppleWatchConnectionView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: OnboardingViewModel
        
        // MARK: Body
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: "Connect to Your Apple Watch") {
                    VStack(spacing: 16) {
                        Image("Apple Watch")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 256)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        IconLabelGroupBox(
                            label:
                                IconLabel(
                                    icon: "info.circle",
                                    title: String(localized: "Info"),
                                    labelColor: .orange,
                                    background: true
                                ),
                            description:
                                Text("Important: Limited integration with the Apple Watch.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        ) {
                            Text(
                               """
                               Not all Apple Watch functions are available yet. Biometric data is already being retrieved from the Apple Watch, but you cannot yet receive automatic review reminders on it.
                               """
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .iconLabelGroupBoxStyle(.divider)
                        
//                        Group {
//                            Text("When pairing MindfulPacer with your Apple Watch, you can visualize your biometric data (including heart rate and steps) and receive reminders on your watch to reflect at times defined by you.")
//                            Text("MindfulPacer is automatically installed on your Apple Watch.")
//                        }
//                        .frame(maxWidth: .infinity, alignment: .leading)
//                        
//                        IconLabelGroupBox(
//                            label:
//                                IconLabel(
//                                    icon: "arrow.down.applewatch",
//                                    title: String(localized: "Installing on Apple Watch"),
//                                    labelColor: Color("BrandPrimary"),
//                                    background: true
//                                ),
//                            description:
//                                Text("Can't find MindfulPacer on your Apple Watch?")
//                                .font(.subheadline)
//                                .foregroundStyle(.secondary)
//                        ) {
//                            Text(
//                               """
//                               1. Once your Apple Watch is connected to your iPhone, open the **Watch** app.
//                               2. Go to the **My Watch** tab.
//                               3. Scroll down to see **MindfulPacer** and tap **Install**.
//                               4. Once you tapped **Install**, make sure the toggle is set to **Show App** on Apple Watch.
//                               """
//                            )
//                        }
//                        .iconLabelGroupBoxStyle(.divider)
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.AppleWatchConnectionView(viewModel: viewModel)
}

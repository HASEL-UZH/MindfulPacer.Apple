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
                        
                        Group {
                            Text("When pairing MindfulPacer with your Apple Watch, you can visualize your biometric data (including heart rate and steps) and receive reminders on your watch to reflect at times defined by you.")
                            Text("MindfulPacer is automatically installed on your Apple Watch.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        IconLabelGroupBox(
                            label:
                                IconLabel(
                                    icon: "arrow.down.applewatch",
                                    title: String(localized: "Installing on Apple Watch"),
                                    labelColor: Color("BrandPrimary"),
                                    background: true
                                ),
                            description:
                                Text("Can't find MindfulPacer on your Apple Watch?")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            Text(
                               """
                               1. Once your Apple Watch is connected to your iPhone, open the **Watch** app.
                               2. Go to the **My Watch** tab.
                               3. Scroll down to see **MindfulPacer** and tap **Install**.
                               4. Once you tapped **Install**, make sure the toggle is set to **Show App** on Apple Watch.
                               """
                            )
                        }
                        .iconLabelGroupBoxStyle(.divider)
                        
                        IconLabelGroupBox(
                            label:
                                IconLabel(
                                    icon: "applewatch",
                                    title: "MindfulPacer Screen",
                                    labelColor: Color("BrandPrimary"),
                                    background: true
                                ),
                            description:
                                Text("Ideally, the MindfulPacer home screen can always be displayed on your watch.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            Image(.appleWatchReturnToClock)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 350, alignment: .top)
                                .clipped()
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(
                                    [
                                        "Open the Watch app on your iPhone",
                                        "Go to General > Return to Clock > MindfulPacer",
                                        "Toggle 'Return to App' to on."
                                    ], id: \.self) { point in
                                        HStack(alignment: .top) {
                                            Text("•")
                                            Text(point)
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(nil)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                            }
                        }
                        .iconLabelGroupBoxStyle(.divider)
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

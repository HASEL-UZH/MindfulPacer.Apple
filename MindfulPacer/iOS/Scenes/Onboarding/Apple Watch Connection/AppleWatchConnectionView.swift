//
//  AppleWatchConnectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

extension Bundle {
    var isTestFlight: Bool {
        #if DEBUG
        return false
        #else
        return appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }
}

// MARK: - AppleWatchConnectionView

extension OnboardingView {
    struct AppleWatchConnectionView: View {
        
        // MARK: Properties
        @Bindable var viewModel: OnboardingViewModel
        
        // MARK: Body
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: "Connect to Your Apple Watch"
            ) {
                VStack(spacing: 16) {
                    if Bundle.main.isTestFlight {
                        IconLabelGroupBox(
                            label:
                                IconLabel(
                                    icon: "applewatch",
                                    title: "Installing with TestFlight",
                                    labelColor: Color("BrandPrimary"),
                                    background: true
                                ),
                            description:
                                Text("Because you installed via TestFlight, the Watch app may not auto-install MindfulPacer.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            Image(.testflightApp)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 280, alignment: .top)
                                .clipped()
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. Open **TestFlight** on your iPhone (paired with your Apple Watch).")
                                Text("2. Under **Currently Testing**, tap **MindfulPacer**.")
                                Text("3. If needed, install the iPhone app first by tapping **Install**.")
                                Text("4. On the app’s page, scroll to the **Apple Watch** section and do one of the following:")
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top, spacing: 4) {
                                        Text("•")
                                        Text("Tap **Install** / **Update** / **Open**")
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    HStack(alignment: .top, spacing: 4) {
                                        Text("•")
                                        Text("Toggle **Show App on Apple Watch** **On**")
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                Text("5. Wait for the spinner to finish; you can confirm in the **Watch** app under **My Watch → Installed on Apple Watch**.")
                            }
                        }
                        .iconLabelGroupBoxStyle(.divider)
                    } else {
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
                               When pairing MindfulPacer with your Apple Watch, you can visualize your biometric data (including heart rate and steps) and receive reminders on your watch to reflect at times defined by you.
                               MindfulPacer is automatically installed on your Apple Watch.
                               """
                            )
                            
                            Image(.appleWatch)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 256)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
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
                    }
                    
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "applewatch",
                                title: "Foreground App",
                                labelColor: Color("BrandPrimary"),
                                background: true
                            ),
                        description:
                            Text("Ideally, the MindfulPacer app can run in the foreground on your watch.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        Image(.appleWatchReturnToClock)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 350, alignment: .top)
                            .clipped()
                            .padding(.horizontal)
                        
                        Text(
                            """
                            1. Open the Watch app on your iPhone.
                            2. Go to **General > Return to Clock > MindfulPacer**.
                            3. Toggle **Return to App** to on.
                            """
                        )
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

//
//  AppleWatchConnectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - Bundle+Ext

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
                                Text(
                                    """
                                    1. Open **TestFlight** on your iPhone (paired with your Apple Watch).
                                    2. Under **Currently Testing**, tap **MindfulPacer**.
                                    3. If needed, install the iPhone app first by tapping **Install**.
                                    4. On the app’s page, scroll to the **Apple Watch** section and do one of the following:
                                        • Tap **Install** / **Update** / **Open**
                                        • Toggle **Show App on Apple Watch** **On**
                                    5. Wait for the spinner to finish; you can confirm in the **Watch** app under **My Watch → Installed on Apple Watch**.
                                    """
                                )
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
                            VStack(spacing: 16) {
                                Text(
                                   """
                                   When pairing MindfulPacer with your Apple Watch, you can visualize your biometric data (including heart rate and steps) and receive reminders on your watch to reflect at times defined by you.
                                   MindfulPacer is automatically installed on your Apple Watch.
                                   """
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .iconLabelGroupBoxStyle(.divider)
                    }
                    
                    IconLabelGroupBox(
                        label: IconLabel(
                            icon: "square.on.square.intersection.dashed",
                            title: "Add to Your Watch Face",
                            labelColor: Color("BrandPrimary"),
                            background: true
                        ),
                        description: Text("See your monitoring status at a glance with a Complication.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        VStack(spacing: 16) {
                            Text("Add our status complication to your favorite watch face to instantly see if monitoring is active or inactive.")
                            
                                VStack(alignment: .leading, spacing: 16) {
                                    Picker(selection: $viewModel.selectedAppleWatchComplicationTyoe) {
                                        ForEach(AppleWatchComplicationType.allCases, id: \.rawValue) { complicationType in
                                            Label(complicationType.rawValue.capitalized, systemImage: complicationType.icon)
                                                .tag(complicationType)
                                        }
                                    } label: {
                                        Label(viewModel.selectedAppleWatchComplicationTyoe.rawValue, systemImage: viewModel.selectedAppleWatchComplicationTyoe.icon)
                                    }
                                    .pickerStyle(.segmented)
                                    .tint(.accent)
                                    
                                    Image(viewModel.selectedAppleWatchComplicationTyoe.image)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 256)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                }
                            
                            Text(
                                """
                                1. **Long-press** on your watch face and tap **Edit**.
                                2. Swipe left to the **Complications** screen.
                                3. Tap a slot, then scroll to **MindfulPacer** and select **Monitoring Status**.
                                """
                            )
                        }
                    }
                    .iconLabelGroupBoxStyle(.divider)
                    
                    IconLabelGroupBox(
                        label: IconLabel(
                            icon: "arrow.turn.up.forward.iphone",
                            title: "Stay in the App",
                            labelColor: Color("BrandPrimary"),
                            background: true
                        ),
                        description: Text("Choose to keep MindfulPacer open during a session.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        VStack(spacing: 16) {
                            Text("By default, the watch returns to the clock. For an immersive experience, you can have it always return to our app when monitoring is active.")
                            
                            CroppedIPhoneImage(
                                Image(.appleWatchReturnToClock),
                                heightRatio: 1,
                                fill: true
                            )
                            
                            Text(
                                """
                                1. Open the **Watch** app on your iPhone.
                                2. Scroll down and tap on **MindfulPacer**.
                                3. Under **Return to App**, make sure the toggle is **ON**.
                                """
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
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

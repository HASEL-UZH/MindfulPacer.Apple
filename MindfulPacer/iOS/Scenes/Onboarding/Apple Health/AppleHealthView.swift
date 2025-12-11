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
                title: String(localized: "Connect to Apple Health"),
                showSkipButton: false
            ) {
                VStack(spacing: 16) {
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                image: "Apple Health",
                                title: String(localized: "Apple Health Integration"),
                                labelColor: Color("BrandPrimary"),
                                background: true
                            )
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            CroppedIPhoneImage(
                                Image(.appleHealthPermission),
                                heightRatio: 0.8,
                                fill: true
                            )
                            .padding()
                            
                            Text(
                            """
                            MindfulPacer can visualize your biometric data (as measured by your Apple Watch) and visualize it together with your diary entries in the Analysis page.
                            
                            Please allow MindfulPacer to access your Apple Health data. Select the biometric data that you want to share (e.g. heart rate and/or steps).
                            """
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } footer: {
                        IconLabel(
                            icon: "info.circle.fill",
                            title: String(localized: "You can always change this permission later, by navigating to Settings > Privacy & Security > Health > MindfulPacer."),
                            labelColor: .secondary
                        )
                        .font(.footnote)
                    }
                    .iconLabelGroupBoxStyle(.divider)
                    
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "hand.raised.fill",
                                title: String(localized: "Correct Permissions"),
                                labelColor: Color("BrandPrimary"),
                                background: true
                            )
                    ) {
                        VStack(alignment: .leading, spacing: 16) {
                            CroppedIPhoneImage(
                                Image(viewModel.imageNameForPermissions),
                                heightRatio: 1,
                                alignment: .center,
                                fill: true
                            )
                            .padding()
                            
                            Text(viewModel.descriptionForPermissions)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } footer: {
                        IconLabel(
                            icon: "info.circle.fill",
                            title: String(localized: "You can always change this permission later, by navigating to Settings > Privacy & Security > Health > MindfulPacer."),
                            labelColor: .secondary
                        )
                        .font(.footnote)
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
    
    OnboardingView.AppleHealthView(viewModel: viewModel)
}

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
                title: String(localized: "Connect to Apple Health")
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Label(title: {
                                Text("Apple Health Integration")
                            }, icon: {
                                Image(.appleHealthIconOfficial)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .padding(4)
                                    .background {
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.black.opacity(0.1))
                                    }
                            })
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .layoutPriority(1)
                        }
                        .padding()
                        
                        Divider()
                        
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
                        .padding()
                    }
                    
                    Divider()
                    
                    IconLabel(
                        icon: "info.circle.fill",
                        title: String(localized: "You can always change this permission later, by navigating to Settings > Privacy & Security > Health > MindfulPacer."),
                        labelColor: .secondary
                    )
                    .font(.subheadline)
                    .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
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

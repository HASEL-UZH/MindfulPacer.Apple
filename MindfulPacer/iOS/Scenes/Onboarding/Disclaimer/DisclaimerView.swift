//
//  DisclaimerView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - DisclaimerView

extension OnboardingView {
    struct DisclaimerView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: OnboardingViewModel
        
        // MARK: Body
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: String(localized: "Disclaimer"),
                showSkipButton: false
            ) {
                VStack(spacing: 16) {
                    IconLabelGroupBox(label:
                                        IconLabel(
                                            icon: "hand.raised",
                                            title: String(localized: "Warnings"),
                                            labelColor: .yellow,
                                            background: true
                                        )
                    ) {
                        Text(
                            """
                            MindfulPacer as well as the Apple Watch are **NOT** medical grade apps and may display inaccurate data.
                            
                            MindfulPacer only processes raw data from your Apple Watch and your diary entries, and does **NOT** make automated recommendations.
                            
                            Do **NOT** solely rely on MindfulPacer for pacing and managing your activities and energy.
                            
                            When in doubt, please contact an experienced physician, personal trainer or other qualified professional.
                            """
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } footer: {
                        Card(backgroundColor: Color(.tertiarySystemFill)) {
                            ZStack {
                                Label {
                                    Text("You can reach out to the following email address in case you have further questions: support@mindfulpacer.ch")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .tint(Color("BrandPrimary"))
                                } icon: {
                                    Icon(name: "envelope", color: .secondary)
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
    
    OnboardingView.DisclaimerView(viewModel: viewModel)
}

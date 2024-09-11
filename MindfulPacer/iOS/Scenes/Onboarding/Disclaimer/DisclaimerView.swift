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
                title: "Disclaimer",
                showSkipButton: false
            ) {
                VStack(spacing: 16) {
                    Image(systemName: "hand.raised.square.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)
                        .foregroundStyle(Color("BrandPrimary"))
                        .symbolRenderingMode(.hierarchical)
                    
                    IconLabelGroupBox(label:
                                        IconLabel(
                                            icon: "exclamationmark.triangle",
                                            title: "Warnings",
                                            labelColor: .yellow
                                        )
                    ) {
                        Group {
                            Text("MindfulPacer as well as the Apple Watch are **NOT** medical grade apps and may display inaccurate data.")
                            Text("MindfulPacer only processes raw data from your Apple Watch and your diary entries, and does **NOT** make automated recommendations.")
                            Text("Do **NOT** solely rely on MindfulPacer for pacing and managing your activities and energy.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline)
                    }
                    
                    Text("When in doubt, please contact an experienced physician, personal trainer or other qualified professional.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Card(backgroundColor: Color(.tertiarySystemFill)) {
                        ZStack {
                            Label {
                                Text("You can reach out to the following email address in case you have further questions: mindfulpacer@outlook.com")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.subheadline)
                                    .tint(Color("BrandPrimary"))
                            } icon: {
                                Icon(name: "envelope.circle", color: .secondary)
                            }
                        }
                    }
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

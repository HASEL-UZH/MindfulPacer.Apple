//
//  NotificationsView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - NotificationsView

extension OnboardingView {
    struct NotificationsView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: OnboardingViewModel
        
        // MARK: Body
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: String(localized: "Receive Reminders for Reflection")) {
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "bell",
                                title: "Notifications",
                                labelColor: Color("BrandPrimary"),
                                background: true
                            )
                    ) {
                        Text("MindfulPacer can remind you to reflect on your activities, energy management, moods and symptoms, for example at specific times or when a biometric value (such as your heart rate or steps) reaches a certain threshold.")
                    } footer: {
                        IconLabel(
                            icon: "info.circle.fill",
                            title: String(localized: "You can always change this permission later, by navigating to Settings > Notifications > MindfulPacer."),
                            labelColor: .secondary
                        )
                        .font(.footnote)
                    }
                }
                .iconLabelGroupBoxStyle(.divider)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.NotificationsView(viewModel: viewModel)
}

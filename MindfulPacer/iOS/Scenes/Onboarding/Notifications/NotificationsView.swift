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
                title: "Receive Reminders for Reflection") {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.square.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 128, height: 128)
                            .foregroundStyle(Color("BrandPrimary"))
                            .symbolRenderingMode(.hierarchical)
                        
                        Group {
                            Text("MindfulPacer can remind you to reflect on your activities, energy management, moods and symptoms, for example at specific times or when a biometric value (such as your heart rate or steps) reaches a certain threshold.")
                            
                            Text("Please allow MindfulPacer to send notifications to receive the reflection reminders.")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        InfoBox(text: "You can always change this permission later, by navigating to Settings > Privacy & Security > Notifications > MindfulPacer.")
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.NotificationsView(viewModel: viewModel)
}

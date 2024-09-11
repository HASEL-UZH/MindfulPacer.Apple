//
//  ActivityPromotingFeaturesView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - ActivityPromotingFeaturesView

extension OnboardingView {
    struct ActivityPromotingFeaturesView: View {
        // MARK: Properties
        
        @Bindable var viewModel: OnboardingViewModel
        
        // MARK: Body
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: "Disable Activity Promoting Features"
            ) {
                VStack(spacing: 16) {
                    Image(systemName: "square.slash.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 128, height: 128)
                        .foregroundStyle(Color("BrandPrimary"))
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Apple has many activity-promoting features on the iPhone and Apple Watch. We will guide you through the process of disabling these.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "figure.stand",
                                title: "Disabling Stand Reminders",
                                labelColor: Color("BrandPrimary")
                            )
                    ) {
                        Group {
                            Text("1. Open the Watch app on your iPhone.")
                            Text("2. Tap on 'My Watch' at the bottom.")
                            Text("3. Scroll down and tap on 'Activity'.")
                            Text("4. Toggle off 'Stand Reminders'.")
                        }
                        .font(.subheadline)
                    }
                    
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "bell.badge",
                                title: "Disabling Activity Reminders",
                                labelColor: Color("BrandPrimary")
                            )
                    ) {
                        Group {
                            Text("1. Open the Watch app on your iPhone.")
                            Text("2. Tap on 'My Watch'.")
                            Text("3. Tap on 'Notifications'.")
                            Text("4. Select 'Activity'.")
                            Text("5. Toggle off 'Activity Reminders'.")
                        }
                        .font(.subheadline)
                    }
                    
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "figure.pool.swim",
                                title: "Disabling Exercise Notifications",
                                labelColor: Color("BrandPrimary")
                            )
                    ) {
                        Group {
                            Text("1. Open the Watch app on your iPhone.")
                            Text("2. Tap on 'My Watch'.")
                            Text("3. Tap on 'Notifications'.")
                            Text("4. Select 'Activity'.")
                            Text("5. Toggle off 'Workout Reminders'.")
                        }
                        .font(.subheadline)
                    }
                    
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "figure.walk",
                                title: "Adjust Move Goals",
                                labelColor: Color("BrandPrimary")
                            )
                    ) {
                        Group {
                            Text("1. Open the Activity app on your Apple Watch.")
                            Text("2. Firmly press the display.")
                            Text("3. Tap 'Change Move Goal'.")
                            Text("4. Adjust the goal to a level that suits your current capabilities.")
                        }
                        .font(.subheadline)
                    }
                    
                    IconLabelGroupBox(
                        label:
                            IconLabel(
                                icon: "aqi.low",
                                title: "Disabling Breathe Reminders",
                                labelColor: Color("BrandPrimary")
                            )
                    ) {
                        Group {
                            Text("1. Open the Activity app on your Apple Watch.")
                            Text("2. Firmly press the display.")
                            Text("3. Tap 'Change Move Goal'.")
                            Text("4. Adjust the goal to a level that suits your current capabilities.")
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.ActivityPromotingFeaturesView(viewModel: viewModel)
}

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

                    ForEach(viewModel.activityPromotingFeatures, id: \.title) { feature in
                        IconLabelGroupBox(
                            label:
                                IconLabel(
                                    icon: feature.icon,
                                    title: feature.title,
                                    labelColor: Color("BrandPrimary")
                                )
                        ) {
                            Text(feature.steps)
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

    OnboardingView.ActivityPromotingFeaturesView(viewModel: viewModel)
}

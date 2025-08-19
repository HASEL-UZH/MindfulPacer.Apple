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
                title: String(localized: "Disable Activity Promoting Features")
            ) {
                IconLabelGroupBox(
                    label:
                        IconLabel(
                            icon: "square.slash",
                            title: "Instructions to Disable Features",
                            labelColor: Color("BrandPrimary"),
                            background: true
                        ),
                    description:
                        Text("Apple has many activity-promoting features on the iPhone and Apple Watch. If you want to disable these features, follow these steps.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 16) {
                            ForEach(viewModel.activityPromotingFeatures, id: \.title) { feature in
                                Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                                    VStack(alignment: .leading, spacing: 16) {
                                        IconLabel(
                                            icon: feature.icon,
                                            title: feature.title,
                                            labelColor: .brandPrimary,
                                            background: true
                                        )
                                        .font(.subheadline.weight(.semibold))
                                        
                                        Text(feature.steps)
                                    }
                                }
                                .frame(width: 300)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)
                }
                .iconLabelGroupBoxStyle(.divider)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.ActivityPromotingFeaturesView(viewModel: viewModel)
}

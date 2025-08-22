//
//  MainFeaturesView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - MainFeaturesView

extension OnboardingView {
    struct MainFeaturesView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: OnboardingViewModel
        
        // MARK: Body
        
        var body: some View {
            OnboardingPage(
                viewModel: viewModel,
                title: String(localized: "Main Features")
            ) {
                VStack(spacing: 16) {
                    ForEach(viewModel.mainFeatures, id: \.title) { feature in
                        IconLabelGroupBox(
                            label:
                                IconLabel(
                                    icon: feature.icon,
                                    title: feature.title,
                                    labelColor: Color("BrandPrimary"),
                                    background: true
                                ),
                            description:
                                Text(feature.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        ) {
                            Image(feature.image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 350, alignment: .top)
                                .clipped()
                            
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(feature.points, id: \.self) { point in
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text(point)
                                            .multilineTextAlignment(.leading)
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }
                }
                .iconLabelGroupBoxStyle(.divider)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()
    
    OnboardingView.MainFeaturesView(viewModel: viewModel)
}

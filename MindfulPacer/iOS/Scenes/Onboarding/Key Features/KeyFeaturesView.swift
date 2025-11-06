//
//  KeyFeaturesView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import SwiftUI

// MARK: - KeyFeaturesView

extension OnboardingView {
    struct KeyFeaturesView: View {
        
        // MARK: Properties

        @Bindable var viewModel: OnboardingViewModel

        // MARK: Body

        var body: some View {
            VStack(spacing: 32) {
                VStack(spacing: 4) {
                    Image("MindfulPacer Icon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                    Text("MindfulPacer")
                        .font(.largeTitle.bold())
                        .foregroundStyle(LinearGradient(colors: [Color("BrandPrimary")], startPoint: .topLeading, endPoint: .bottomTrailing))
                }
                .padding(.top, 64)
                
                VStack(spacing: 32) {
                    ForEach(viewModel.keyFeatures, id: \.title) { feature in
                        keyFeatureItem(
                            icon: feature.icon,
                            title: feature.title,
                            description: feature.description
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .safeAreaPadding(.bottom, viewModel.actionButtonHeight)
        }

        // MARK: Key Feature Item

        @ViewBuilder
        private func keyFeatureItem(icon: String, title: String, description: String) -> some View {
            HStack(spacing: 24) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.brandPrimary)
                    .symbolRenderingMode(.hierarchical)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).fontWeight(.semibold)
                    Text(description).font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: OnboardingViewModel = ScenesContainer.shared.onboardingViewModel()

    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        OnboardingView.KeyFeaturesView(viewModel: viewModel)
    }
}

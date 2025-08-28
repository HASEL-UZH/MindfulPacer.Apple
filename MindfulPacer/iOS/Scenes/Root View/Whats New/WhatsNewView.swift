//
//  WhatsNewView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2025.
//

import SwiftUI

// MARK: - WhatsNewView

struct WhatsNewView: View {

    // MARK: Properties
    
    @Bindable var viewModel: RootViewModel
    var onContinue: () -> Void

    // MARK: Body
    
    var body: some View {
        VStack(spacing: 32) {
            Group {
                Text("What's New in ")
                + Text("MindfulPacer ")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.brandPrimary,
                                Color.brandPrimary.opacity(0.6),
                                Color.brandPrimary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                + Text("🎉")
            }
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .padding(.top, 64)

            VStack(spacing: 32) {
                ForEach(viewModel.whatsNewFeatures) { feature in
                    whatsNewFeature(feature)
                }
            }
            .padding([.horizontal, .top])

            Spacer()

            PrimaryButton(title: String(localized: "Continue")) {
                onContinue()
            }
            .padding(.horizontal)
        }
        .background(Color(.systemGroupedBackground))
        .frame(maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func whatsNewFeature(_ feature: NewFeature) -> some View {
        HStack(spacing: 24) {
            Image(systemName: feature.icon)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32)
                .foregroundStyle(feature.color)
                .symbolRenderingMode(.hierarchical)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title).fontWeight(.semibold)
                Text(feature.description).font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    let viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()

    WhatsNewView(
        viewModel: viewModel,
        onContinue: { }
    )
}

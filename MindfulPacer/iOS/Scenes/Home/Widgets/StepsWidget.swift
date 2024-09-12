//
//  StepsWidgetView.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - StepsWidget

extension HomeView {
    struct StepsWidget: View {
        // MARK: Properties

        @Bindable var viewModel: HomeViewModel

        // MARK: Body

        var body: some View {
            NavigationLink(value: HomeViewNavigationDestination.reviewsList) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "figure.walk",
                        title: "Steps",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
                ) {
                    stepsSummary
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(.primary)
        }

        // MARK: Steps Summary

        private var stepsSummary: some View {
            if let currentSteps = viewModel.currentSteps {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(Int(currentSteps.stepCount))")
                        .font(.title.weight(.semibold))
                    Text("steps")
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(alignment: .center, spacing: 4) {
                    Text("--")
                        .font(.title.weight(.semibold))
                    Text("steps")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    HomeView.StepsWidget(viewModel: viewModel)
}

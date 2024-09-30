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
            IconLabelGroupBox(
                label: IconLabel(
                    icon: "figure.walk",
                    title: "Steps",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
            ) {
                stepsSummary
            }
        }

        // MARK: Steps Summary

        @ViewBuilder
        private var stepsSummary: some View {
            if let currentSteps = viewModel.currentSteps {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(currentSteps.stepCount))")
                            .font(.title.weight(.semibold))
                        Text("steps")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("**Updated:** \(currentSteps.timestamp.formatted(.dateTime.hour().minute()))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 4) {
                        Text("--")
                            .font(.title.weight(.semibold))
                        Text("steps")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("No data")
                        .font(.footnote)
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

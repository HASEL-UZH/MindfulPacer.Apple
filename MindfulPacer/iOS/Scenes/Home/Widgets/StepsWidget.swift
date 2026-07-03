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
            LabeledCard {
                stepsSummary
                    .foregroundStyle(Color.primary)
            } label: {
                Label("Steps", systemImage: "figure.walk")
                    .foregroundStyle(.teal)
            }
        }
        
        // MARK: Steps Summary
        
        @ViewBuilder
        private var stepsSummary: some View {
            if let currentSteps = viewModel.currentSteps {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Int(currentSteps.stepCount).formatted())
                        .font(.title.weight(.semibold))
                        .monospacedDigit()
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)
                    
                    Text("Updated \(currentSteps.timestamp.formatted(.dateTime.hour().minute()))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("--")
                        .font(.title.weight(.semibold))
                    
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

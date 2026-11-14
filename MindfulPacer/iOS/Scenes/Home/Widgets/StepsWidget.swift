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
            HealthMetricCard(
                title: String(localized: "Steps"),
                systemImage: "figure.walk",
                tint: .teal,
                value: viewModel.currentSteps.map { Int($0.stepCount).formatted() },
                unit: String(localized: "steps"),
                timestamp: viewModel.currentSteps?.timestamp
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.StepsWidget(viewModel: viewModel)
}

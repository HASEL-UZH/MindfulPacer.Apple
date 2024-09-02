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
        @Bindable var viewModel: HomeViewModel
        
        var body: some View {
            NavigationLink(value: Int()) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "figure.walk",
                        title: "Steps",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
                ) {
                    if let currentSteps = viewModel.currentSteps {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(currentSteps)")
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
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.StepsWidget(viewModel: viewModel)
}

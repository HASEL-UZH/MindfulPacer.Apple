//
//  HeartRateWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - HeartRateWidget

extension HomeView {
    struct HeartRateWidget: View {
        // MARK: Properties
        
        @Bindable var viewModel: HomeViewModel

        // MARK: Body

        var body: some View {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
            ) {
                heartRateSummary
                    .foregroundStyle(Color.primary)
            }
        }
        
        // MARK: Heart Rate Summary

        @ViewBuilder
        private var heartRateSummary: some View {
            if let currentHeartRate = viewModel.currentHeartRate {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(Int(currentHeartRate.heartRate))")
                            .font(.title.weight(.semibold))
                            .lineLimit(1)
                        Text("bpm")
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("**Updated:** \(currentHeartRate.timestamp.formatted(.dateTime.hour().minute()))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 4) {
                        Text("--")
                            .font(.title.weight(.semibold))
                        Text("bpm")
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

    HomeView.HeartRateWidget(viewModel: viewModel)
}

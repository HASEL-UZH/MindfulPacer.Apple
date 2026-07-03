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
            LabeledCard {
                heartRateSummary
                    .foregroundStyle(Color.primary)
            } label: {
                Label("Heart Rate", systemImage: "heart.fill")
                    .foregroundStyle(.pink)
            }
        }
        
        // MARK: Heart Rate Summary

        @ViewBuilder
        private var heartRateSummary: some View {
            if let currentHeartRate = viewModel.currentHeartRate {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(Int(currentHeartRate.heartRate))")
                        .font(.title.weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .unit("bpm")
                    
                    Text("Updated \(currentHeartRate.timestamp.formatted(.dateTime.hour().minute()))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("--")
                        .font(.title.weight(.semibold))
                        .unit("bpm")
                    
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

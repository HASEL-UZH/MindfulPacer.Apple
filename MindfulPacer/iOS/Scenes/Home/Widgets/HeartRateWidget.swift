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
        // MARK: Body

        var body: some View {
            NavigationLink(value: Int()) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
                ) {
                    heartRateSummary
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .foregroundStyle(.primary)
        }

        // MARK: Heart Rate Summary

        @ViewBuilder
        private var heartRateSummary: some View {
            if let heartRate = getHeartRate() { // TODO: Replace with actual heart rate retrieval
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(heartRate)")
                        .font(.title.weight(.semibold))
                    Text("bpm")
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
                    
                    Text("No Data")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }

        // MARK: - Mock Heart Rate Method

        private func getHeartRate() -> Int? {
            // TODO: Implement actual heart rate logic
            return nil
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView.HeartRateWidget()
}

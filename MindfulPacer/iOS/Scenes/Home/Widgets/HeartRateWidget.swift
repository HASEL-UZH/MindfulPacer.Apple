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
            HealthMetricCard(
                title: String(localized: "Heart Rate"),
                systemImage: "heart.fill",
                tint: .pink,
                value: viewModel.currentHeartRate.map { String(Int($0.heartRate)) },
                unit: "BPM",
                timestamp: viewModel.currentHeartRate?.timestamp
            )
        }
    }

    // MARK: - Health Metric Card

    struct HealthMetricCard: View {
        let title: String
        let systemImage: String
        let tint: Color
        let value: String?
        let unit: String
        let timestamp: Date?

        var body: some View {
            LabeledCard(
                contentSpacing: 18,
                contentPadding: 14,
                cornerRadius: 22
            ) {
                metricContent
            } label: {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: systemImage)
                }
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            } accessory: {
                HStack(spacing: 4) {
                    Text(timestampText)
                        .font(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
            }
        }

        private var timestampText: String {
            guard let timestamp else { return "--" }
            return timestamp.formatted(.dateTime.hour().minute())
        }

        private var metricContent: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("Latest")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.secondary)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value ?? "--")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)

                    Text(unit)
                        .font(.caption.weight(.bold))
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

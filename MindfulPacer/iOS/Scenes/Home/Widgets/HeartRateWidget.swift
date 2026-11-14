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
            LabeledCard(contentSpacing: 10) {
                metricContent
            } label: {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: systemImage)
                }
                .foregroundStyle(tint)
            } accessory: {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }

        private var timestampText: String {
            guard let timestamp else { return "--" }
            return timestamp.formatted(.dateTime.hour().minute())
        }

        private var metricContent: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value ?? "--")
                        .font(.title.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(unit)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                }

                Text(timestamp == nil ? String(localized: "No recent data") : timestampText)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    HomeView.HeartRateWidget(viewModel: viewModel)
}

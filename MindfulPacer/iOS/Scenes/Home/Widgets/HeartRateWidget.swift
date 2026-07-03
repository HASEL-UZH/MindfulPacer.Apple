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
            VStack(alignment: .leading, spacing: 46) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Label {
                        Text(title)
                    } icon: {
                        Image(systemName: systemImage)
                    }
                    .labelIconToTitleSpacing(8)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(tint)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                    Spacer(minLength: 8)

                    HStack(spacing: 8) {
                        Text(timestampText)
                            .font(.title3)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)

                        Image(systemName: "chevron.right")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color(.systemGray3))
                    }
                }

                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latest")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.secondary)

                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text(value ?? "--")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)

                            Text(unit)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer(minLength: 12)

                    HealthMetricSparkline(tint: tint)
                        .frame(width: 90, height: 56)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
            .containerShape(.rect(cornerRadius: 24, style: .continuous))
        }

        private var timestampText: String {
            guard let timestamp else { return "--" }
            return timestamp.formatted(.dateTime.hour().minute())
        }
    }

    struct HealthMetricSparkline: View {
        let tint: Color

        private let barHeights: [CGFloat] = [18, 22, 20, 16, 28, 50, 8, 56, 38, 34, 6]

        var body: some View {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                    Capsule()
                        .fill(index == barHeights.count - 1 ? tint : Color(.systemGray5))
                        .frame(width: 7, height: height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    HomeView.HeartRateWidget(viewModel: viewModel)
}

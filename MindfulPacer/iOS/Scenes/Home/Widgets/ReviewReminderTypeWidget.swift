//
//  ReviewReminderTypeWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - ReviewReminderTypeWidget

extension HomeView {
    struct ReviewReminderTypeWidget: View {
        // MARK: Body

        var body: some View {
            IconLabelGroupBox(
                label:
                    IconLabel(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Threshold Exceeded",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                description:
                    Text("Summary of number of review reminders triggered, by review reminder type.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            ) {
                HStack(spacing: 16) {
                    ForEach(ReviewReminder.ReviewReminderType.allCases, id: \.self) { reviewReminderType in
                        HStack(spacing: 16) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("0")
                                    .font(.title.weight(.semibold))

                                Text(reviewReminderType.rawValue.lowercased())
                                    .foregroundStyle(reviewReminderType.color)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        HomeView.ReviewReminderTypeWidget()
            .padding()
    }
}

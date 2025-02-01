//
//  ReminderTypeWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - ReminderTypeWidget

extension HomeView {
    struct ReminderTypeWidget: View {
        
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
                    Text("Summary of number of reflection reminders triggered, by reflection reminder type.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            ) {
                HStack(spacing: 16) {
                    ForEach(Reminder.ReminderType.allCases, id: \.self) { reminderType in
                        HStack(spacing: 16) {
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("0")
                                    .font(.title.weight(.semibold))

                                Text(reminderType.rawValue.lowercased())
                                    .foregroundStyle(reminderType.color)
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

        HomeView.ReminderTypeWidget()
            .padding()
    }
}

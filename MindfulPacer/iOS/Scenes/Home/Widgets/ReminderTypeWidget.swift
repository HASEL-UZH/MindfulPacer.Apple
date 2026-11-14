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
            LabeledCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Summary of number of Reminders triggered, by Reminder type.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 16) {
                        ForEach(Reminder.ReminderType.allCases, id: \.self) { reminderType in
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text("0")
                                    .font(.title.weight(.semibold))
                                    .monospacedDigit()

                                Text(reminderType.rawValue.lowercased())
                                    .foregroundStyle(reminderType.color)
                            }
                        }
                    }
                }
            } label: {
                Label("Threshold Exceeded", systemImage: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(Color("BrandPrimary"))
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

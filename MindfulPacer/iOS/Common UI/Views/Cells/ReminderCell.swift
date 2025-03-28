//
//  ReminderCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import SwiftUI

// MARK: - ReminderCell

struct ReminderCell: View {
    
    // MARK: Properties

    var reminder: Reminder
    var backgroundColor: Color = Color(.secondarySystemGroupedBackground)
    var onTap: () -> Void

    // MARK: Body

    var body: some View {
        Button {
            onTap()
        } label: {
            cellContent
                .padding()
                .background(backgroundColor)
        }
    }

    // MARK: Cell Content

    private var cellContent: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                IconLabel(
                    icon: reminder.measurementType.icon,
                    title: reminder.measurementType.localized,
                    labelColor: reminder.measurementType == .heartRate ? .pink : .teal
                )
                .font(.subheadline.weight(.semibold))

                Text(reminder.triggerSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Icon(
                name: "alarm",
                color: reminder.reminderType.color,
                background: true
            )
        }
        .foregroundStyle(Color.primary)
    }
}

// MARK: - Preview

#Preview {
    RoundedList {
        ReminderCell(reminder: Reminder()) {}
    }
}

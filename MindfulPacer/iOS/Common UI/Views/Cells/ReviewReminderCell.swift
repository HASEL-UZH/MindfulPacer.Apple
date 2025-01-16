//
//  ReviewReminderCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import SwiftUI

// MARK: - ReviewReminderCell

struct ReviewReminderCell: View {
    
    // MARK: Properties

    var reviewReminder: ReviewReminder
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
                    icon: reviewReminder.measurementType.icon,
                    title: reviewReminder.measurementType.rawValue,
                    labelColor: reviewReminder.measurementType == .heartRate ? .pink : .teal
                )
                .font(.subheadline.weight(.semibold))

                Text(reviewReminder.triggerSummary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Icon(
                name: "alarm",
                color: reviewReminder.reviewReminderType.color,
                background: true
            )
        }
        .foregroundStyle(Color.primary)
    }
}

// MARK: - Preview

#Preview {
    RoundedList {
        ReviewReminderCell(reviewReminder: ReviewReminder()) {}
    }
}

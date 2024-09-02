//
//  ReviewReminderCell.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import SwiftUI

// MARK: - ReviewReminderCell

struct ReviewReminderCell: View {
    var reviewReminder: ReviewReminder
    var withBackground: Bool = true
    var onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    IconLabel(
                        icon: reviewReminder.measurementType.icon,
                        title: reviewReminder.measurementType.rawValue,
                        labelColor: reviewReminder.measurementType == .heartRate ? .pink : .teal
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    Text("Above \(reviewReminder.threshold) \(reviewReminder.measurementType == .heartRate ? "bpm" : "steps") for \(reviewReminder.interval.rawValue.lowercased())")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Icon(
                    name: "alarm",
                    color: reviewReminder.alarmType.color,
                    background: true
                )
            }
            .padding(withBackground ? .all : [])
            .foregroundStyle(Color.primary)
            .background {
                if withBackground {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
                }
            }
        }

    }
}

// MARK: - Preview

#Preview {
    ReviewReminderCell(reviewReminder: ReviewReminder()) {}
}

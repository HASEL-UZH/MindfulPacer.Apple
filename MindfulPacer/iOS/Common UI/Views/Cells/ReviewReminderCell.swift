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
    
    // MARK: Body
    
    var body: some View {
        Button {
            onTap()
        } label: {
            if withBackground {
                Card {
                    cardContent
                }
            } else {
                cardContent
            }
        }
    }
    
    // MARK: Card Content
    
    private var cardContent: some View {
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
                color: reviewReminder.reviewReminderType.color,
                background: true
            )
        }
        .foregroundStyle(Color.primary)
    }
}

// MARK: - Preview

#Preview {
    ReviewReminderCell(reviewReminder: ReviewReminder()) {}
}

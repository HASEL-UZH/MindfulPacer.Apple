//
//  ReminderCell.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import SwiftUI

struct ReminderCell: View {
    let rule: AlertRule
    
    var body: some View {
        HStack(spacing: 16) {
            Icon(
                name: "alarm",
                color: rule.reminderType.color,
                background: true
            )
            
            VStack(alignment: .leading, spacing: 8) {
                IconLabel(
                    icon: rule.measurementType == .heartRate ? "heart.fill" : "figure.walk",
                    title: rule.measurementType.localized,
                    labelColor: rule.measurementType.color
                )
                .font(.subheadline.weight(.semibold))
                
                Text(rule.alertMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color.primary)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(.primary.opacity(0.1))
        }
    }
}

//
//  ReminderCell.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import SwiftUI

struct ReminderCell: View {
    let rule: HeartRateAlertRule
    
    var body: some View {
        HStack(spacing: 16) {
            Icon(
                name: "alarm",
                color: .yellow,
                background: true
            )
            
            VStack(alignment: .leading, spacing: 8) {
                IconLabel(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    labelColor: .pink
                )
                .font(.subheadline.weight(.semibold))
                
                Text("Above 90 bpm for 10 min")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(Color.primary)
    }
}

#Preview {
    ReminderCell(rule: HeartRateAlertRule(id: UUID(), thresholdBPM: 0.0, duration: .infinity, alertMessage: "", type: .light))
}

//
//  ReminderTypeInfoSheet.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import SwiftUI

struct ReminderTypeInfoSheet: View {
    var body: some View {
        InfoSheet(
            title: String(localized: "Reminder Type Information"),
            info: String(localized: "You can choose between three different Reminder types.")
        ) {
            VStack(spacing: 12) {
                ForEach(Reminder.ReminderType.allCases, id: \.self) { reminderType in
                    ReminderCreationInfoBlock(
                        title: reminderType.localized,
                        systemImage: reminderType.icon,
                        tint: reminderType.color,
                        text: reminderType.description
                    )
                }

                Label("The strength and duration of the vibration varies by reminder type.", systemImage: "applewatch.radiowaves.left.and.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }
}

#Preview {
    ReminderTypeInfoSheet()
}

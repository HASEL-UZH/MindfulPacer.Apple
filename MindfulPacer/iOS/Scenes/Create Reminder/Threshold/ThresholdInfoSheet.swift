//
//  ThresholdInfoSheet.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import SwiftUI

struct ThresholdInfoSheet: View {
    var body: some View {
        InfoSheet(
            title: String(localized: "Threshold Information"),
            info: String(localized: "Set a threshold that triggers a reminder when reached for a specified interval. Please consult with your healthcare professional if you are unsure which threshold to set.")
        ) {
            VStack(spacing: 16) {
                ReminderCreationInfoBlock(
                    title: String(localized: "Steps"),
                    systemImage: "figure.walk",
                    tint: .teal,
                    text: """
                    The current step count, as detected by the Apple Watch, must stay at or above the threshold for a Reminder to be triggered.

                    For example: Completing more than 2000 steps in 30 minutes.
                    """
                )

                ReminderCreationInfoBlock(
                    title: String(localized: "Heart Rate"),
                    systemImage: "heart",
                    tint: .pink,
                    text: """
                    The current heart rate, in beats per minute, must stay at or above the threshold for a Reminder to be triggered.

                    Thresholds are highly individual. Please consult with your healthcare professional if you are unsure which value to set.
                    """
                )
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }
}

#Preview {
    ThresholdInfoSheet()
}

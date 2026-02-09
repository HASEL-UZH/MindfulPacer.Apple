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
            info: String(localized: "Set a threshold that triggers a reminder when reached for a specified interval.")
        ) {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label: IconLabel(icon: "figure.walk", title: "Steps", labelColor: .teal)
                    label: IconLabel(icon: "figure.walk", title: String(localized: "Steps"), labelColor: .teal)
                ) {
                    Text(
                        """
                        The current step count, as detected by the Apple Watch, must stay at or above the threshold for a Reminder to be triggered.
                        
                        For example: Completing more than 2000 steps in 30 minutes.\n\nPlease note that you can set the interval on the next page.
                        """
                    )
                    
                }
                
                IconLabelGroupBox(
                    label: IconLabel(icon: "heart", title: "Heart Rate", labelColor: .pink)
                    label: IconLabel(icon: "heart", title: String(localized: "Heart Rate"), labelColor: .pink)
                ) {
                    Text(
                        """
                        The current heart rate (in beats per minute, BPM), as detected by the Apple Watch, must stay at or above the threshold for a Reminder to be triggered.
                        
                        Please note that such thresholds for pacing and managing your activity are highly individual. We recommend to experiment with different (and several) thresholds to identify what works best for you. One starting point could be (220 - AgeInYears) * 0.5. For example, a 40-year old person would set a threshold as (220-40)*0.5=90 beats per minute.
                        """
                    )
                }
            }
            .font(.subheadline)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }
}

#Preview {
    ThresholdInfoSheet()
}

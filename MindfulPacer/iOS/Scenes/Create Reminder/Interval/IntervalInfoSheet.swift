//
//  IntervalInfoSheet.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import SwiftUI

struct IntervalInfoSheet: View {
    var body: some View {
        InfoSheet(
            title: String(localized: "Interval Information"),
            info: String(localized: "Duration during which the heart rate has to be greater than or equal to the threshold (threshold selected on previous page) in order for the Reminder to be triggered.")
        ) {
            VStack(spacing: 16) {
                IconLabelGroupBox(
                    label: IconLabel(icon: "figure.walk", title: "Steps", labelColor: .teal)
                ) {
                    Text(
                        """
                        The period during which the heart rate, as measured by the Apple Watch, must stay at or above the specified threshold for the Reminder to be triggered.
                        
                        For example: Do a quick reflection when the detected heart rate is greater than 120 for 30 seconds or longer.
                        """
                    )
                }
                
                IconLabelGroupBox(
                    label: IconLabel(icon: "heart", title: "Heart Rate", labelColor: .pink)
                ) {
                    Text(
                        """
                        The period during which the total number of steps, as measured by the Apple Watch, must stay at or above the threshold for the Reminder to be triggered.
                        
                        For example: Do a quick reflection when completing 2000 or more steps within 30 minutes.
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
    IntervalInfoSheet()
}

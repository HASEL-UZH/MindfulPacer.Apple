//
//  ReturnToAppInfoSheet.swift
//  iOS
//
//  Created by Grigor Dochev on 17.02.2026.
//

import SwiftUI

// MARK: - Return to App Info Sheet

struct ReturnToAppInfoSheet: View {
    var body: some View {
        InfoSheet(
            title: String(localized: "Return to App"),
            info: String(localized: "This setting can keep MindfulPacer on screen while a session is active. If you don’t see it right away, don’t worry - it can take a little time to appear.")
        ) {
            VStack(spacing: 16) {

                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "questionmark.circle",
                        title: String(localized: "Why it may not show"),
                        labelColor: .secondary
                    )
                ) {
                    Text(
                        String(localized: """
                        Sometimes MindfulPacer doesn’t appear in the Watch app’s “Return to Clock” list immediately - even if it’s installed. This is normal and usually fixes itself after the watch finishes setup.
                        """)
                    )
                }

                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "checkmark.circle.fill",
                        title: String(localized: "Try this"),
                        labelColor: Color("BrandPrimary")
                    )
                ) {
                    Text(
                        String(localized: """
                        1. Open MindfulPacer on your Apple Watch.
                        2. Keep it open for a few seconds.
                        3. Then check again on your iPhone:
                           Watch app → General → Return to Clock → MindfulPacer
                        """)
                    )
                }

                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "clock.badge.exclamationmark",
                        title: String(localized: "If it’s still missing"),
                        labelColor: .orange
                    )
                ) {
                    Text(
                        String(localized: """
                        • Wait a minute and try again.
                        • Make sure your Apple Watch is connected to your iPhone.
                        • Restart your Apple Watch, then check again.
                        """)
                    )
                }

                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "info.circle",
                        title: String(localized: "Good to know"),
                        labelColor: .cyan
                    )
                ) {
                    Text(
                        String(localized: """
                        This setting is optional. MindfulPacer will work normally even if your watch returns to the clock.
                        """)
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

// MARK: - Preview

#Preview {
    ReturnToAppInfoSheet()
}

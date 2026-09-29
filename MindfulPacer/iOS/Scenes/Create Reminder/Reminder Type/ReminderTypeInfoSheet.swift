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
            VStack(alignment: .leading, spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        reminderTypeCard(
                            title: "Light Reminder",
                            color: .yellow,
                            image: Image(.lightReminder)
                        )

                        reminderTypeCard(
                            title: "Medium Reminder",
                            color: .orange,
                            image: Image(.mediumReminder)
                        )

                        reminderTypeCard(
                            title: "Strong Reminder",
                            color: .red,
                            image: Image(.strongReminder)
                        )
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)

                Label("The strength and duration of the vibration varies by reminder type.", systemImage: "applewatch.radiowaves.left.and.right")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func reminderTypeCard(
        title: String,
        color: Color,
        image: Image
    ) -> some View {
        VStack(alignment: .center, spacing: 16) {
            Label(title, systemImage: "circle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)

            image
                .resizable()
                .scaledToFit()
                .frame(height: 256)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.tertiarySystemGroupedBackground))
        }
    }
}

#Preview {
    ReminderTypeInfoSheet()
}

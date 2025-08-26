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
            IconLabelGroupBox(
                label:
                    IconLabel(
                        icon: "alarm",
                        title: String(localized: "Reminder Types"),
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
            ) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 16) {
                        Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                            VStack(alignment: .center, spacing: 16) {
                                IconLabel(
                                    icon: "circle",
                                    title: "Light Reminder",
                                    labelColor: .yellow,
                                    background: true
                                )
                                .font(.subheadline.weight(.semibold))
                                
                                Image(.lightReminder)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 256)
                            }
                        }
                        
                        Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                            VStack(alignment: .center, spacing: 16) {
                                IconLabel(
                                    icon: "circle",
                                    title: "Medium Reminder",
                                    labelColor: .orange,
                                    background: true
                                )
                                .font(.subheadline.weight(.semibold))
                                
                                Image(.mediumReminder)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 256)
                            }
                        }
                        
                        Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                            VStack(alignment: .center, spacing: 16) {
                                IconLabel(
                                    icon: "circle",
                                    title: "Strong Reminder",
                                    labelColor: .red,
                                    background: true
                                )
                                .font(.subheadline.weight(.semibold))
                                
                                Image(.strongReminder)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 256)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
            } footer: {
                Label("The strength and duration of the vibration varies by reminder type.", systemImage: "applewatch.radiowaves.left.and.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .iconLabelGroupBoxStyle(.divider)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(16)
    }
}

#Preview {
    ReminderTypeInfoSheet()
}

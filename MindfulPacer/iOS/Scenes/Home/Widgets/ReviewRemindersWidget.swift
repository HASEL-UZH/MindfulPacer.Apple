//
//  RemindersWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - RemindersWidget

extension HomeView {
    struct RemindersWidget: View {
        
        // MARK: Properties

        @Bindable var viewModel: HomeViewModel

        // MARK: Body
        
        var body: some View {
            NavigationLink(value: HomeViewNavigationDestination.remindersList) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "bell.badge.fill",
                        title: "Reflection Reminders",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description:
                        Text("Summary of your reflection reminders.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    if viewModel.reminders.isEmpty {
                        EmptyStateView(
                            image: "bell.badge.slash",
                            title: "No Reflection Reminders",
                            description: "Tap the + button to create a reflection reminder."
                        )
                    } else {
                        recentRemindersSummary
                    }
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                } footer: {
                    createReminderButton
                }
            }
            .foregroundStyle(.primary)
        }

        // MARK: Recent Reflection Reminders Summary
        
        private var recentRemindersSummary: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.recentReminders, id: \.self) { reminder in
                    ReminderCell(
                        reminder: reminder,
                        backgroundColor: Color(.tertiarySystemGroupedBackground)
                    ) {
                        viewModel.presentSheet(.createReminderView(reminder))
                    }
                    if viewModel.recentReminders.last != reminder {
                        Divider()
                    }
                }
            }
            .cornerRadius(16)
        }

        // MARK: Create Reflection Reminder Button

        private var createReminderButton: some View {
            Button {
                viewModel.presentSheet(.createReminderView(nil))
            } label: {
                IconLabel(icon: "plus.circle", title: "Create Reflection Reminder", labelColor: Color("BrandPrimary"))
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    ScrollView {
        HomeView.RemindersWidget(viewModel: viewModel)
            .padding()
    }
    .background(Color(.systemGroupedBackground))
}

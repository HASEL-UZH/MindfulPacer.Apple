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
            LabeledCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Summary of your Reminders.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if viewModel.reminders.isEmpty {
                        EmptyStateView(
                            image: "bell.badge.slash",
                            title: String(localized: "No Reminders"),
                            description: String(localized: "Tap the + button to create a reminder.")
                        )
                    } else {
                        recentRemindersSummary
                    }

                    Divider()

                    createReminderButton
                }
            } label: {
                Label("Reminders", systemImage: "bell.badge.fill")
                    .foregroundStyle(Color("BrandPrimary"))
            } accessory: {
                NavigationLink(value: HomeNavigationDestination.remindersList) {
                    navigationAccessory("View")
                }
                .buttonStyle(.plain)
            }
        }

        // MARK: Recent Reminders Summary
        
        private var recentRemindersSummary: some View {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.recentReminders, id: \.self) { reminder in
                    reminderRow(reminder)

                    if viewModel.recentReminders.last != reminder {
                        Divider()
                    }
                }
            }
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        private func reminderRow(_ reminder: Reminder) -> some View {
            Button {
                viewModel.presentSheet(.createReminderView(reminder))
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: reminder.measurementType.icon)
                        .font(.headline)
                        .foregroundStyle(reminder.measurementType == .heartRate ? .pink : .teal)
                        .frame(width: 34, height: 34)
                        .background((reminder.measurementType == .heartRate ? Color.pink : Color.teal).opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(reminder.measurementType.localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Text(reminder.triggerSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "alarm")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(reminder.reminderType.color)
                        .frame(width: 30, height: 30)
                        .background(reminder.reminderType.color.opacity(0.12), in: Circle())
                }
                .padding()
            }
            .buttonStyle(.plain)
        }

        // MARK: Create Reminder Button
        
        private var createReminderButton: some View {
            Button {
                viewModel.presentSheet(.createReminderView(nil))
            } label: {
                Label("Create Reminder", systemImage: "plus.circle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandPrimary"))
            }
            .buttonStyle(.plain)
        }

        private func navigationAccessory(_ title: String) -> some View {
            HStack(spacing: 6) {
                Text(title)
                Image(systemName: "chevron.right")
            }
            .font(.subheadline)
            .foregroundStyle(Color(.systemGray2))
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

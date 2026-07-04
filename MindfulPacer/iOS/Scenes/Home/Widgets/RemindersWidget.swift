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
            NavigationLink(value: HomeNavigationDestination.remindersList) {
                LabeledCard(
                    contentSpacing: 18,
                    contentPadding: 16,
                    cornerRadius: 24
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        if viewModel.reminders.isEmpty {
                            EmptyStateView(
                                image: "bell.badge.slash",
                                title: String(localized: "No Reminders"),
                                description: String(localized: "Tap the + button to create a reminder.")
                            )
                        } else {
                            Text(remindersHeadline)
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Divider()

                            recentRemindersSummary
                        }

                        Divider()

                        createReminderButton
                    }
                } label: {
                    Label("Reminders", systemImage: "bell.badge.fill")
                        .foregroundStyle(Color("BrandPrimary"))
                } accessory: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.systemGray2))
                }
            }
            .buttonStyle(.plain)
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
        }

        private func reminderRow(_ reminder: Reminder) -> some View {
            Button {
                viewModel.presentSheet(.createReminderView(reminder))
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: reminder.measurementType.icon)
                        .font(.headline)
                        .foregroundStyle(reminder.measurementType.color)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(reminder.measurementType.localized)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text("\(reminder.threshold) \(reminder.thresholdUnits)")

                            subtitleSeparator

                            Text(reminder.interval.localized)

                            subtitleSeparator

                            Text(reminder.reminderType.localized)
                                .foregroundStyle(reminder.reminderType.color)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    }
                }
                .padding(.vertical, 10)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }

        private var subtitleSeparator: some View {
            Rectangle()
                .fill(Color(.separator))
                .frame(width: 1, height: 13)
        }

        private var remindersHeadline: String {
            switch viewModel.reminders.count {
            case 1:
                String(localized: "You have 1 active reminder.")
            default:
                String(localized: "You have \(viewModel.reminders.count) active reminders.")
            }
        }

        // MARK: Create Reminder Button
        
        private var createReminderButton: some View {
            Button {
                viewModel.presentSheet(.createReminderView(nil))
            } label: {
                Label("Create Reminder", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("BrandPrimary"))
            }
            .buttonStyle(.plain)
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

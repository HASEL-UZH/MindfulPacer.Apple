import SwiftUI

extension HomeView {
    struct RemindersWidget: View {
        @Bindable var viewModel: HomeViewModel

        let onOpenList: () -> Void

        var body: some View {
            LabeledCard(
                contentSpacing: 12,
                action: onOpenList,
                actionAccessibilityIdentifier: "home.reminders.showAll"
            ) {
                if viewModel.reminders.isEmpty {
                    Button(action: onOpenList) {
                        EmptyStateView(image: "bell.badge.slash", title: String(localized: "No Reminders"),
                                       description: String(localized: "Create a reminder to make time for reflection."),
                                       isCompact: true)
                            .frame(maxWidth: .infinity)
                            .contentShape(.rect)
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(viewModel.recentReminders) { reminder in
                            if reminder.id != viewModel.recentReminders.first?.id {
                                Divider().padding(.leading, 36)
                            }
                            Button {
                                viewModel.presentSheet(.createReminderView(reminder))
                            } label: {
                                reminderRow(reminder)
                            }
                            .accessibilityIdentifier("home.reminder.\(reminder.id)")
                        }
                    }
                }
            } label: {
                Label("Reminders", systemImage: "bell.badge.fill")
                    .foregroundStyle(Color.accentColor)
            } accessory: {
                HStack(spacing: 4) {
                    Text("Show All")
                    Image(systemName: "chevron.right")
                }
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            }
        }

        private func reminderRow(_ reminder: Reminder) -> some View {
            HStack(spacing: 12) {
                Image(systemName: reminder.measurementType.icon)
                    .font(.body)
                    .foregroundStyle(reminder.measurementType.color)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 4) {
                    Text(reminder.measurementType.localized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(reminder.triggerSummary)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                Image(systemName: reminder.reminderType.icon)
                    .font(.body)
                    .foregroundStyle(reminder.reminderType.color)
                    .accessibilityLabel(reminder.reminderType.localized)
            }
            .frame(minHeight: 44)
            .padding(.top, reminder.id == viewModel.recentReminders.first?.id ? 0 : 8)
            .padding(.bottom, reminder.id == viewModel.recentReminders.last?.id ? 0 : 8)
            .contentShape(.rect)
        }
    }
}

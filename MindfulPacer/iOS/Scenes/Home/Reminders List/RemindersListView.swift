//
//  RemindersListView.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import SwiftUI

// MARK: - RemindersListView

struct RemindersListView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: HomeViewModel
    @State private var activeReminderID: UUID?
    @State private var reminderPendingDeletion: Reminder?
    
    // MARK: Body
    
    var body: some View {
        Group {
            if viewModel.reminders.isEmpty {
                remindersEmptyState
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                remindersList
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Reminders")
        .navigationSubtitle(navigationSubtitleText)
        .alert("Delete Reminder", isPresented: isDeleteConfirmationPresented) {
            Button("Delete", role: .destructive) {
                deletePendingReminder()
            }

            Button("Cancel", role: .cancel) {
                reminderPendingDeletion = nil
            }
        } message: {
            Text("Are you sure you want to delete this reminder? This action cannot be undone.")
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentSheet(.createReminderView(nil))
                } label: {
                    Label("New Reminder", systemImage: "plus")
                }
            }
        }
    }

    // MARK: Reminders List

    private var remindersList: some View {
        GeometryReader { proxy in
            ScrollView {
                ZStack(alignment: .top) {
                    Color.clear
                        .contentShape(.rect)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: proxy.size.height)
                        .onTapGesture {
                            clearActiveReminder()
                        }

                    LazyVStack(alignment: .leading, spacing: 6) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.reminders, id: \.id) { reminder in
                                reminderRow(reminder)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }

    private var navigationSubtitleText: String {
        let count = viewModel.reminders.count
        return count == 1 ? String(localized: "1 reminder") : String(localized: "\(count) reminders")
    }

    private var isDeleteConfirmationPresented: Binding<Bool> {
        Binding {
            reminderPendingDeletion != nil
        } set: { isPresented in
            if !isPresented {
                reminderPendingDeletion = nil
            }
        }
    }
    
    // MARK: Reminders Empty State
    
    private var remindersEmptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            ContentUnavailableView {
                Label("No Reminders", systemImage: "bell.badge.fill")
            } description: {
                Text("You have not created any reminders.")
            } actions: {
                Button {
                    viewModel.presentSheet(.createReminderView(nil))
                } label: {
                    Text("Create Reminder")
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private func reminderRow(_ reminder: Reminder) -> some View {
        let metadataRow = ExpandableMetadataRow(
            id: reminder.id,
            activeID: $activeReminderID,
            expandedContentLeadingInset: 44
        ) { isActive in
            reminderRowContent(reminder, isActive: isActive)
        } rowAccessory: { isActive in
            reminderRowAccessory(reminder, isActive: isActive)
        } expandedContent: {
            reminderQuickActions(reminder)
        }

        if activeReminderID != reminder.id {
            metadataRow
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        presentDeleteConfirmation(for: reminder)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } onPresentationChanged: { isPresented in
                    guard isPresented else { return }
                    clearActiveReminder()
                }
        } else {
            metadataRow
        }
    }

    private func reminderRowContent(_ reminder: Reminder, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: reminder.measurementType.icon)
                .symbolVariant(.circle.fill)
                .font(.title2.weight(.semibold))
                .foregroundStyle(isActive ? reminder.measurementType.color : .secondary)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.measurementType.localized)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(reminder.triggerSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func reminderRowAccessory(_ reminder: Reminder, isActive: Bool) -> some View {
        if isActive {
            Button {
                viewModel.presentSheet(.createReminderView(reminder))
            } label: {
                Image(systemName: "info.circle")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("BrandPrimary"))
                    .frame(width: 32, height: 32)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit Reminder")
            .padding(.top, 4)
        }
    }

    private func reminderQuickActions(_ reminder: Reminder) -> some View {
        ExpandableMetadataScroll {
            ExpandableMetadataMenuChip(
                title: reminder.measurementType.localized,
                systemImage: reminder.measurementType.icon,
                isActive: true,
                tint: reminder.measurementType.color
            ) {
                Section {
                    ForEach(MeasurementType.allCases, id: \.self) { measurementType in
                        Button(measurementType.localized, systemImage: measurementType.icon) {
                            viewModel.updateReminder(reminder, measurementType: measurementType)
                        }
                    }
                }
            }

            ExpandableMetadataMenuChip(
                title: reminder.reminderType.localized,
                systemImage: reminder.reminderType.icon,
                isActive: true,
                tint: reminder.reminderType.color
            ) {
                Section {
                    ForEach(Reminder.ReminderType.allCases, id: \.self) { reminderType in
                        Button(reminderType.localized, systemImage: reminderType.icon) {
                            viewModel.updateReminder(reminder, reminderType: reminderType)
                        }
                    }
                }
            }

            ExpandableMetadataMenuChip(
                title: reminder.interval.localized,
                systemImage: reminder.interval.icon,
                isActive: true
            ) {
                Section {
                    ForEach(validIntervals(for: reminder.measurementType), id: \.self) { interval in
                        Button(interval.localized, systemImage: interval.icon) {
                            viewModel.updateReminder(reminder, interval: interval)
                        }
                    }
                }
            }

            ExpandableMetadataChip(
                title: "\(reminder.threshold) \(reminder.thresholdUnits)",
                systemImage: "number",
                isActive: true
            )
        }
    }

    private func validIntervals(for measurementType: MeasurementType) -> [Reminder.Interval] {
        switch measurementType {
        case .heartRate:
            Reminder.Interval.heartRateIntervals
        case .steps:
            Reminder.Interval.stepsIntervals
        }
    }

    private func clearActiveReminder() {
        withAnimation(.snappy(duration: 0.24)) {
            activeReminderID = nil
        }
    }

    private func presentDeleteConfirmation(for reminder: Reminder) {
        clearActiveReminder()
        reminderPendingDeletion = reminder
    }

    private func deletePendingReminder() {
        guard let reminder = reminderPendingDeletion else { return }
        reminderPendingDeletion = nil
        activeReminderID = nil
        viewModel.deleteReminder(reminder)
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    NavigationStack {
        RemindersListView(viewModel: viewModel)
    }
}

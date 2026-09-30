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
    @State private var thresholdEditorSelection: ReminderThresholdEditorSelection?
    @State private var collapsedMeasurementTypes: Set<MeasurementType> = []
    
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
        .navigationBarTitleDisplayMode(.large)
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
        .sheet(item: $thresholdEditorSelection) { selection in
            ReminderThresholdEditorSheet(
                viewModel: viewModel,
                reminder: selection.reminder
            )
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
                        ForEach(reminderSections) { section in
                            reminderSection(
                                section,
                                isLast: section.id == reminderSections.last?.id
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
            }
            .swipeActionsContainer()
            .background(Color(.systemGroupedBackground))
        }
    }

    private var navigationSubtitleText: String {
        let count = viewModel.reminders.count
        return count == 1 ? String(localized: "1 reminder") : String(localized: "\(count) reminders")
    }

    private var reminderSections: [ReminderSection] {
        MeasurementType.allCases.compactMap { measurementType in
            let reminders = viewModel.reminders.filter { $0.measurementType == measurementType }
            guard !reminders.isEmpty else { return nil }
            return ReminderSection(measurementType: measurementType, reminders: reminders)
        }
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

    private func reminderSection(_ section: ReminderSection, isLast: Bool) -> some View {
        let isCollapsed = collapsedMeasurementTypes.contains(section.measurementType)

        return VStack(alignment: .leading, spacing: 4) {
            ReminderMeasurementSectionHeader(
                measurementType: section.measurementType,
                reminderCount: section.reminders.count,
                isCollapsed: isCollapsed
            ) {
                toggleSection(section.measurementType)
            }

            if !isCollapsed {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(section.reminders, id: \.id) { reminder in
                        reminderRow(reminder)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) {
            Divider()
                .opacity(isLast ? 0 : 1)
                .offset(y: 6)
        }
        .padding(.bottom, isLast ? 0 : 12)
    }

    private func reminderRow(_ reminder: Reminder) -> some View {
        ExpandableMetadataRow(
            id: reminder.id,
            activeID: $activeReminderID,
            expandedContentLeadingInset: 36,
            onSwipePresentationChanged: { isPresented in
                if isPresented { clearActiveReminder() }
            }
        ) { isActive in
            reminderRowContent(reminder, isActive: isActive)
        } rowAccessory: { isActive in
            reminderRowAccessory(reminder, isActive: isActive)
        } rowSwipeActions: {
            Button(role: .destructive) {
                presentDeleteConfirmation(for: reminder)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .accessibilityLabel("Delete")
            .accessibilityIdentifier("reminders.delete")
        } expandedContent: {
            reminderQuickActions(reminder)
        }
        .accessibilityIdentifier("reminders.row.\(reminder.id)")
    }

    private func reminderRowContent(_ reminder: Reminder, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: reminderIconName(for: reminder.measurementType))
                .symbolVariant(.fill)
                .font(.body.weight(.medium))
                .foregroundStyle(reminder.measurementType.color)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.measurementType.localized)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.primary)
                    .lineLimit(1)

                Text(reminder.triggerSummary)
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
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
            .accessibilityLabel("Edit Reminder")
            .padding(.top, 4)
        }
    }

    private func reminderQuickActions(_ reminder: Reminder) -> some View {
        ExpandableMetadataScroll {
            ExpandableMetadataChip(
                title: reminder.measurementType.localized,
                systemImage: reminder.measurementType.icon,
                isActive: true,
                tint: reminder.measurementType.color
            )

            ExpandableMetadataChip(
                title: reminder.reminderType.localized,
                systemImage: reminder.reminderType.icon,
                isActive: true,
                tint: reminder.reminderType.color
            )

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

            ExpandableMetadataChipButton(
                title: "\(reminder.threshold) \(reminder.thresholdUnits)",
                systemImage: "number",
                isActive: true,
                tint: reminder.measurementType.color
            ) {
                thresholdEditorSelection = ReminderThresholdEditorSelection(reminder: reminder)
            }
        }
    }

    private func reminderIconName(for measurementType: MeasurementType) -> String {
        switch measurementType {
        case .heartRate:
            measurementType.icon
        case .steps:
            "figure.walk"
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

    private func toggleSection(_ measurementType: MeasurementType) {
        withAnimation(.snappy(duration: 0.24)) {
            activeReminderID = nil
            if collapsedMeasurementTypes.contains(measurementType) {
                collapsedMeasurementTypes.remove(measurementType)
            } else {
                collapsedMeasurementTypes.insert(measurementType)
            }
        }
    }
}

private struct ReminderSection: Identifiable {
    let measurementType: MeasurementType
    let reminders: [Reminder]

    var id: MeasurementType {
        measurementType
    }
}

private struct ReminderThresholdEditorSelection: Identifiable {
    let reminder: Reminder

    var id: UUID {
        reminder.id
    }
}

private struct ReminderMeasurementSectionHeader: View {
    let measurementType: MeasurementType
    let reminderCount: Int
    let isCollapsed: Bool
    let onToggleCollapsed: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(measurementType.localized)
                    .font(.title3.weight(.bold))

                Text(reminderCountText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }

            Spacer(minLength: 12)

            Button(action: onToggleCollapsed) {
                Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.secondary)
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
            }
            .accessibilityLabel(isCollapsed ? "Expand \(measurementType.localized)" : "Collapse \(measurementType.localized)")
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .contentShape(.rect)
    }

    private var reminderCountText: String {
        reminderCount == 1 ? String(localized: "1 reminder") : String(localized: "\(reminderCount) reminders")
    }
}

private struct ReminderThresholdEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var viewModel: HomeViewModel
    let reminder: Reminder

    @State private var threshold: Int?
    @FocusState private var isThresholdFocused: Bool

    init(
        viewModel: HomeViewModel,
        reminder: Reminder
    ) {
        self.viewModel = viewModel
        self.reminder = reminder
        self._threshold = State(initialValue: reminder.threshold)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        TextField("0", value: $threshold, format: .number)
                            .keyboardType(.numberPad)
                            .focused($isThresholdFocused)
                            .font(.title2.weight(.semibold))

                        Text(reminder.thresholdUnits)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                    }
                } footer: {
                    Text(footerText)
                }
            }
            .navigationTitle("Threshold")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(threshold == nil)
                }

                ToolbarItem(placement: .keyboard) {
                    Button {
                        isThresholdFocused = false
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down.fill")
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .onSubmit {
                save()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            isThresholdFocused = true
        }
    }

    private func save() {
        guard let threshold else { return }
        viewModel.updateReminder(reminder, threshold: threshold)
        dismiss()
    }

    private var footerText: String {
        switch reminder.measurementType {
        case .heartRate:
            String(localized: "Heart rate thresholds can be between 0 and 250 bpm.")
        case .steps:
            String(localized: "Step thresholds can be between 0 and 100000 steps.")
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    NavigationStack {
        RemindersListView(viewModel: viewModel)
    }
}

//
//  CreateReminderViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Combine
import Foundation
import SwiftData

// MARK: - CreateReminderViewModel

@MainActor
@Observable
class CreateReminderViewModel {
    enum Mode { case create, edit }

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let createReminderUseCase: CreateReminderUseCase
    private let deleteReminderUseCase: DeleteReminderUseCase
    private let saveReminderUseCase: SaveReminderUseCase
    private let triggerWatchNotificationUseCase: TriggerWatchNotificationUseCase

    // MARK: - Published Properties

    var mode: Mode = .create
    var navigationPath: [CreateReminderNavigationDestination] = []
    var activeSheet: CreateReminderSheet?
    var activeAlert: CreateReminderAlert?

    var shouldDismiss: Bool = false

    var summaryViewTitle: String {
        switch mode {
        case .create:
            return String(localized: "Reminder Summary")
        case .edit:
            return String(localized: "Edit Reminder")
        }
    }

    var isActionButtonDisabled: Bool {
        guard let lastDestination = navigationPath.last else {
            return false
        }

        switch lastDestination {
        case .measurementType:
            return selectedMeasurementType == nil
        case .reminderType:
            return selectedReminderType == nil
        case .threshold:
            return threshold == nil
        case .interval:
            return selectedInterval == nil
        case .summary:
            return (selectedMeasurementType == nil || selectedReminderType == nil || threshold == nil || selectedInterval == nil)
        }
    }

    var isSaveButtonDisabled: Bool {
        selectedMeasurementType == nil || selectedReminderType == nil || threshold == nil || selectedInterval == nil
    }

    var showActionButton: Bool {
        /// Check if the second-to-last element in the navigationPath is .summary
        if navigationPath.dropLast().last == .summary {
            return false
        }
        return true
    }

    var actionButtonTitle: String {
        guard let lastDestination = navigationPath.last else {
            return String(localized: "Continue")
        }

        switch lastDestination {
        case .summary:
            return String(localized: "Create")
        default:
            return String(localized: "Continue")
        }
    }
    
    var validIntervals: [Reminder.Interval] {
        switch selectedMeasurementType {
        case .heartRate:
            Reminder.Interval.heartRateIntervals
        case .steps:
            Reminder.Interval.stepsIntervals
        case .none:
            []
        }
    }

    var thresholdUnitText: String {
        switch selectedMeasurementType {
        case .heartRate:
            return String(localized: "bpm")
        case .steps:
            return String(localized: "steps")
        case nil:
            return ""
        }
    }

    var notificationPreviewBodyText: String {
        String("A Reminder was triggered because your \(selectedMeasurementType?.rawValue.lowercased() ?? "<MEASUREMENT TYPE>") exceeded the threshold of \(threshold ?? 0) \(thresholdUnitText.lowercased()) over a period of \(selectedInterval?.rawValue.lowercased() ?? "<INTERBAL>").")
    }

    var selectedMeasurementType: MeasurementType? {
        didSet {
            validateThreshold()
            resetSelectedFields()
        }
    }
    var threshold: Int? {
        didSet {
            validateThreshold()
        }
    }
    var selectedReminderType: Reminder.ReminderType?
    var selectedInterval: Reminder.Interval?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        createReminderUseCase: CreateReminderUseCase,
        deleteReminderUseCase: DeleteReminderUseCase,
        saveReminderUseCase: SaveReminderUseCase,
        triggerWatchNotificationUseCase: TriggerWatchNotificationUseCase
    ) {
        self.modelContext = modelContext
        self.createReminderUseCase = createReminderUseCase
        self.deleteReminderUseCase = deleteReminderUseCase
        self.saveReminderUseCase = saveReminderUseCase
        self.triggerWatchNotificationUseCase = triggerWatchNotificationUseCase
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear() {}

    func configureMode(with reminder: Reminder?) {
        if let reminder {
            mode = .edit
            loadReminder(reminder)
        }
    }

    // MARK: - User Actions

    func actionButtonTapped() {
        /// Check if we are on the first page
        guard let currentDestination = navigationPath.last else {
            navigateTo(destination: .measurementType)
            return
        }

        switch currentDestination {
        case .measurementType:
            navigateTo(destination: .reminderType)
        case .reminderType:
            navigateTo(destination: .threshold)
        case .threshold:
            navigateTo(destination: .interval)
        case .interval:
            navigateTo(destination: .summary)
        case .summary:
            createReminder()
        }
    }

    func saveReminder(_ reminder: Reminder?) {
        let result = saveReminderUseCase.execute(
            existingReminder: reminder.unsafelyUnwrapped,
            newMeasurementType: selectedMeasurementType.unsafelyUnwrapped,
            newReminderType: selectedReminderType.unsafelyUnwrapped,
            newThreshold: threshold.unsafelyUnwrapped,
            newInterval: selectedInterval.unsafelyUnwrapped
        )

        if case .failure = result {
            presentAlert(.unableToSaveReminder)
        }

        shouldDismiss = true
    }

    func deleteReminder(_ reminder: Reminder?) {
        guard let reminder else { return }
        deleteReminderUseCase.execute(reminder: reminder)
        shouldDismiss = true
    }

    func sendNotificationToWatch() {
        triggerWatchNotificationUseCase.execute(title: "Reminder", body: notificationPreviewBodyText) { result in
            switch result {
            case .success:
                print("Notification sent successfully")
            case .failure(let error):
                self.presentAlert(.unableToSendTestNotification)
            }
        }
    }

    func toggleSelection<T: Equatable>(_ item: T, selectedItem: inout T?) {
        selectedItem = (selectedItem == item) ? nil : item
    }

    // MARK: - Presentation

    func navigateTo(destination: CreateReminderNavigationDestination) {
        navigationPath.append(destination)
    }

    func presentSheet(_ sheet: CreateReminderSheet) {
        activeSheet = sheet
    }

    func presentAlert(_ alert: CreateReminderAlert) {
        activeAlert = alert
    }

    func dismissView() {
        shouldDismiss = true
    }
    
    // MARK: - Private Methods

    private func loadReminder(_ reminder: Reminder) {
        selectedMeasurementType = reminder.measurementType
        selectedReminderType = reminder.reminderType
        threshold = reminder.threshold
        selectedInterval = reminder.interval
    }

    private func createReminder() {
        guard let measurementType = selectedMeasurementType,
              let reminderType = selectedReminderType,
              let threshold,
              let interval = selectedInterval else {
                  print("Missing required fields to create Reminder")
                  return
              }

        let result = createReminderUseCase.execute(
            measurementType: measurementType,
            reminderType: reminderType,
            threshold: threshold,
            interval: interval
        )

        if case .failure = result {
            self.presentAlert(.unableToSaveReminder)
        }

        shouldDismiss = true
    }
    
    private func resetSelectedFields() {
        threshold = nil
        selectedInterval = nil
        selectedReminderType = nil
    }

    private func validateThreshold() {
        guard let threshold = threshold else { return }

        if let measurementType = selectedMeasurementType {
            switch measurementType {
            case .steps:
                if threshold < 0 {
                    self.threshold = 0
                } else if threshold > 100_000 {
                    self.threshold = 100_000
                }

            case .heartRate:
                if threshold < 0 {
                    self.threshold = 0
                } else if threshold > 250 {
                    self.threshold = 250
                }
            }
        }
    }
}

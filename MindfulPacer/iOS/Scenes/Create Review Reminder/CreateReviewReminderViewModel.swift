//
//  CreateReviewReminderViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Combine
import Foundation
import SwiftData

// MARK: - CreateReviewReminderViewModel

@MainActor
@Observable
class CreateReviewReminderViewModel {
    enum Mode { case create, edit }

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let createReviewReminderUseCase: CreateReviewReminderUseCase
    private let deleteReviewReminderUseCase: DeleteReviewReminderUseCase
    private let saveReviewReminderUseCase: SaveReviewReminderUseCase
    private let triggerWatchNotificationUseCase: TriggerWatchNotificationUseCase

    // MARK: - Published Properties

    var mode: Mode = .create
    var navigationPath: [CreateReviewReminderNavigationDestination] = []
    var activeSheet: CreateReviewReminderSheet?
    var activeAlert: CreateReviewReminderAlert?

    var shouldDismiss: Bool = false

    var summaryViewTitle: String {
        switch mode {
        case .create:
            return "Review Reminder Summary"
        case .edit:
            return "Edit Review Reminder"
        }
    }

    var isActionButtonDisabled: Bool {
        guard let lastDestination = navigationPath.last else {
            return false
        }

        switch lastDestination {
        case .measurementType:
            return selectedMeasurementType == nil
        case .reviewReminderType:
            return selectedReviewReminderType == nil
        case .threshold:
            return threshold == nil
        case .interval:
            return selectedInterval == nil
        case .summary:
            return (selectedMeasurementType == nil || selectedReviewReminderType == nil || threshold == nil || selectedInterval == nil)
        }
    }

    var isSaveButtonDisabled: Bool {
        selectedMeasurementType == nil || selectedReviewReminderType == nil || threshold == nil || selectedInterval == nil
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
            return "Continue"
        }

        switch lastDestination {
        case .summary:
            return "Create"
        default:
            return "Continue"
        }
    }
    
    var validIntervals: [ReviewReminder.Interval] {
        switch selectedMeasurementType {
        case .heartRate:
            ReviewReminder.Interval.heartRateIntervals
        case .steps:
            ReviewReminder.Interval.stepsIntervals
        case .none:
            []
        }
    }

    var thresholdUnitText: String {
        switch selectedMeasurementType {
        case .heartRate:
            return "bpm"
        case .steps:
            return "steps"
        case nil:
            return ""
        }
    }

    var notificationPreviewBodyText: String {
        String("A review reminder was triggered because your \(selectedMeasurementType?.rawValue.lowercased() ?? "<MEASUREMENT TYPE>") exceeded the threshold of \(threshold ?? 0) \(thresholdUnitText.lowercased()) over a period of \(selectedInterval?.rawValue.lowercased() ?? "<INTERBAL>").")
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
    var selectedReviewReminderType: ReviewReminder.ReviewReminderType?
    var selectedInterval: ReviewReminder.Interval?

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        createReviewReminderUseCase: CreateReviewReminderUseCase,
        deleteReviewReminderUseCase: DeleteReviewReminderUseCase,
        saveReviewReminderUseCase: SaveReviewReminderUseCase,
        triggerWatchNotificationUseCase: TriggerWatchNotificationUseCase
    ) {
        self.modelContext = modelContext
        self.createReviewReminderUseCase = createReviewReminderUseCase
        self.deleteReviewReminderUseCase = deleteReviewReminderUseCase
        self.saveReviewReminderUseCase = saveReviewReminderUseCase
        self.triggerWatchNotificationUseCase = triggerWatchNotificationUseCase
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear() {}

    func configureMode(with reviewReminder: ReviewReminder?) {
        if let reviewReminder {
            mode = .edit
            loadReviewReminder(reviewReminder)
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
            navigateTo(destination: .reviewReminderType)
        case .reviewReminderType:
            navigateTo(destination: .threshold)
        case .threshold:
            navigateTo(destination: .interval)
        case .interval:
            navigateTo(destination: .summary)
        case .summary:
            createReviewReminder()
        }
    }

    func saveReviewReminder(_ reviewReminder: ReviewReminder?) {
        let result = saveReviewReminderUseCase.execute(
            existingReviewReminder: reviewReminder.unsafelyUnwrapped,
            newMeasurementType: selectedMeasurementType.unsafelyUnwrapped,
            newReviewReminderType: selectedReviewReminderType.unsafelyUnwrapped,
            newThreshold: threshold.unsafelyUnwrapped,
            newInterval: selectedInterval.unsafelyUnwrapped
        )

        if case .failure = result {
            presentAlert(.unableToSaveReviewReminder)
        }

        shouldDismiss = true
    }

    func deleteReviewReminder(_ reviewReminder: ReviewReminder?) {
        guard let reviewReminder else { return }
        deleteReviewReminderUseCase.execute(reviewReminder: reviewReminder)
        shouldDismiss = true
    }

    func sendNotificationToWatch() {
        triggerWatchNotificationUseCase.execute(title: "Review Reminder", body: notificationPreviewBodyText) { result in
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

    func navigateTo(destination: CreateReviewReminderNavigationDestination) {
        navigationPath.append(destination)
    }

    func presentSheet(_ sheet: CreateReviewReminderSheet) {
        activeSheet = sheet
    }

    func presentAlert(_ alert: CreateReviewReminderAlert) {
        activeAlert = alert
    }

    func dismissView() {
        shouldDismiss = true
    }
    
    // MARK: - Private Methods

    private func loadReviewReminder(_ reviewReminder: ReviewReminder) {
        selectedMeasurementType = reviewReminder.measurementType
        selectedReviewReminderType = reviewReminder.reviewReminderType
        threshold = reviewReminder.threshold
        selectedInterval = reviewReminder.interval
    }

    private func createReviewReminder() {
        guard let measurementType = selectedMeasurementType,
              let reviewReminderType = selectedReviewReminderType,
              let threshold,
              let interval = selectedInterval else {
                  print("Missing required fields to create review reminder")
                  return
              }

        let result = createReviewReminderUseCase.execute(
            measurementType: measurementType,
            reviewReminderType: reviewReminderType,
            threshold: threshold,
            interval: interval
        )

        if case .failure = result {
            self.presentAlert(.unableToSaveReviewReminder)
        }

        shouldDismiss = true
    }
    
    private func resetSelectedFields() {
        threshold = nil
        selectedInterval = nil
        selectedReviewReminderType = nil
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

//
//  CreateReviewReminderViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Combine
import Foundation
import SwiftData
import CocoaLumberjackSwift

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
            DDLogInfo("Selected measurement type updated to \(String(describing: selectedMeasurementType))")
            validateThreshold()
        }
    }
    var threshold: Int? {
        didSet {
            DDLogInfo("Threshold updated to \(String(describing: threshold))")
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

        DDLogInfo("CreateReviewReminderViewModel initialized in mode: \(mode)")
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear() {
        DDLogInfo("View first appeared")
    }

    func configureMode(with reviewReminder: ReviewReminder?) {
        if let reviewReminder {
            DDLogInfo("Configuring view model with existing review reminder: \(reviewReminder)")
            mode = .edit
            loadReviewReminder(reviewReminder)
        } else {
            DDLogInfo("Creating new review reminder")
        }
    }

    // MARK: - User Actions

    func actionButtonTapped() {
        /// Check if we are on the first page
        guard let currentDestination = navigationPath.last else {
            DDLogInfo("Navigating to measurement type")
            navigateTo(destination: .measurementType)
            return
        }

        DDLogInfo("Action button tapped at destination: \(currentDestination)")

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
            DDLogInfo("Creating review reminder")
            createReviewReminder()
        }
    }

    func saveReviewReminder(_ reviewReminder: ReviewReminder?) {
        DDLogInfo("Saving review reminder: \(String(describing: reviewReminder))")
        let result = saveReviewReminderUseCase.execute(
            existingReviewReminder: reviewReminder.unsafelyUnwrapped,
            newMeasurementType: selectedMeasurementType.unsafelyUnwrapped,
            newReviewReminderType: selectedReviewReminderType.unsafelyUnwrapped,
            newThreshold: threshold.unsafelyUnwrapped,
            newInterval: selectedInterval.unsafelyUnwrapped
        )

        if case .failure = result {
            DDLogError("Failed to save review reminder")
            presentAlert(.unableToSaveReviewReminder)
        }

        shouldDismiss = true
    }

    func deleteReviewReminder(_ reviewReminder: ReviewReminder?) {
        guard let reviewReminder else { return }
        DDLogInfo("Deleting review reminder: \(reviewReminder)")
        deleteReviewReminderUseCase.execute(reviewReminder: reviewReminder)
        shouldDismiss = true
    }

    func sendNotificationToWatch() {
        DDLogInfo("Sending notification to watch")
        triggerWatchNotificationUseCase.execute(title: "Review Reminder", body: notificationPreviewBodyText) { result in
            switch result {
            case .success:
                DDLogInfo("Notification sent successfully")
            case .failure(let error):
                self.presentAlert(.unableToSendTestNotification)
                DDLogError("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }

    func toggleSelection<T: Equatable>(_ item: T, selectedItem: inout T?) {
        selectedItem = (selectedItem == item) ? nil : item
        DDLogInfo("Toggled selection of \(item), selectedItem is now: \(String(describing: selectedItem))")
    }

    // MARK: - Presentation

    func navigateTo(destination: CreateReviewReminderNavigationDestination) {
        DDLogInfo("Navigating to: \(destination)")
        navigationPath.append(destination)
    }

    func presentSheet(_ sheet: CreateReviewReminderSheet) {
        DDLogInfo("Presenting sheet: \(sheet)")
        activeSheet = sheet
    }

    func presentAlert(_ alert: CreateReviewReminderAlert) {
        DDLogInfo("Presenting alert: \(alert)")
        activeAlert = alert
    }

    func dismissView() {
        shouldDismiss = true
    }
    
    // MARK: - Private Methods

    private func loadReviewReminder(_ reviewReminder: ReviewReminder) {
        DDLogInfo("Loading review reminder: \(reviewReminder)")
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
                  DDLogError("Missing required fields to create review reminder")
                  return
              }

        let result = createReviewReminderUseCase.execute(
            measurementType: measurementType,
            reviewReminderType: reviewReminderType,
            threshold: threshold,
            interval: interval
        )

        if case .failure = result {
            DDLogError("Failed to create review reminder")
            self.presentAlert(.unableToSaveReviewReminder)
        }

        shouldDismiss = true
    }

    private func validateThreshold() {
        DDLogInfo("Validating threshold: \(String(describing: threshold)) for measurement type: \(String(describing: selectedMeasurementType))")
        guard let threshold = threshold else { return }

        if let measurementType = selectedMeasurementType {
            switch measurementType {
            case .steps:
                if threshold < 0 {
                    self.threshold = 0
                    DDLogWarn("Steps threshold set below 0, resetting to 0")
                } else if threshold > 100_000 {
                    self.threshold = 100_000
                    DDLogWarn("Steps threshold set above 100,000, resetting to 100,000")
                }

            case .heartRate:
                if threshold < 0 {
                    self.threshold = 0
                    DDLogWarn("Heart rate threshold set below 0, resetting to 0")
                } else if threshold > 250 {
                    self.threshold = 250
                    DDLogWarn("Heart rate threshold set above 250, resetting to 250")
                }
            }
        }
    }
}

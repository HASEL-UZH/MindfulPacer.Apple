//
//  CreateReviewReminderViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class CreateReviewReminderViewModel {
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let createReviewReminderUseCase: CreateReviewReminderUseCase
    private let triggerWatchNotificationUseCase: TriggerWatchNotificationUseCase
    
    // MARK: - Published Properties (State)
    
    var navigationPath: [CreateReviewReminderNavigationDestination] = []
    var activeSheet: CreateReviewReminderSheet? = nil
    var alertItem: AlertItem? = nil
    
    var isContinueButtonDisabled: Bool {
        guard let lastDestination = navigationPath.last else {
            return false
        }
        
        switch lastDestination {
        case .measurementType:
            return selectedMeasurementType == nil
        case .alarmType:
            return selectedAlarmType == nil
        case .threshold:
            return threshold == nil
        case .interval:
            return selectedInterval == nil
        case .summary:
            return (selectedMeasurementType == nil || selectedAlarmType == nil || threshold == nil || selectedInterval == nil)
        }
    }
    
    var showContinueButton: Bool {
        /// Check if the second-to-last element in the navigationPath is .summary
        if navigationPath.dropLast().last == .summary {
            return false
        }
        return true
    }
    
    var continueButtonTitle: String {
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
            "bpm"
        case .steps:
            "steps"
        case nil:
            ""
        }
    }
    
    var notificationPreviewBodyText: String {
        String("A review reminder was triggered because your \(selectedMeasurementType?.rawValue.lowercased() ?? "<MEASUREMENT TYPE>") exceeded the threshold of \(threshold ?? 0) \(thresholdUnitText.lowercased()) over a period of \(selectedInterval?.rawValue.lowercased() ?? "<INTERBAL>").")
    }
    
    var selectedMeasurementType: ReviewReminder.MeasurementType? = nil {
        didSet {
            validateThreshold()
        }
    }
    var threshold: Int? {
        didSet {
            validateThreshold()
        }
    }
    var selectedAlarmType: ReviewReminder.AlarmType? = nil
    var selectedInterval: ReviewReminder.Interval? = nil
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        createReviewReminderUseCase: CreateReviewReminderUseCase,
        triggerWatchNotificationUseCase: TriggerWatchNotificationUseCase
    ) {
        self.modelContext = modelContext
        self.createReviewReminderUseCase = createReviewReminderUseCase
        self.triggerWatchNotificationUseCase = triggerWatchNotificationUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {}
    
    // MARK: - User Actions
    
    func continueButtonTapped() {
        /// Check if we are on the first page
        guard let currentDestination = navigationPath.last else {
            navigationPath.append(CreateReviewReminderNavigationDestination.measurementType)
            return
        }
        
        switch currentDestination {
        case .measurementType:
            navigationPath.append(CreateReviewReminderNavigationDestination.alarmType)
        case .alarmType:
            navigationPath.append(CreateReviewReminderNavigationDestination.threshold)
        case .threshold:
            navigationPath.append(CreateReviewReminderNavigationDestination.interval)
        case .interval:
            navigationPath.append(CreateReviewReminderNavigationDestination.summary)
        case .summary:
            saveReviewReminder()
        }
    }
    
    func sendNotificationToWatch() {
        triggerWatchNotificationUseCase.execute(title: "Review Reminder", body: notificationPreviewBodyText) { result in
            switch result {
            case .success:
                print("DEBUGY: Notification sent successfully.")
            case .failure(let error):
                self.alertItem = AlertContext.unableToSendTestNotification
                print("DEBUGY: Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
    
    func presentSheet(_ sheet: CreateReviewReminderSheet) {
        activeSheet = sheet
    }
    
    func toggleSelection<T: Equatable>(_ item: T, selectedItem: inout T?) {
        selectedItem = (selectedItem == item) ? nil : item
    }
    
    // MARK: - Private Methods
    
    private func saveReviewReminder() {
        guard let measurementType = selectedMeasurementType,
              let alarmType = selectedAlarmType,
              let threshold,
              let interval = selectedInterval else { return }
        
        let result = createReviewReminderUseCase.execute(
            measurementType: measurementType,
            alarmType: alarmType,
            threshold: threshold,
            interval: interval
        )
        
        if case .failure(_) = result {
            alertItem = AlertContext.unableToSaveReviewReminder
        }
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

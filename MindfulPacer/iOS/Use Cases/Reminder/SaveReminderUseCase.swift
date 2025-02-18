//
//  SaveReminderUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import Foundation
import SwiftData

protocol SaveReminderUseCase {
    func execute(
        existingReminder: Reminder,
        newMeasurementType: MeasurementType,
        newReminderType: Reminder.ReminderType,
        newThreshold: Int,
        newInterval: Reminder.Interval

    ) -> Result<Reminder, Error>
}

// MARK: - Use Case Implementation

class DefaultSaveReminderUseCase: SaveReminderUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute(
        existingReminder: Reminder,
        newMeasurementType: MeasurementType,
        newReminderType: Reminder.ReminderType,
        newThreshold: Int,
        newInterval: Reminder.Interval
    ) -> Result<Reminder, any Error> {
        existingReminder.measurementType = newMeasurementType
        existingReminder.reminderType = newReminderType
        existingReminder.threshold = newThreshold
        existingReminder.interval = newInterval

        do {
            try modelContext.save()
            return .success(existingReminder)
        } catch {
            return .failure(error)
        }
    }
}

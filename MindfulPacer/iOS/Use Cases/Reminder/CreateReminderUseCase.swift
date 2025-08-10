//
//  CreateReminderUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import Foundation
import SwiftData
import WatchConnectivity

protocol CreateReminderUseCase {
    func execute(
        measurementType: MeasurementType,
        reminderType: Reminder.ReminderType,
        threshold: Int,
        interval: Reminder.Interval
    ) -> Result<Reminder, Error>
}

// MARK: - Use Case Implementation

class DefaultCreateReminderUseCase: CreateReminderUseCase {
    private let modelContext: ModelContext
    private let watchUpdateService: WatchUpdateService
    
    init(modelContext: ModelContext, watchUpdateService: WatchUpdateService) {
        self.modelContext = modelContext
        self.watchUpdateService = watchUpdateService
    }
    
    func execute(
        measurementType: MeasurementType,
        reminderType: Reminder.ReminderType,
        threshold: Int,
        interval: Reminder.Interval
    ) -> Result<Reminder, any Error> {
        let reminder = Reminder(
            measurementType: measurementType,
            reminderType: reminderType,
            threshold: threshold,
            interval: interval
        )
        
        modelContext.insert(reminder)
        
        do {
            try modelContext.save()
            watchUpdateService.notifyWatchOfReminderChange()
            return .success(reminder)
        } catch {
            return .failure(error)
        }
    }
}

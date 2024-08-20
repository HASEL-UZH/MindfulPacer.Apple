//
//  CreateReviewReminderUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import Foundation
import SwiftData

protocol CreateReviewReminderUseCase {
    func execute(
        measurementType: ReviewReminder.MeasurementType,
        alarmType: ReviewReminder.AlarmType,
        threshold: Int,
        vibrationStrength: ReviewReminder.VibrationStrength,
        interval: ReviewReminder.Interval
    ) -> Result<ReviewReminder, Error>
}

// MARK: - Use Case Implementation

class DefaultCreateReviewReminderUseCase: CreateReviewReminderUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(
        measurementType: ReviewReminder.MeasurementType,
        alarmType: ReviewReminder.AlarmType,
        threshold: Int,
        vibrationStrength: ReviewReminder.VibrationStrength,
        interval: ReviewReminder.Interval
    ) -> Result<ReviewReminder, any Error> {
        let reviewReminder = ReviewReminder(
            measurementType: measurementType,
            alarmType: alarmType,
            threshold: threshold,
            vibrationStrength: vibrationStrength,
            interval: interval
        )
        
        modelContext.insert(reviewReminder)
        
        do {
            try modelContext.save()
            return .success(reviewReminder)
        } catch {
            return .failure(error)
        }
    }
}

//
//  SaveReviewReminderUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import Foundation
import SwiftData

protocol SaveReviewReminderUseCase {
    func execute(
        existingReviewReminder: ReviewReminder,
        newMeasurementType: MeasurementType,
        newReviewReminderType: ReviewReminder.ReviewReminderType,
        newThreshold: Int,
        newInterval: ReviewReminder.Interval

    ) -> Result<ReviewReminder, Error>
}

// MARK: - Use Case Implementation

class DefaultSaveReviewReminderUseCase: SaveReviewReminderUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute(
        existingReviewReminder: ReviewReminder,
        newMeasurementType: MeasurementType,
        newReviewReminderType: ReviewReminder.ReviewReminderType,
        newThreshold: Int,
        newInterval: ReviewReminder.Interval
    ) -> Result<ReviewReminder, any Error> {
        existingReviewReminder.measurementType = newMeasurementType
        existingReviewReminder.reviewReminderType = newReviewReminderType
        existingReviewReminder.threshold = newThreshold
        existingReviewReminder.interval = newInterval

        do {
            try modelContext.save()
            return .success(existingReviewReminder)
        } catch {
            return .failure(error)
        }
    }
}

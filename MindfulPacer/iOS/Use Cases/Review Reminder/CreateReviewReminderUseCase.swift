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
        reviewReminderType: ReviewReminder.ReviewReminderType,
        threshold: Int,
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
        reviewReminderType: ReviewReminder.ReviewReminderType,
        threshold: Int,
        interval: ReviewReminder.Interval
    ) -> Result<ReviewReminder, any Error> {
        let reviewReminder = ReviewReminder(
            measurementType: measurementType,
            reviewReminderType: reviewReminderType,
            threshold: threshold,
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

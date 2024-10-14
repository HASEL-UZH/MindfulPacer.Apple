//
//  CreateReviewUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 14.08.2024.
//

import Foundation
import SwiftData

protocol CreateReviewUseCase {
    func execute(
        date: Date,
        category: Category?,
        subcategory: Subcategory?,
        mood: Mood?,
        didTriggerCrash: Bool,
        perceivedEnergyLevelRating: Int?,
        headachesRating: Int?,
        shortnessOfBreatheRating: Int?,
        feverRating: Int?,
        painsAndNeedlesRating: Int?,
        muscleAchesRating: Int?,
        additionalInformation: String,
        measurementType: ReviewReminder.MeasurementType?,
        reviewReminderType: ReviewReminder.ReviewReminderType?,
        threshold: Int?,
        interval: ReviewReminder.Interval?
    ) -> Result<Review, Error>
}

// MARK: - Use Case Implementation

class DefaulCreateReviewUseCase: CreateReviewUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute(
        date: Date,
        category: Category?,
        subcategory: Subcategory?,
        mood: Mood?,
        didTriggerCrash: Bool,
        perceivedEnergyLevelRating: Int?,
        headachesRating: Int?,
        shortnessOfBreatheRating: Int?,
        feverRating: Int?,
        painsAndNeedlesRating: Int?,
        muscleAchesRating: Int?,
        additionalInformation: String,
        measurementType: ReviewReminder.MeasurementType?,
        reviewReminderType: ReviewReminder.ReviewReminderType?,
        threshold: Int?,
        interval: ReviewReminder.Interval?
    ) -> Result<Review, Error> {
        let review = Review(
            date: date,
            category: category,
            subcategory: subcategory,
            mood: mood,
            didTriggerCrash: didTriggerCrash,
            perceivedEnergyLevelRating: perceivedEnergyLevelRating,
            headachesRating: headachesRating,
            shortnessOfBreatheRating: shortnessOfBreatheRating,
            feverRating: feverRating,
            painsAndNeedlesRating: painsAndNeedlesRating,
            muscleAchesRating: muscleAchesRating,
            additionalInformation: additionalInformation,
            measurementType: measurementType,
            reviewReminderType: reviewReminderType,
            threshold: threshold,
            interval: interval
        )

        modelContext.insert(review)

        do {
            try modelContext.save()
            return .success(review)
        } catch {
            return .failure(error)
        }
    }
}

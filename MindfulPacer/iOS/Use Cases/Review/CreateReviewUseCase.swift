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
        reviewReminder: ReviewReminder?
        // TODO: Instead of having a reference to a review reminder, store the fields like threshold, measurement type etc separately; this is for 2 reasons:
        // 1. If the user deletes a review reminder, the reference will be nil so this review will say it was created manually
        // 2. If the user changes the review reminder, this change will be reflected in the review, even though the state of the review reminder is now different to what it was when the review was created from the triggered review reminder
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
        reviewReminder: ReviewReminder?
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
            reviewReminder: reviewReminder
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

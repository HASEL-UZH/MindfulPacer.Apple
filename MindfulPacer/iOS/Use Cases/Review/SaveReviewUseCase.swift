//
//  SaveReviewUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import Foundation
import SwiftData

protocol SaveReviewUseCase {
    func execute(
        existingReview: Review,
        newDate: Date,
        newCategory: Category?,
        newSubcategory: Subcategory?,
        newMood: String?,
        newDidTriggerCrash: Bool,
        newPerceivedEnergyLevelRating: Int?,
        newHeadachesRating: Int?,
        newShortnessOfBreatheRating: Int?,
        newFeverRating: Int?,
        newPainsAndNeedlesRating: Int?,
        newMuscleAchesRating: Int?,
        newAdditionalInformation: String
    ) -> Result<Review, Error>
}

// MARK: - Use Case Implementation

class DefaultSaveReviewUseCase: SaveReviewUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute(
        existingReview: Review,
        newDate: Date,
        newCategory: Category?,
        newSubcategory: Subcategory?,
        newMood: String?,
        newDidTriggerCrash: Bool,
        newPerceivedEnergyLevelRating: Int?,
        newHeadachesRating: Int?,
        newShortnessOfBreatheRating: Int?,
        newFeverRating: Int?,
        newPainsAndNeedlesRating: Int?,
        newMuscleAchesRating: Int?,
        newAdditionalInformation: String
    ) -> Result<Review, any Error> {
        existingReview.date = newDate
        existingReview.category = newCategory
        existingReview.subcategory = newSubcategory
        existingReview.mood = newMood
        existingReview.didTriggerCrash = newDidTriggerCrash
        existingReview.perceivedEnergyLevelRating = newPerceivedEnergyLevelRating
        existingReview.headachesRating = newHeadachesRating
        existingReview.shortnessOfBreatheRating = newShortnessOfBreatheRating
        existingReview.feverRating = newFeverRating
        existingReview.painsAndNeedlesRating = newPainsAndNeedlesRating
        existingReview.muscleAchesRating = newMuscleAchesRating
        existingReview.additionalInformation = newAdditionalInformation

        do {
            try modelContext.save()
            return .success(existingReview)
        } catch {
            return .failure(error)
        }
    }
}

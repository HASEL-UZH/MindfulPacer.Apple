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
        newMood: Mood?,
        newDidTriggerCrash: Bool,
        newWellBeing: Symptom?,
        newFatigue: Symptom?,
        newShortnessOfBreath: Symptom?,
        newSleepDisorder: Symptom?,
        newCognitiveImpairment: Symptom,
        newPhysicalPain: Symptom?,
        newDepressionOrAnxiety: Symptom?,
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
        newMood: Mood?,
        newDidTriggerCrash: Bool,
        newWellBeing: Symptom?,
        newFatigue: Symptom?,
        newShortnessOfBreath: Symptom?,
        newSleepDisorder: Symptom?,
        newCognitiveImpairment: Symptom,
        newPhysicalPain: Symptom?,
        newDepressionOrAnxiety: Symptom?,
        newAdditionalInformation: String
    ) -> Result<Review, Error> {
        existingReview.date = newDate
        existingReview.category = newCategory
        existingReview.subcategory = newSubcategory
        existingReview.mood = newMood
        existingReview.didTriggerCrash = newDidTriggerCrash
        existingReview.wellBeing = newWellBeing
        existingReview.fatigue = newFatigue
        existingReview.shortnessOfBreath = newShortnessOfBreath
        existingReview.sleepDisorder = newSleepDisorder
        existingReview.cognitiveImpairment = newCognitiveImpairment
        existingReview.physicalPain = newPhysicalPain
        existingReview.depressionOrAnxiety = newDepressionOrAnxiety
        existingReview.additionalInformation = newAdditionalInformation
        
        do {
            try modelContext.save()
            return .success(existingReview)
        } catch {
            return .failure(error)
        }
    }
}

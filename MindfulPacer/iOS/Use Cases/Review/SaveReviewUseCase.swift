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
        newActivity: Activity?,
        newSubactivity: Subactivity?,
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
        newActivity: Activity?,
        newSubactivity: Subactivity?,
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
        existingReview.activity = newActivity
        existingReview.subactivity = newSubactivity
        existingReview.mood = newMood
        existingReview.didTriggerCrash = newDidTriggerCrash
        existingReview.wellBeing = newWellBeing?.value
        existingReview.fatigue = newFatigue?.value
        existingReview.shortnessOfBreath = newShortnessOfBreath?.value
        existingReview.sleepDisorder = newSleepDisorder?.value
        existingReview.cognitiveImpairment = newCognitiveImpairment.value
        existingReview.physicalPain = newPhysicalPain?.value
        existingReview.depressionOrAnxiety = newDepressionOrAnxiety?.value
        existingReview.additionalInformation = newAdditionalInformation
        
        do {
            try modelContext.save()
            return .success(existingReview)
        } catch {
            return .failure(error)
        }
    }
}

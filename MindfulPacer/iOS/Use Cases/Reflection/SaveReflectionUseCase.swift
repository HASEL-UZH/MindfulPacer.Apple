//
//  SaveReflectionUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import Foundation
import SwiftData

protocol SaveReflectionUseCase {
    @MainActor
    func execute(
        existingReflection: Reflection,
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
    ) -> Result<Reflection, Error>
}

// MARK: - Use Case Implementation

@MainActor
class DefaultSaveReflectionUseCase: SaveReflectionUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(
        existingReflection: Reflection,
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
    ) -> Result<Reflection, Error> {
        existingReflection.date = newDate
        existingReflection.activity = newActivity
        existingReflection.subactivity = newSubactivity
        existingReflection.mood = newMood
        existingReflection.didTriggerCrash = newDidTriggerCrash
        existingReflection.wellBeing = newWellBeing?.value
        existingReflection.fatigue = newFatigue?.value
        existingReflection.shortnessOfBreath = newShortnessOfBreath?.value
        existingReflection.sleepDisorder = newSleepDisorder?.value
        existingReflection.cognitiveImpairment = newCognitiveImpairment.value
        existingReflection.physicalPain = newPhysicalPain?.value
        existingReflection.depressionOrAnxiety = newDepressionOrAnxiety?.value
        existingReflection.additionalInformation = newAdditionalInformation
        
        do {
            try modelContext.save()
            
            BackgroundReflectionsStore.shared.upsert(.init(from: existingReflection))

            return .success(existingReflection)
        } catch {
            return .failure(error)
        }
    }
}

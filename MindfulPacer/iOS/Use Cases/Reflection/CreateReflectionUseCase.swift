//
//  CreateReflectionUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 14.08.2024.
//

import Foundation
import SwiftData

protocol CreateReflectionUseCase {
    func execute(
        date: Date,
        activity: Activity?,
        subactivity: Subactivity?,
        mood: Mood?,
        didTriggerCrash: Bool,
        wellBeing: Symptom?,
        fatigue: Symptom?,
        shortnessOfBreath: Symptom?,
        sleepDisorder: Symptom?,
        cognitiveImpairment: Symptom?,
        physicalPain: Symptom?,
        depressionOrAnxiety: Symptom?,
        additionalInformation: String,
        measurementType: Reminder.MeasurementType?,
        reminderType: Reminder.ReminderType?,
        threshold: Int?,
        interval: Reminder.Interval?,
        triggerSamples: [MeasurementSample],
        isRejected: Bool
    ) -> Result<Reflection, Error>
}

// MARK: - Use Case Implementation

class DefaultCreateReflectionUseCase: CreateReflectionUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(
        date: Date,
        activity: Activity?,
        subactivity: Subactivity?,
        mood: Mood?,
        didTriggerCrash: Bool,
        wellBeing: Symptom?,
        fatigue: Symptom?,
        shortnessOfBreath: Symptom?,
        sleepDisorder: Symptom?,
        cognitiveImpairment: Symptom?,
        physicalPain: Symptom?,
        depressionOrAnxiety: Symptom?,
        additionalInformation: String,
        measurementType: Reminder.MeasurementType?,
        reminderType: Reminder.ReminderType?,
        threshold: Int?,
        interval: Reminder.Interval?,
        triggerSamples: [MeasurementSample],
        isRejected: Bool
    ) -> Result<Reflection, Error> {
        let reflection = Reflection(
            date: date,
            activity: activity,
            subactivity: subactivity,
            mood: mood,
            didTriggerCrash: didTriggerCrash,
            wellBeing: wellBeing?.value,
            fatigue: fatigue?.value,
            shortnessOfBreath: shortnessOfBreath?.value,
            sleepDisorder: sleepDisorder?.value,
            cognitiveImpairment: cognitiveImpairment?.value,
            physicalPain: physicalPain?.value,
            depressionOrAnxiety: depressionOrAnxiety?.value,
            additionalInformation: additionalInformation,
            measurementType: measurementType,
            reminderType: reminderType,
            threshold: threshold,
            interval: interval,
            triggerSamples: triggerSamples,
            isRejected: isRejected
        )
        
        modelContext.insert(reflection)
        
        do {
            try modelContext.save()
            return .success(reflection)
        } catch {
            return .failure(error)
        }
    }
}

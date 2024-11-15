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
        measurementType: ReviewReminder.MeasurementType?,
        reviewReminderType: ReviewReminder.ReviewReminderType?,
        threshold: Int?,
        interval: ReviewReminder.Interval?
    ) -> Result<Review, Error> {
        let review = Review(
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

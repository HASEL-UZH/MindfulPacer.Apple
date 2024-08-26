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
        didTriggerCrash: Bool?,
        perceivedEnergyLevelRating: Int?,
        headachesRating: Int?,
        shortnessOfBreatheRating: Int?,
        feverRating: Int?,
        painsAndNeedlesRating: Int?,
        muscleAchesRating: Int?,
        additionalInformation: String?
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
        didTriggerCrash: Bool?,
        perceivedEnergyLevelRating: Int?,
        headachesRating: Int?,
        shortnessOfBreatheRating: Int?,
        feverRating: Int?,
        painsAndNeedlesRating: Int?,
        muscleAchesRating: Int?,
        additionalInformation: String?
    ) -> Result<Review, Error> {
        let review = Review(
            date: date,
            category: category,
            subcategory: subcategory,
            didTriggerCrash: didTriggerCrash,
            perceivedEnergyLevelRating: perceivedEnergyLevelRating,
            headachesRating: headachesRating,
            shortnessOfBreatheRating: shortnessOfBreatheRating,
            feverRating: feverRating,
            painsAndNeedlesRating: painsAndNeedlesRating,
            muscleAchesRating: muscleAchesRating,
            additionalInformation: additionalInformation
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

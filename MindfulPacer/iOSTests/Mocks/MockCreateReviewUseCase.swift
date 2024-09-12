//
//  MockCreateReviewUseCase.swift
//  MindfulPacerTests
//
//  Created by Grigor Dochev on 25.08.2024.
//

import Foundation
import XCTest

@testable import iOS

class MockCreateReviewUseCase: CreateReviewUseCase {
    var executeResult: Result<iOS.Review, Error> = .success(iOS.Review()) // Adjust the Review initializer to match your actual Review model

    func execute(
        date: Date,
        category: iOS.Category?,
        subcategory: iOS.Subcategory?,
        didTriggerCrash: Bool?,
        perceivedEnergyLevelRating: Int?,
        headachesRating: Int?,
        shortnessOfBreatheRating: Int?,
        feverRating: Int?,
        painsAndNeedlesRating: Int?,
        muscleAchesRating: Int?,
        additionalInformation: String?
    ) -> Result<iOS.Review, Error> {
        return executeResult
    }
}

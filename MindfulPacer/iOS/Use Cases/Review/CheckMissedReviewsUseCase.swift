//
//  CheckMissedReviewsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 03.01.2025.
//

import Foundation

protocol CheckMissedReviewsUseCase {
    func execute(
        reviewReminders: [ReviewReminder],
        actionedMissedReviewIDs: [String],
        completion: @escaping @Sendable (Result<[MissedReview], HealthKitError>) -> Void
    )
}

// MARK: - Use Case Implementation

final class DefaultCheckMissedReviewsUseCase: CheckMissedReviewsUseCase {
    private let healthKitService: HealthKitService
    
    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }
    
    func execute(
        reviewReminders: [ReviewReminder],
        actionedMissedReviewIDs: [String],
        completion: @escaping @Sendable (Result<[MissedReview], HealthKitError>) -> Void
    ) {
        healthKitService.checkMissedReviews(
            reminders: reviewReminders,
            actionedMissedReviewIDs: actionedMissedReviewIDs,
            completion: completion
        )
    }
}

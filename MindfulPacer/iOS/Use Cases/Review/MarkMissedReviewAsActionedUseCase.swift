//
//  MarkMissedReviewAsActionedUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 12.01.2025.
//

import Foundation

// MARK: - MarkMissedReviewAsActionedUseCase

protocol MarkMissedReviewAsActionedUseCase {
    func execute(missedReview: MissedReview)
}

// MARK: - Use Case Implementation

class DefaultMarkMissedReviewAsActionedUseCase: MarkMissedReviewAsActionedUseCase {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func execute(missedReview: MissedReview) {
        var actionedReviews = userDefaults.stringArray(forKey: MissedReview.actionedKey) ?? []
        if !actionedReviews.contains(missedReview.id) {
            actionedReviews.append(missedReview.id)
            userDefaults.set(actionedReviews, forKey: MissedReview.actionedKey)
        }
    }
}

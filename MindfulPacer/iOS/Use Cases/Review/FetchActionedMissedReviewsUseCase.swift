//
//  FetchActionedMissedReviewsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 12.01.2025.
//

import Foundation

// MARK: - FetchActionedMissedReviewsUseCase

protocol FetchActionedMissedReviewsUseCase {
    func execute() -> [String]
}

// MARK: - Use Case Implementation

class DefaultFetchActionedMissedReviewsUseCase: FetchActionedMissedReviewsUseCase {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func execute() -> [String] {
        userDefaults.stringArray(forKey: MissedReview.actionedKey) ?? []
    }
}

//
//  FetchReviewsInPeriodUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 24.09.2024.
//

import Foundation
import SwiftData

// MARK: - FetchReviewsInPeriodUseCase

protocol FetchReviewsInPeriodUseCase {
    func execute(period: Period) -> [Review]
}

// MARK: - Use Case Implementation

class DefaultFetchReviewsInPeriodUseCase: FetchReviewsInPeriodUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(period: Period) -> [Review] {
        do {
            let descriptor = FetchDescriptor<Review>(sortBy: [SortDescriptor(\Review.date, order: .reverse)])
                        
            let reviews = try modelContext.fetch(descriptor)
            let filteredReviews = reviews.filter { review in
                (review.date >= period.startDate && review.date <= Date())
            }
            
            return filteredReviews
        } catch {
            print("DEBUG: Could not fetch reviews: \(error)")
            return []
        }
    }
}

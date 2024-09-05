//
//  FilterReviewsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 05.09.2024.
//

import Foundation

import Foundation

protocol FilterReviewsUseCase {
    func execute(reviews: [Review], filters: HomeViewModel.ReviewFilter, sorting: HomeViewModel.ReviewSorting) -> [Review]
}

// MARK: - Use Case Implementation

class DefaultFilterReviewsUseCase: FilterReviewsUseCase {
    func execute(reviews: [Review], filters: HomeViewModel.ReviewFilter, sorting: HomeViewModel.ReviewSorting) -> [Review] {
        
        // Apply filtering with safety checks for optional properties
        let filteredReviews = reviews.filter { review in
            
            var matches = false
            
            // Filter by Category (match any category)
            if !filters.selectedCategories.isEmpty {
                matches = matches || (review.category.map { filters.selectedCategories.contains($0) } ?? false)
            }
            
            // Filter by Subcategory (match any subcategory)
            if !filters.selectedSubcategories.isEmpty {
                matches = matches || (review.subcategory.map { filters.selectedSubcategories.contains($0) } ?? false)
            }
            
            // Filter by Mood (matching emoji strings)
            if !filters.selectedMoods.isEmpty {
                matches = matches || (review.mood.map { moodEmoji in
                    filters.selectedMoods.contains { $0.emoji == moodEmoji }
                } ?? false)
            }
            
            // Filter by Triggered Crash (match if crash was triggered)
            if filters.triggeredCrash {
                matches = matches || review.didTriggerCrash
            }
            
            // If no filters are active, include all reviews
            if filters.activeFilterCount == 0 {
                matches = true
            }
            
            return matches
        }
        
        // Apply sorting
        let sortedReviews = filteredReviews.sorted(by: sorting.comparator)
        
        return sortedReviews
    }
}

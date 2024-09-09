//
//  FilterReviewsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 05.09.2024.
//

import Foundation

protocol FilterReviewsUseCase {
    func execute(reviews: [Review], filters: ReviewFilter, sorting: ReviewSorting) -> [Review]
}

// MARK: - Use Case Implementation

class DefaultFilterReviewsUseCase: FilterReviewsUseCase {
    func execute(reviews: [Review], filters: ReviewFilter, sorting: ReviewSorting) -> [Review] {
        
        // Adjust toDate to include the entire day (set time to 23:59:59)
        let adjustedToDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: filters.toDate) ?? filters.toDate
        
        let filteredReviews = reviews.filter { review in
            
            var matches = false
            
            // Check if date range filter is active
            let isDateFilterActive = filters.fromDate != .distantPast || filters.toDate != .distantFuture
            let isWithinDateRange = review.date >= filters.fromDate && review.date <= adjustedToDate
            
            // Check if any non-date filters are active
            let areOtherFiltersActive = filters.activeFilterCount > 0
            
            // If there are no non-date filters, only apply date range filter
            if !areOtherFiltersActive && isDateFilterActive {
                return isWithinDateRange
            }
            
            // Apply Category Filter (match any selected category)
            if !filters.selectedCategories.isEmpty {
                matches = matches || (review.category.map { filters.selectedCategories.contains($0) } ?? false)
            }
            
            // Apply Subcategory Filter (match any selected subcategory)
            if !filters.selectedSubcategories.isEmpty {
                matches = matches || (review.subcategory.map { filters.selectedSubcategories.contains($0) } ?? false)
            }
            
            // Apply Mood Filter (match any selected mood emoji)
            if !filters.selectedMoods.isEmpty {
                matches = matches || (review.mood.map { moodEmoji in
                    filters.selectedMoods.contains { $0.emoji == moodEmoji }
                } ?? false)
            }
            
            // Apply Triggered Crash Filter
            if filters.triggeredCrash {
                matches = matches || review.didTriggerCrash
            }
            
            // If date filter is active and other filters are applied, reviews must match both
            if isDateFilterActive {
                matches = matches && isWithinDateRange
            }
            
            return matches
        }
        
        // Apply sorting
        return filteredReviews.sorted(by: sorting.comparator)
    }
}

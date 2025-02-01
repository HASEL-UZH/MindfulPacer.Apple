//
//  FilterReflectionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 05.09.2024.
//

import Foundation

protocol FilterReflectionsUseCase {
    func execute(reflections: [Reflection], filters: ReflectionFilter, sorting: ReflectionSorting) -> [Reflection]
}

// MARK: - Use Case Implementation

class DefaultFilterReflectionsUseCase: FilterReflectionsUseCase {
    func execute(reflections: [Reflection], filters: ReflectionFilter, sorting: ReflectionSorting) -> [Reflection] {

        // Adjust toDate to include the entire day (set time to 23:59:59)
        let adjustedToDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: filters.toDate) ?? filters.toDate

        let filteredReflections = reflections.filter { reflection in

            var matches = false

            // Check if date range filter is active
            let isDateFilterActive = filters.fromDate != .distantPast || filters.toDate != .distantFuture
            let isWithinDateRange = reflection.date >= filters.fromDate && reflection.date <= adjustedToDate

            // Check if any non-date filters are active
            let areOtherFiltersActive = filters.activeFilterCount > 0

            // If there are no non-date filters, only apply date range filter
            if !areOtherFiltersActive && isDateFilterActive {
                return isWithinDateRange
            }

            // Apply Activity Filter (match any selected activity)
            if !filters.selectedActivities.isEmpty {
                matches = matches || (reflection.activity.map { filters.selectedActivities.contains($0) } ?? false)
            }

            // Apply Subactivity Filter (match any selected subactivity)
            if !filters.selectedSubactivities.isEmpty {
                matches = matches || (reflection.subactivity.map { filters.selectedSubactivities.contains($0) } ?? false)
            }

            // Apply Mood Filter (match any selected mood)
            if !filters.selectedMoods.isEmpty {
                matches = matches || (reflection.mood.map { filters.selectedMoods.contains($0) } ?? false)
            }

            // Apply Triggered Crash Filter
            if filters.triggeredCrash {
                matches = matches || reflection.didTriggerCrash
            }

            // If date filter is active and other filters are applied, reflections must match both
            if isDateFilterActive {
                matches = matches && isWithinDateRange
            }

            return matches
        }

        // Apply sorting
        return filteredReflections.sorted(by: sorting.comparator)
    }
}

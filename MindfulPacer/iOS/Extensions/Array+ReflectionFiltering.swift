//
//  Array+ReflectionFiltering.swift
//  iOS
//
//  Created by Grigor Dochev on 05.09.2024.
//
import Foundation

extension Array where Element == Reflection {
    /// Filters and sorts reflections based on provided filter and sorting criteria
    func filtered(by filters: ReflectionFilter, sorting: ReflectionSorting) -> [Reflection] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: filters.fromDate)
        let endExclusive = cal.startOfNextDay(for: filters.toDate)
        let dateRange = start..<endExclusive
        
        let isDateFilterActive = true
        let areOtherFiltersActive =
            !filters.selectedActivities.isEmpty ||
            !filters.selectedSubactivities.isEmpty ||
            !filters.selectedMoods.isEmpty ||
            filters.triggeredCrash
        
        let filteredReflections = self.filter { reflection in
            let isWithinDateRange = dateRange.contains(reflection.date)
            
            if isDateFilterActive && !areOtherFiltersActive {
                return isWithinDateRange
            }
            
            var matches = false
            
            if !filters.selectedActivities.isEmpty {
                if let activity = reflection.activity {
                    matches = matches || filters.selectedActivities.contains(activity)
                }
            }
            
            if !filters.selectedSubactivities.isEmpty {
                if let sub = reflection.subactivity {
                    matches = matches || filters.selectedSubactivities.contains(sub)
                }
            }
            
            if !filters.selectedMoods.isEmpty {
                if let mood = reflection.mood {
                    matches = matches || filters.selectedMoods.contains(mood)
                }
            }
            
            if filters.triggeredCrash {
                matches = matches || reflection.didTriggerCrash
            }
            
            return (isDateFilterActive ? (matches && isWithinDateRange) : matches)
        }
        
        return filteredReflections.sorted(by: sorting.comparator)
    }
}

// MARK: - Calendar Extension

extension Calendar {
    func startOfNextDay(for date: Date) -> Date {
        let startOfDay = self.startOfDay(for: date)
        return self.date(byAdding: .day, value: 1, to: startOfDay) ?? date
    }
}

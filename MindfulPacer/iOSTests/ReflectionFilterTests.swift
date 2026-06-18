//
//  ReflectionFilterTests.swift
//  iOSTests
//
//  Tests for `ReflectionFilter` and `ReflectionSorting`, which drive the
//  Reviews Filter screen. Users can filter their reflection history by date
//  range, activities, subactivities, moods, and whether a crash was triggered.
//  The `activeFilterCount` property shows a badge count on the filter button,
//  and `ReflectionSorting` controls whether reflections appear newest-first
//  or oldest-first.
//

import Testing
import Foundation
@testable import iOS

// MARK: - ReflectionFilter.activeFilterCount

/// Validates that `activeFilterCount` correctly tallies the number of active
/// filter criteria. This count is displayed as a badge on the "Filters" button
/// so the user knows how many filters are active at a glance.
struct ReflectionFilterCountTests {

    /// A freshly created filter has no active criteria, so the count should be 0.
    @Test func activeFilterCount_default_isZero() {
        let filter = ReflectionFilter()
        #expect(filter.activeFilterCount == 0)
    }

    /// Each selected activity adds 1 to the count.
    @Test func activeFilterCount_withActivities() {
        var filter = ReflectionFilter()
        filter.selectedActivities = [Activity(name: "Walking", icon: "figure.walk")]
        #expect(filter.activeFilterCount == 1)
    }

    /// Each selected subactivity adds 1 to the count.
    @Test func activeFilterCount_withSubactivities() {
        var filter = ReflectionFilter()
        filter.selectedSubactivities = [
            Subactivity(name: "Running", icon: "figure.run"),
            Subactivity(name: "Hiking", icon: "figure.hiking")
        ]
        #expect(filter.activeFilterCount == 2)
    }

    /// Each selected mood adds 1 to the count.
    @Test func activeFilterCount_withMoods() {
        var filter = ReflectionFilter()
        filter.selectedMoods = [Mood(emoji: "😊", text: "Happy")]
        #expect(filter.activeFilterCount == 1)
    }

    /// The "triggered crash" toggle adds 1 when enabled.
    @Test func activeFilterCount_withTriggeredCrash() {
        var filter = ReflectionFilter()
        filter.triggeredCrash = true
        #expect(filter.activeFilterCount == 1)
    }

    /// Multiple filter criteria should accumulate.
    @Test func activeFilterCount_combinedFilters() {
        var filter = ReflectionFilter()
        filter.selectedActivities = [Activity(name: "Work", icon: "briefcase")]
        filter.selectedMoods = [Mood(emoji: "😢", text: "Sad"), Mood(emoji: "😡", text: "Angry")]
        filter.triggeredCrash = true
        // 1 activity + 2 moods + 1 crash = 4
        #expect(filter.activeFilterCount == 4)
    }
}

// MARK: - ReflectionSorting

/// Validates that `ReflectionSorting.comparator` produces the correct ordering.
/// The analytics and review screens use this to display reflections chronologically.
struct ReflectionSortingTests {

    /// `.dateAscending` should sort older dates first.
    @Test func dateAscending_sortsOlderFirst() {
        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)
        let comparator = ReflectionSorting.dateAscending.comparator
        // comparator returns true when the first argument should be ordered before the second
        #expect(comparator(makeFakeReflection(date: earlier), makeFakeReflection(date: later)) == true)
        #expect(comparator(makeFakeReflection(date: later), makeFakeReflection(date: earlier)) == false)
    }

    /// `.dateDescending` should sort newer dates first.
    @Test func dateDescending_sortsNewerFirst() {
        let earlier = Date(timeIntervalSince1970: 1000)
        let later = Date(timeIntervalSince1970: 2000)
        let comparator = ReflectionSorting.dateDescending.comparator
        #expect(comparator(makeFakeReflection(date: later), makeFakeReflection(date: earlier)) == true)
        #expect(comparator(makeFakeReflection(date: earlier), makeFakeReflection(date: later)) == false)
    }

    /// Helper to create a minimal Reflection with a specific date.
    private func makeFakeReflection(date: Date) -> Reflection {
        Reflection(
            date: date,
            wellBeing: nil,
            fatigue: nil,
            shortnessOfBreath: nil,
            sleepDisorder: nil,
            cognitiveImpairment: nil,
            physicalPain: nil,
            depressionOrAnxiety: nil
        )
    }
}

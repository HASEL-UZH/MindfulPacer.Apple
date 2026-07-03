//
//  ReflectionsFilterViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 07.09.2024.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - Reflection Filter & Sorting

struct ReflectionFilter: Equatable {
    var selectedActivities: [Activity] = []
    var selectedSubactivities: [Subactivity] = []
    var selectedMoods: [Mood] = []
    var triggeredCrash: Bool = false
    
    var fromDate: Date = Calendar.current.date(byAdding: .weekOfMonth, value: -2, to: Date()) ?? Date()
    var toDate: Date = Date()
    
    var dateRange: Range<Date> {
        let cal = Calendar.current
        let start = cal.startOfDay(for: fromDate)
        let endExclusive = cal.startOfNextDay(for: toDate)
        return start..<endExclusive
    }
    
    var activeFilterCount: Int {
        var count = 0
        count += selectedActivities.count
        count += selectedSubactivities.count
        count += selectedMoods.count
        count += triggeredCrash ? 1 : 0
        return count
    }
}

enum ReflectionSorting: CaseIterable, Hashable {
    case dateAscending
    case dateDescending

    var title: String {
        switch self {
        case .dateAscending: return String(localized: "Oldest First")
        case .dateDescending: return String(localized: "Newest First")
        }
    }

    var systemImage: String {
        switch self {
        case .dateAscending: return "arrow.up"
        case .dateDescending: return "arrow.down"
        }
    }
    
    var comparator: (Reflection, Reflection) -> Bool {
        switch self {
        case .dateAscending: return { $0.date < $1.date }
        case .dateDescending: return { $0.date > $1.date }
        }
    }
}

// MARK: - ReflectionsFilterViewModel

@MainActor
@Observable
class ReflectionsFilterViewModel {
    
    // MARK: - Dependencies
    
    // No dependencies needed - activities passed from view
    
    // MARK: - Published Properties
    
    var triggeredCrashBinding: Binding<Bool> {
        Binding(
            get: { self.reviewFilter.triggeredCrash },
            set: { self.updateTriggeredCrash($0) }
        )
    }
    
    var reviewSortingBinding: Binding<ReflectionSorting> {
        Binding(
            get: { self.reviewSorting },
            set: { self.updateSorting($0) }
        )
    }
    
    var fromDateBinding: Binding<Date> {
        Binding(
            get: { self.reviewFilter.fromDate },
            set: { self.updateFromDate($0) }
        )
    }
    
    var toDateBinding: Binding<Date> {
        Binding(
            get: { self.reviewFilter.toDate },
            set: { self.updateToDate($0) }
        )
    }
    
    var activities: [Activity] = []
    var subactivities: [Subactivity] {
        activities.flatMap { $0.subactivities ?? [] }
    }
    var reviewFilter = ReflectionFilter()
    var reviewSorting = ReflectionSorting.dateDescending
    
    var filterButtonTitle: String {
        reviewFilter.activeFilterCount == 0 ? "Filters" : "Filters (\(reviewFilter.activeFilterCount))"
    }
    
    var selectedFilterActivitiesSummary: String {
        reviewFilter.selectedActivities.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFilterSubactivitiesSummary: String {
        reviewFilter.selectedSubactivities.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFilterMoodsSummary: String {
        reviewFilter.selectedMoods.map { $0.text }.joined(separator: ", ")
    }

    var hasActiveFilters: Bool {
        reviewFilter.activeFilterCount > 0 ||
        !isDefaultDateRange ||
        reviewSorting != .dateDescending
    }

    var navigationSubtitle: String {
        activeControlCount == 0
            ? String(localized: "Default date range")
            : String(localized: "\(activeControlCount) active")
    }

    var dateRangeSummary: String {
        reviewFilter.fromDate.formatted(.dateTime.day().month().year()) + " - " +
        reviewFilter.toDate.formatted(.dateTime.day().month().year())
    }

    var activitiesSubtitle: String {
        selectionSubtitle(reviewFilter.selectedActivities.count)
    }

    var subactivitiesSubtitle: String {
        selectionSubtitle(reviewFilter.selectedSubactivities.count)
    }

    var moodsSubtitle: String {
        selectionSubtitle(reviewFilter.selectedMoods.count)
    }

    var crashSubtitle: String {
        reviewFilter.triggeredCrash ? String(localized: "Triggered only") : String(localized: "All")
    }

    var sortingSubtitle: String {
        reviewSorting.title
    }

    private var isDefaultDateRange: Bool {
        let defaultFilter = ReflectionFilter()
        return Calendar.current.isDate(reviewFilter.fromDate, inSameDayAs: defaultFilter.fromDate) &&
        Calendar.current.isDate(reviewFilter.toDate, inSameDayAs: defaultFilter.toDate)
    }

    private var activeControlCount: Int {
        reviewFilter.activeFilterCount +
        (isDefaultDateRange ? 0 : 1) +
        (reviewSorting == .dateDescending ? 0 : 1)
    }
    
    // MARK: - Private Properties
    
    private var filterAndSortingPublisher: CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
    }
    
    func updateActivities(_ newActivities: [Activity]) {
        activities = newActivities
    }
    
    func setPublisher(_ publisher: CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>?) {
        self.filterAndSortingPublisher = publisher
        bindToPublisher()
    }
    
    // MARK: - User Actions
    
    func resetFilters() {
        if reviewFilter != ReflectionFilter() || reviewSorting != .dateDescending {
            reviewFilter = ReflectionFilter()
            reviewSorting = .dateDescending
            publishChanges()
        }
    }
    
    func toggleFilterActivity(_ activity: Activity) {
        toggleSelection(in: &reviewFilter.selectedActivities, item: activity)
        publishChanges()
    }
    
    func toggleFilterSubactivity(_ subactivity: Subactivity) {
        toggleSelection(in: &reviewFilter.selectedSubactivities, item: subactivity)
        publishChanges()
    }
    
    func toggleFilterMood(_ mood: Mood) {
        toggleSelection(in: &reviewFilter.selectedMoods, item: mood)
        publishChanges()
    }
    
    func toggleTriggeredCrash() {
        reviewFilter.triggeredCrash.toggle()
        publishChanges()
    }
    
    func updateTriggeredCrash(_ isOn: Bool) {
        reviewFilter.triggeredCrash = isOn
        publishChanges()
    }
    
    func updateSorting(_ sorting: ReflectionSorting) {
        reviewSorting = sorting
        publishChanges()
    }
    
    // MARK: - Private Methods
    
    private func bindToPublisher() {
        filterAndSortingPublisher?
            .sink { [weak self] (filter, sorting) in
                self?.reviewFilter = filter
                self?.reviewSorting = sorting
            }
            .store(in: &cancellables)
    }
    
    private func publishChanges() {
        filterAndSortingPublisher?.send((reviewFilter, reviewSorting))
    }
    
    private func toggleSelection<T: Equatable>(in list: inout [T], item: T) {
        if let index = list.firstIndex(of: item) {
            list.remove(at: index)
        } else {
            list.append(item)
        }
    }

    private func selectionSubtitle(_ count: Int) -> String {
        count == 0 ? String(localized: "All") : String(localized: "\(count) selected")
    }
    
    private func updateFromDate(_ fromDate: Date) {
        if fromDate > reviewFilter.toDate {
            reviewFilter.fromDate = reviewFilter.toDate
        } else {
            reviewFilter.fromDate = fromDate
        }
        publishChanges()
    }
    
    private func updateToDate(_ toDate: Date) {
        if toDate < reviewFilter.fromDate {
            reviewFilter.toDate = reviewFilter.fromDate
        } else {
            reviewFilter.toDate = toDate
        }
        publishChanges()
    }
}

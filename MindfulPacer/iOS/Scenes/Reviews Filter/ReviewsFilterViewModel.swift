//
//  ReviewsFilterViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 07.09.2024.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - Review Filter & Sorting

struct ReviewFilter: Equatable {
    var selectedActivities: [Activity] = []
    var selectedSubactivities: [Subactivity] = []
    var selectedMoods: [Mood] = []
    var triggeredCrash: Bool = false

    var fromDate: Date = Calendar.current.date(byAdding: .weekOfMonth, value: -2, to: Date()) ?? Date()
    var toDate: Date = Date()

    var activeFilterCount: Int {
        var count = 0
        count += selectedActivities.count
        count += selectedSubactivities.count
        count += selectedMoods.count
        count += triggeredCrash ? 1 : 0
        return count
    }
}

enum ReviewSorting {
    case dateAscending
    case dateDescending

    var comparator: (Review, Review) -> Bool {
        switch self {
        case .dateAscending: return { $0.date < $1.date }
        case .dateDescending: return { $0.date > $1.date }
        }
    }
}

// MARK: - ReviewsFilterViewModel

@MainActor
@Observable
class ReviewsFilterViewModel {
    
    // MARK: - Dependencies

    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase

    // MARK: - Published Properties

    var triggeredCrashBinding: Binding<Bool> {
        Binding(
            get: { self.reviewFilter.triggeredCrash },
            set: { self.updateTriggeredCrash($0) }
        )
    }

    var reviewSortingBinding: Binding<ReviewSorting> {
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
    var reviewFilter = ReviewFilter()
    var reviewSorting = ReviewSorting.dateDescending
    
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

    // MARK: - Private Properties

    private var filterAndSortingPublisher: CurrentValueSubject<(ReviewFilter, ReviewSorting), Never>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase) {
        self.fetchDefaultActivitiesUseCase = fetchDefaultActivitiesUseCase
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear() {
        fetchDefaultReviewActivities()
    }

    func setPublisher(_ publisher: CurrentValueSubject<(ReviewFilter, ReviewSorting), Never>?) {
        self.filterAndSortingPublisher = publisher
        bindToPublisher()
    }

    // MARK: - User Actions

    func resetFilters() {
        if reviewFilter != ReviewFilter() || reviewSorting != .dateDescending {
            reviewFilter = ReviewFilter()
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

    func updateSorting(_ sorting: ReviewSorting) {
        reviewSorting = sorting
        publishChanges()
    }

    // MARK: - Private Methods

    private func fetchDefaultReviewActivities() {
        self.activities = fetchDefaultActivitiesUseCase.execute() ?? []
    }

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

    private func updateFromDate(_ fromDate: Date) {
        reviewFilter.fromDate = fromDate
        publishChanges()
    }

    private func updateToDate(_ toDate: Date) {
        reviewFilter.toDate = toDate
        publishChanges()
    }
}

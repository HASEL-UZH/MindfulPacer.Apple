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

@MainActor
@Observable
class ReviewsFilterViewModel {
    // MARK: - Dependencies
    
    private let fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase
    
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
    
    var categories: [Category] = []
    var subcategories: [Subcategory] {
        categories.flatMap { $0.subcategories ?? [] }
    }
    var reviewFilter = ReviewFilter()
    var reviewSorting = ReviewSorting.dateDescending
    
    var filterButtonTitle: String {
        reviewFilter.activeFilterCount == 0 ? "Filters" : "Filters (\(reviewFilter.activeFilterCount))"
    }
    
    var selectedFilterCategoriesSummary: String {
        reviewFilter.selectedCategories.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFilterSubcategoriesSummary: String {
        reviewFilter.selectedSubcategories.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFilterMoodsSummary: String {
        reviewFilter.selectedMoods.map { $0.description }.joined(separator: ", ")
    }
    
    // MARK: - Private Properties
    
    private var filterAndSortingPublisher: CurrentValueSubject<(ReviewFilter, ReviewSorting), Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase) {
        self.fetchDefaultCategoriesUseCase = fetchDefaultCategoriesUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchDefaultReviewCategories()
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
    
    func toggleFilterCategory(_ category: Category) {
        toggleSelection(in: &reviewFilter.selectedCategories, item: category)
        publishChanges()
    }
    
    func toggleFilterSubcategory(_ subcategory: Subcategory) {
        toggleSelection(in: &reviewFilter.selectedSubcategories, item: subcategory)
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
    
    /// Fetches default categories for the filter.
    private func fetchDefaultReviewCategories() {
        self.categories = fetchDefaultCategoriesUseCase.execute() ?? []
    }
    
    /// Binds the publisher to listen for updates to the filter and sorting criteria.
    private func bindToPublisher() {
        filterAndSortingPublisher?
            .sink { [weak self] (filter, sorting) in
                self?.reviewFilter = filter
                self?.reviewSorting = sorting
            }
            .store(in: &cancellables)
    }
    
    /// Publishes any changes in the filter or sorting properties to the subscribers.
    private func publishChanges() {
        filterAndSortingPublisher?.send((reviewFilter, reviewSorting))
    }
    
    /// Toggles the selection of an item in a list.
    private func toggleSelection<T: Equatable>(in list: inout [T], item: T) {
        if let index = list.firstIndex(of: item) {
            list.remove(at: index)
        } else {
            list.append(item)
        }
    }
}

// MARK: - Review Filter & Sorting

typealias ReviewFilter = ReviewsFilterViewModel.ReviewFilter
typealias ReviewSorting = ReviewsFilterViewModel.ReviewSorting

extension ReviewsFilterViewModel {
    struct ReviewFilter: Equatable {
        var selectedCategories: [Category] = []
        var selectedSubcategories: [Subcategory] = []
        var selectedMoods: [Mood] = []
        var triggeredCrash: Bool = false
        
        var activeFilterCount: Int {
            var count = 0
            count += selectedCategories.count
            count += selectedSubcategories.count
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
}

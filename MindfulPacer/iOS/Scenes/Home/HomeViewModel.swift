//
//  HomeViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class HomeViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let deleteReviewUseCase: DeleteReviewUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    private let filterReviewsUseCase: FilterReviewsUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: HomeViewSheet? = nil
    var reviewFilter: ReviewFilter = ReviewFilter()
    var reviewSorting: ReviewSorting = .dateDescending
    var reviews: [Review] = []
    var filteredReviews: [Review] = []
    
    var recentReviews: [Review] {
        Array(reviews.prefix(3))
    }
    
    var reviewReminders: [ReviewReminder] = []
    var recentReviewReminders: [ReviewReminder] {
        Array(reviewReminders.prefix(3))
    }
    
    var currentSteps: (stepCount: Double, timestamp: Date)? = nil
    
    var filterButtonTitle: String {
        let (filter, _) = filterAndSortingPublisher.value
        return filter.activeFilterCount == 0 ? "Filters" : "Filters (\(filter.activeFilterCount))"
    }
    
    // MARK: - Private Properties
    
    var filterAndSortingPublisher = CurrentValueSubject<(ReviewFilter, ReviewSorting), Never>((ReviewFilter(), .dateDescending))
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        deleteReviewUseCase: DeleteReviewUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase,
        filterReviewsUseCase: FilterReviewsUseCase
    ) {
        self.modelContext = modelContext
        self.deleteReviewUseCase = deleteReviewUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
        self.filterReviewsUseCase = filterReviewsUseCase
        setupBindings()
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchCurrentSteps()
        fetchReviews()
        fetchReviewReminders()
    }
    
    func onSheetDismissed() {
        fetchReviews()
        fetchReviewReminders()
    }
    
    // MARK: - User Actions
    
    func toggleFilterCategory(_ category: Category) {
        updateFilter {
            if reviewFilter.selectedCategories.contains(category) {
                reviewFilter.selectedCategories.removeAll { $0 == category }
            } else {
                reviewFilter.selectedCategories.append(category)
            }
        }
    }
    
    func toggleFilterSubcategory(_ subcategory: Subcategory) {
        updateFilter {
            if reviewFilter.selectedSubcategories.contains(subcategory) {
                reviewFilter.selectedSubcategories.removeAll { $0 == subcategory }
            } else {
                reviewFilter.selectedSubcategories.append(subcategory)
            }
        }
    }
    
    func toggleFilterMood(_ mood: Mood) {
        updateFilter {
            if reviewFilter.selectedMoods.contains(mood) {
                reviewFilter.selectedMoods.removeAll { $0 == mood }
            } else {
                reviewFilter.selectedMoods.append(mood)
            }
        }
    }
    
    func toggleTriggeredCrash() {
        updateFilter {
            reviewFilter.triggeredCrash.toggle()
        }
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: HomeViewSheet) {
        activeSheet = sheet
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        filterAndSortingPublisher
            .sink { [weak self] newFilter, newSorting in
                guard let self = self else { return }
                self.reviewFilter = newFilter
                self.reviewSorting = newSorting
                self.applyFilterAndSorting(newFilter, newSorting)
            }
            .store(in: &cancellables)
    }
    
    private func applyFilterAndSorting(_ filter: ReviewFilter, _ sorting: ReviewSorting) {
        filteredReviews = filterReviewsUseCase.execute(
            reviews: reviews,
            filters: filter,
            sorting: sorting
        )
    }
    
    private func updateFilter(_ updateBlock: () -> Void) {
        updateBlock()
        filterAndSortingPublisher.send((reviewFilter, reviewSorting))
    }
    
    private func fetchCurrentSteps() {
        fetchCurrentStepsUseCase.execute { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let success):
                    self.currentSteps = success
                case .failure(let failure):
                    print("DEBUG: Could not fetch current steps: \(failure)")
                }
            }
        }
    }
    
    private func fetchReviews() {
        reviews = fetchReviewsUseCase.execute() ?? []
        applyFilterAndSorting(reviewFilter, reviewSorting)
    }
    
    private func fetchReviewReminders() {
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
    }
}

//
//  HomeViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

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
    private let fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    private let filterReviewsUseCase: FilterReviewsUseCase
    
    // MARK: - Published Properties (State)
    
    var activeSheet: HomeViewSheet? = nil
    
    var reviewFilter: ReviewFilter = ReviewFilter() {
        didSet { applyCurrentFilters() }
    }
    var reviewSorting: ReviewSorting = .dateDescending {
        didSet { applyCurrentFilters() }
    }
    
    var categories: [Category] = []
    
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
    
    var selectedFilterCategoriesSummary: String {
        reviewFilter.selectedCategories.map { $0.name }.joined(separator: ", ")
    }
    
    var selectedFilterMoodsSummary: String {
        reviewFilter.selectedMoods.map { $0.description }.joined(separator: ", ")
    }
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        deleteReviewUseCase: DeleteReviewUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase,
        filterReviewsUseCase: FilterReviewsUseCase
    ) {
        self.modelContext = modelContext
        self.deleteReviewUseCase = deleteReviewUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchDefaultCategoriesUseCase = fetchDefaultCategoriesUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
        self.filterReviewsUseCase = filterReviewsUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchCurrentSteps()
        fetchDefaultReviewCategories()
        fetchReviews()
        fetchReviewReminders()
    }
    
    func onSheetDismissed() {
        fetchReviews()
        fetchReviewReminders()
    }
    
    // MARK: - User Actions
    
    func applyFilters(_ filters: ReviewFilter, sorting: ReviewSorting) {
        reviewFilter = filters
        reviewSorting = sorting
        filteredReviews = filterReviewsUseCase.execute(reviews: reviews, filters: reviewFilter, sorting: reviewSorting)
    }
    
    func resetFilters() {
        reviewFilter = ReviewFilter()
        reviewSorting = .dateDescending
    }
    
    func toggleFilterCategory(_ category: Category) {
        if reviewFilter.selectedCategories.contains(category) {
            reviewFilter.selectedCategories.removeAll { $0 == category }
        } else {
            reviewFilter.selectedCategories.append(category)
        }
    }
    
    func toggleFilterMood(_ mood: Mood) {
        if reviewFilter.selectedMoods.contains(mood) {
            reviewFilter.selectedMoods.removeAll { $0 == mood }
        } else {
            reviewFilter.selectedMoods.append(mood)
        }
    }
    
    func toggleTriggeredCrash() {
        reviewFilter.triggeredCrash.toggle()
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: HomeViewSheet) {
        activeSheet = sheet
    }
    
    // MARK: - Private Methods
    
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
    
    private func fetchDefaultReviewCategories() {
        self.categories = fetchDefaultCategoriesUseCase.execute() ?? []
    }
    
    private func fetchReviews() {
        let reviews = fetchReviewsUseCase.execute() ?? []
        self.reviews = reviews
        applyCurrentFilters()
    }
    
    private func fetchReviewReminders() {
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
    }
    
    private func applyCurrentFilters() {
        if reviewFilter.activeFilterCount == 0 {
            filteredReviews = reviews
        } else {
            filteredReviews = filterReviewsUseCase.execute(reviews: reviews, filters: reviewFilter, sorting: reviewSorting)
        }
    }
}

// MARK: - Review Filter & Sorting

extension HomeViewModel {
    struct ReviewFilter: Equatable {
        var selectedCategories: [Category] = []
        var selectedSubcategories: [Subcategory] = []
        var selectedMoods: [Mood] = []
        var triggeredCrash: Bool = false
        
        var activeFilterCount: Int {
            var count = 0
            if !selectedCategories.isEmpty {
                count += 1
            }
            if !selectedSubcategories.isEmpty {
                count += 1
            }
            if !selectedMoods.isEmpty {
                count += 1
            }
            if triggeredCrash {
                count += 1
            }
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

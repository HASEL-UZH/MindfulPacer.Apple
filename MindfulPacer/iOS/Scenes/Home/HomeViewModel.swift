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
    // MARK: - Review Filter

    struct ReviewFilterOptions: Equatable {
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
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let deleteReviewUseCase: DeleteReviewUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    
    // MARK: - Published Properties (State)
    
    var activeSheet: HomeViewSheet? = nil
    
    var reviews: [Review] = []
    var reviewReminders: [ReviewReminder] = []
    var categories: [Category] = []
    var recentReviews: [Review] {
        Array(reviews.prefix(3))
    }
    var recentReviewReminders: [ReviewReminder] {
        Array(reviewReminders.prefix(3))
    }
    var currentSteps: (stepCount: Double, timestamp: Date)? = nil

    var reviewFilterOptions: ReviewFilterOptions = ReviewFilterOptions()
    var reviewSorting: ReviewSorting = .dateAscending
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        deleteReviewUseCase: DeleteReviewUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    ) {
        self.modelContext = modelContext
        self.deleteReviewUseCase = deleteReviewUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchDefaultCategoriesUseCase = fetchDefaultCategoriesUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchCurrentSteps()
        fetchDefaultCategories()
        fetchReviews()
        fetchReviewReminders()
    }
    
    func onSheetDismissed() {
        fetchReviews()
        fetchReviewReminders()
    }
    
    // MARK: - User Actions
    
    func updateReviewFilterOptions(with category: Category) {
        if reviewFilterOptions.selectedCategories.contains(category) {
            reviewFilterOptions.selectedCategories.removeAll { $0 == category }
        } else {
            reviewFilterOptions.selectedCategories.append(category)
        }
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
    
    private func fetchDefaultCategories() {
        if let fetchedCategories = fetchDefaultCategoriesUseCase.execute() {
            categories = fetchedCategories
        }
    }
    
    private func fetchReviews() {
        reviews = fetchReviewsUseCase.execute() ?? []
    }
    
    private func fetchReviewReminders() {
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
    }
}

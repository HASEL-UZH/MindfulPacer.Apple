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
import CocoaLumberjackSwift

// MARK: - HomeViewModel

@MainActor
@Observable
class HomeViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    private let filterReviewsUseCase: FilterReviewsUseCase

    // MARK: - Published Properties

    var activeSheet: HomeViewSheet?
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

    var currentSteps: (stepCount: Double, timestamp: Date)?
    var currentHeartRate: (heartRate: Double, timestamp: Date)?

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
        fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase,
        filterReviewsUseCase: FilterReviewsUseCase
    ) {
        self.modelContext = modelContext
        self.fetchCurrentHeartRateUseCase = fetchCurrentHeartRateUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
        self.filterReviewsUseCase = filterReviewsUseCase
        DDLogInfo("HomeViewModel initialized")
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear() {
        DDLogInfo("onViewFirstAppear called")
        setupBindings()
    }

    func onViewAppear() {
        DDLogInfo("onViewAppear called")
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchReviews()
        fetchReviewReminders()
    }
    
    func onSheetDismissed() {
        DDLogInfo("onSheetDismissed called")
        fetchReviews()
        fetchReviewReminders()
    }

    // MARK: - User Actions

    func toggleFilterActivity(_ activity: Activity) {
        DDLogInfo("toggleFilterActivity: \(activity.name)")
        updateFilter {
            if reviewFilter.selectedCategories.contains(activity) {
                reviewFilter.selectedCategories.removeAll { $0 == activity }
            } else {
                reviewFilter.selectedCategories.append(activity)
            }
        }
    }

    func toggleFilterSubactivity(_ subactivity: Subactivity) {
        DDLogInfo("toggleFilterSubactivity: \(subactivity.name)")
        updateFilter {
            if reviewFilter.selectedSubcategories.contains(subactivity) {
                reviewFilter.selectedSubcategories.removeAll { $0 == subactivity }
            } else {
                reviewFilter.selectedSubcategories.append(subactivity)
            }
        }
    }

    func toggleFilterMood(_ mood: Mood) {
        DDLogInfo("toggleFilterMood: \(mood.emoji)")
        updateFilter {
            if reviewFilter.selectedMoods.contains(mood) {
                reviewFilter.selectedMoods.removeAll { $0 == mood }
            } else {
                reviewFilter.selectedMoods.append(mood)
            }
        }
    }

    func toggleTriggeredCrash() {
        DDLogInfo("toggleTriggeredCrash")
        updateFilter {
            reviewFilter.triggeredCrash.toggle()
        }
    }

    // MARK: - Presentation

    func presentSheet(_ sheet: HomeViewSheet) {
        DDLogInfo("presentSheet: \(sheet)")
        activeSheet = sheet
    }

    // MARK: - Private Methods

    private func setupBindings() {
        DDLogInfo("Setting up bindings")
        filterAndSortingPublisher
            .sink { [weak self] newFilter, newSorting in
                guard let self = self else { return }
                DDLogInfo("Filter and sorting updated")
                self.reviewFilter = newFilter
                self.reviewSorting = newSorting
                self.applyFilterAndSorting(newFilter, newSorting)
            }
            .store(in: &cancellables)
    }

    private func applyFilterAndSorting(_ filter: ReviewFilter, _ sorting: ReviewSorting) {
        DDLogInfo("Applying filter and sorting")
        filteredReviews = filterReviewsUseCase.execute(
            reviews: reviews,
            filters: filter,
            sorting: sorting
        )
    }

    private func updateFilter(_ updateBlock: () -> Void) {
        DDLogInfo("Updating filter")
        updateBlock()
        filterAndSortingPublisher.send((reviewFilter, reviewSorting))
    }

    private func fetchCurrentSteps() {
        DDLogInfo("Fetching current steps")
        fetchCurrentStepsUseCase.execute { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let success):
                    DDLogInfo("Fetched current steps successfully: \(success.stepCount)")
                    self.currentSteps = success
                case .failure(let failure):
                    DDLogWarn("Failed to fetch current steps: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchCurrentHeartRate() {
        DDLogInfo("Fetching current heart rate")
        fetchCurrentHeartRateUseCase.execute { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let success):
                    DDLogInfo("Fetched current heart rate successfully: \(success.heartRate)")
                    self.currentHeartRate = success
                case .failure(let failure):
                    DDLogWarn("Failed to fetch current heart rate: \(failure.localizedDescription)")
                }
            }
        }
    }

    private func fetchReviews() {
        DDLogInfo("Fetching reviews")
        reviews = fetchReviewsUseCase.execute() ?? []
        applyFilterAndSorting(reviewFilter, reviewSorting)
    }

    private func fetchReviewReminders() {
        DDLogInfo("Fetching review reminders")
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
    }
}

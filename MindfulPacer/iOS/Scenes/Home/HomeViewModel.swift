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

// MARK: - HomeViewModel

@MainActor
@Observable
class HomeViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let checkMissedReviewsUseCase: CheckMissedReviewsUseCase
    private let createReviewUseCase: CreateReviewUseCase
    private let fetchActionedMissedReviewsUseCase: FetchActionedMissedReviewsUseCase
    private let fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    private let filterReviewsUseCase: FilterReviewsUseCase
    private let markMissedReviewAsActionedUseCase: MarkMissedReviewAsActionedUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: HomeViewSheet?
    var activeToast: HomeViewToast?
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
    
    var missedReviews: [MissedReview] = []
    
    var currentSteps: (stepCount: Double, timestamp: Date)?
    var currentHeartRate: (heartRate: Double, timestamp: Date)?
    
    var filterDateRangeSummary: String {
        reviewFilter.fromDate.formatted(.dateTime.day().month()) + " - " + reviewFilter.toDate.formatted(.dateTime.day().month())
    }
    
    var filterButtonTitle: String {
        let (filter, _) = filterAndSortingPublisher.value
        return filter.activeFilterCount == 0 ? "Filters" : "Filters (\(filter.activeFilterCount))"
    }
    
    var missedReviewsWidgetTitle: String {
        "\(missedReviews.count) Missed \(missedReviews.count > 1 ? "Reviews" : "Review")"
    }
    
    // MARK: - Private Properties
    
    var filterAndSortingPublisher = CurrentValueSubject<(ReviewFilter, ReviewSorting), Never>((ReviewFilter(), .dateDescending))
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        checkMissedReviewsUseCase: CheckMissedReviewsUseCase,
        createReviewUseCase: CreateReviewUseCase,
        fetchActionedMissedReviewsUseCase: FetchActionedMissedReviewsUseCase,
        fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase,
        filterReviewsUseCase: FilterReviewsUseCase,
        markMissedReviewAsActionedUseCase: MarkMissedReviewAsActionedUseCase
    ) {
        self.modelContext = modelContext
        self.checkMissedReviewsUseCase = checkMissedReviewsUseCase
        self.createReviewUseCase = createReviewUseCase
        self.fetchActionedMissedReviewsUseCase = fetchActionedMissedReviewsUseCase
        self.fetchCurrentHeartRateUseCase = fetchCurrentHeartRateUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchDefaultActivitiesUseCase = fetchDefaultActivitiesUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
        self.filterReviewsUseCase = filterReviewsUseCase
        self.markMissedReviewAsActionedUseCase = markMissedReviewAsActionedUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        setupBindings()
    }
    
    func onViewAppear() {
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchReviews()
        fetchReviewReminders()
        checkMissedReviews()
    }
    
    func onSheetDismissed() {
        fetchReviews()
        fetchReviewReminders()
    }
    
    // MARK: - User Actions
    
    func toggleFilterActivity(_ activity: Activity) {
        updateFilter {
            if reviewFilter.selectedActivities.contains(activity) {
                reviewFilter.selectedActivities.removeAll { $0 == activity }
            } else {
                reviewFilter.selectedActivities.append(activity)
            }
        }
    }
    
    func toggleFilterSubactivity(_ subactivity: Subactivity) {
        updateFilter {
            if reviewFilter.selectedSubactivities.contains(subactivity) {
                reviewFilter.selectedSubactivities.removeAll { $0 == subactivity }
            } else {
                reviewFilter.selectedSubactivities.append(subactivity)
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
    
    func acceptMissedReview(_ missedReview: MissedReview) {
        guard let defaultActivities = fetchDefaultActivitiesUseCase.execute() else { return }
        guard let reviewRemindersActivity = (defaultActivities.first { $0.name == "Review Reminders"}) else { return }
        guard let reviewRemindersSubactivities = reviewRemindersActivity.subactivities,
              let stepsActivity = (reviewRemindersSubactivities.first { $0.name == "Steps"}),
              let heartRateActivity = (reviewRemindersSubactivities.first { $0.name == "Heart Rate"}) else {
            return
        }
        
        _ = createReviewUseCase.execute(
            date: missedReview.date,
            activity: reviewRemindersActivity,
            subactivity: missedReview.measurementType == .steps ? stepsActivity : heartRateActivity,
            mood: nil,
            didTriggerCrash: false,
            wellBeing: nil,
            fatigue: nil,
            shortnessOfBreath: nil,
            sleepDisorder: nil,
            cognitiveImpairment: nil,
            physicalPain: nil,
            depressionOrAnxiety: nil,
            additionalInformation: "",
            measurementType: missedReview.measurementType,
            reviewReminderType: missedReview.reviewReminderType,
            threshold: missedReview.threshold,
            interval: missedReview.interval
        )
        
        markMissedReviewAsActionedUseCase.execute(missedReview: missedReview)
        
        withAnimation {
            missedReviews.removeAll { $0.id == missedReview.id }
        }
        
        // TODO: Show toast on success
    }
    
    func rejectMissedReview(_ missedReview: MissedReview) {
        markMissedReviewAsActionedUseCase.execute(missedReview: missedReview)
        
        withAnimation {
            missedReviews.removeAll { $0.id == missedReview.id }
        }
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: HomeViewSheet) {
        activeSheet = sheet
    }
    
    func presentToast(_ toast: HomeViewToast) {
        activeToast = toast
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
                    print("Failed to fetch current steps: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchCurrentHeartRate() {
        fetchCurrentHeartRateUseCase.execute { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let success):
                    self.currentHeartRate = success
                case .failure(let failure):
                    print("Failed to fetch current heart rate: \(failure.localizedDescription)")
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
    
    private func checkMissedReviews() {
        let reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
        let actionedMissedReviewIDs = fetchActionedMissedReviewsUseCase.execute()
        
        checkMissedReviewsUseCase.execute(
            reviewReminders: reviewReminders,
            actionedMissedReviewIDs: actionedMissedReviewIDs
        ) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let missedReviews):
                    /// 10 most recent missed reviews
                    self.missedReviews = Array(missedReviews.sorted { $0.date > $1.date }.prefix(10))
                case .failure(let failure):
                    print("DEBUG:", failure)
                }
            }
        }
    }
}

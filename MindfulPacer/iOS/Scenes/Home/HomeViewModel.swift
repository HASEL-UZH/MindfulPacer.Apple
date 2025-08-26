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
    private let checkMissedReflectionsUseCase: CheckMissedReflectionsUseCase
    private let createReflectionUseCase: CreateReflectionUseCase
    private let deleteReflectionUseCase: DeleteReflectionUseCase
    private let fetchActionedMissedReflectionsUseCase: FetchActionedMissedReflectionsUseCase
    private let fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase
    private let fetchHeartRateDataLast24HoursUseCase: FetchHeartRateDataLast24HoursUseCase
    private let fetchReflectionsUseCase: FetchReflectionsUseCase
    private let fetchRemindersUseCase: FetchRemindersUseCase
    private let fetchStepDataLast24HoursUseCase: FetchStepsDataLast24HoursUseCase
    private let filterReflectionsUseCase: FilterReflectionsUseCase
    private let markMissedReflectionAsActionedUseCase: MarkMissedReflectionAsActionedUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: HomeViewSheet?
    var activeToast: HomeViewToast?
    var reviewFilter: ReflectionFilter = ReflectionFilter()
    var reviewSorting: ReflectionSorting = .dateDescending
    var reflections: [Reflection] = []
    var missedReflections: [Reflection] = []
    var filteredReflections: [Reflection] = []
    
    var recentReflections: [Reflection] {
        Array(reflections.prefix(3))
    }
    
    var reminders: [Reminder] = []
    var recentReminders: [Reminder] {
        Array(reminders.prefix(3))
    }
    
    var stepData: [(startDate: Date, endDate: Date, stepCount: Double)] = []
    var heartRateData: [(startDate: Date, endDate: Date, stepCount: Double)] = []
    
    var currentSteps: (stepCount: Double, timestamp: Date)?
    var currentHeartRate: (heartRate: Double, timestamp: Date)?
    
    var filterDateRangeSummary: String {
        reviewFilter.fromDate.formatted(.dateTime.day().month()) + " - " + reviewFilter.toDate.formatted(.dateTime.day().month())
    }
    
    var filterButtonTitle: String {
        let (filter, _) = filterAndSortingPublisher.value
        return filter.activeFilterCount == 0 ? "Filters" : "Filters (\(filter.activeFilterCount))"
    }
    
    var missedReflectionsWidgetTitle: String {
        missedReflections.count > 1 ? "\(missedReflections.count) Missed Reflections" : "1 Missed Reflection"
    }
    
    // MARK: - Private Properties
    
    var filterAndSortingPublisher = CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>((ReflectionFilter(), .dateDescending))
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        checkMissedReflectionsUseCase: CheckMissedReflectionsUseCase,
        createReflectionUseCase: CreateReflectionUseCase,
        deleteReflectionUseCase: DeleteReflectionUseCase,
        fetchActionedMissedReflectionsUseCase: FetchActionedMissedReflectionsUseCase,
        fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase,
        fetchHeartRateDataLast24HoursUseCase: FetchHeartRateDataLast24HoursUseCase,
        fetchReflectionsUseCase: FetchReflectionsUseCase,
        fetchRemindersUseCase: FetchRemindersUseCase,
        fetchStepDataLast24HoursUseCase: FetchStepsDataLast24HoursUseCase,
        filterReflectionsUseCase: FilterReflectionsUseCase,
        markMissedReflectionAsActionedUseCase: MarkMissedReflectionAsActionedUseCase
    ) {
        self.modelContext = modelContext
        self.checkMissedReflectionsUseCase = checkMissedReflectionsUseCase
        self.createReflectionUseCase = createReflectionUseCase
        self.deleteReflectionUseCase = deleteReflectionUseCase
        self.fetchActionedMissedReflectionsUseCase = fetchActionedMissedReflectionsUseCase
        self.fetchCurrentHeartRateUseCase = fetchCurrentHeartRateUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchDefaultActivitiesUseCase = fetchDefaultActivitiesUseCase
        self.fetchHeartRateDataLast24HoursUseCase = fetchHeartRateDataLast24HoursUseCase
        self.fetchReflectionsUseCase = fetchReflectionsUseCase
        self.fetchRemindersUseCase = fetchRemindersUseCase
        self.fetchStepDataLast24HoursUseCase = fetchStepDataLast24HoursUseCase
        self.filterReflectionsUseCase = filterReflectionsUseCase
        self.markMissedReflectionAsActionedUseCase = markMissedReflectionAsActionedUseCase
        
        subscribeToWatchEvents()
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        setupBindings()
    }
    
    func onViewAppear() {
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchReflections()
        fetchReminders()
        fetchHealthData()
    }
    
    func onSheetDismissed() {
        fetchReflections()
        fetchReminders()
    }
    
    // MARK: - User Actions
    
    func rejectMissedReflection(reflection: Reflection) {
        deleteReflectionUseCase.execute(reflection: reflection)
        missedReflections.removeAll { $0.id == reflection.id }
    }
    
    func acceptMissedReflection(reflection: Reflection) {
        missedReflections.removeAll { $0.id == reflection.id }
        presentSheet(.editReflectionView(reflection))
    }
    
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
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: HomeViewSheet) {
        activeSheet = sheet
    }
    
    func presentToast(_ toast: HomeViewToast) {
        activeToast = toast
    }
    
    // MARK: - Private Methods
    
    private func subscribeToWatchEvents() {
        WatchEventCoordinator.shared.openReflectionSubject
            .sink { [weak self] event in
                guard let self = self else { return }
                
                guard let reflections = self.fetchReflectionsUseCase.execute() else {
                    print("ERROR: iPhone could not find reflection with ID \(event.reflectionID)")
                    return
                }
                
                guard let reflection = reflections.filter({ $0.id == event.reflectionID }).first else { return }
                
                if let activityID = event.activityID {
                    if let allActivities = self.fetchDefaultActivitiesUseCase.execute(),
                       let matchingActivity = allActivities.first(where: { $0.id == activityID }) {
                        
                        reflection.activity = matchingActivity
                        
                        if let subactivityID = event.subactivityID,
                           let matchingSubactivity = matchingActivity.subactivities?.first(where: { $0.id == subactivityID }) {
                            reflection.subactivity = matchingSubactivity
                        }
                    }
                }
                
                self.presentSheet(.editReflectionView(reflection))
            }
            .store(in: &cancellables)
    }
    
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
    
    private func applyFilterAndSorting(_ filter: ReflectionFilter, _ sorting: ReflectionSorting) {
        filteredReflections = filterReflectionsUseCase.execute(
            reflections: reflections,
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
                    print("DEBUGY: Failed to fetch current heart rate: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchHealthData() {
        fetchStepDataLast24HoursUseCase.execute { [weak self] stepData in
            guard let self = self else { return }
            Task { @MainActor in
                self.stepData = stepData
            }
        }
        
        fetchHeartRateDataLast24HoursUseCase.execute { [weak self] heartRateData in
            guard let self = self else { return }
            Task { @MainActor in
                self.heartRateData = heartRateData
            }
        }
    }
    
    private func fetchReflections() {
        let allReflections = fetchReflectionsUseCase.execute() ?? []
        reflections = allReflections.filter { !$0.isMissedReflection }
        missedReflections = allReflections.filter { $0.isMissedReflection }
        applyFilterAndSorting(reviewFilter, reviewSorting)
    }
    
    private func fetchReminders() {
        reminders = fetchRemindersUseCase.execute() ?? []
    }
}

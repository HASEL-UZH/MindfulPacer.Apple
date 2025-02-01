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
    private let fetchActionedMissedReflectionsUseCase: FetchActionedMissedReflectionsUseCase
    private let fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase
    private let fetchReflectionsUseCase: FetchReflectionsUseCase
    private let fetchRemindersUseCase: FetchRemindersUseCase
    private let filterReflectionsUseCase: FilterReflectionsUseCase
    private let markMissedReflectionAsActionedUseCase: MarkMissedReflectionAsActionedUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: HomeViewSheet?
    var activeToast: HomeViewToast?
    var reviewFilter: ReflectionFilter = ReflectionFilter()
    var reviewSorting: ReflectionSorting = .dateDescending
    var reflections: [Reflection] = []
    var filteredReflections: [Reflection] = []
    
    var recentReflections: [Reflection] {
        Array(reflections.prefix(3))
    }
    
    var reminders: [Reminder] = []
    var recentReminders: [Reminder] {
        Array(reminders.prefix(3))
    }
    
    var missedReflections: [MissedReflection] = []
    
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
        "\(missedReflections.count) Missed \(missedReflections.count > 1 ? "Reflections" : "Reflection")"
    }
    
    // MARK: - Private Properties
    
    var filterAndSortingPublisher = CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>((ReflectionFilter(), .dateDescending))
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        checkMissedReflectionsUseCase: CheckMissedReflectionsUseCase,
        createReflectionUseCase: CreateReflectionUseCase,
        fetchActionedMissedReflectionsUseCase: FetchActionedMissedReflectionsUseCase,
        fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase,
        fetchReflectionsUseCase: FetchReflectionsUseCase,
        fetchRemindersUseCase: FetchRemindersUseCase,
        filterReflectionsUseCase: FilterReflectionsUseCase,
        markMissedReflectionAsActionedUseCase: MarkMissedReflectionAsActionedUseCase
    ) {
        self.modelContext = modelContext
        self.checkMissedReflectionsUseCase = checkMissedReflectionsUseCase
        self.createReflectionUseCase = createReflectionUseCase
        self.fetchActionedMissedReflectionsUseCase = fetchActionedMissedReflectionsUseCase
        self.fetchCurrentHeartRateUseCase = fetchCurrentHeartRateUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchDefaultActivitiesUseCase = fetchDefaultActivitiesUseCase
        self.fetchReflectionsUseCase = fetchReflectionsUseCase
        self.fetchRemindersUseCase = fetchRemindersUseCase
        self.filterReflectionsUseCase = filterReflectionsUseCase
        self.markMissedReflectionAsActionedUseCase = markMissedReflectionAsActionedUseCase
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
        checkMissedReflections()
    }
    
    func onSheetDismissed() {
        fetchReflections()
        fetchReminders()
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
    
    func acceptMissedReflection(_ missedReflection: MissedReflection) {
        guard let defaultActivities = fetchDefaultActivitiesUseCase.execute() else { return }
        guard let remindersActivity = (defaultActivities.first { $0.name == "Reflection Reminders"}) else { return }
        guard let remindersSubactivities = remindersActivity.subactivities,
              let stepsActivity = (remindersSubactivities.first { $0.name == "Steps"}),
              let heartRateActivity = (remindersSubactivities.first { $0.name == "Heart Rate"}) else {
            return
        }
        
        _ = createReflectionUseCase.execute(
            date: missedReflection.date,
            activity: remindersActivity,
            subactivity: missedReflection.measurementType == .steps ? stepsActivity : heartRateActivity,
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
            measurementType: missedReflection.measurementType,
            reminderType: missedReflection.reminderType,
            threshold: missedReflection.threshold,
            interval: missedReflection.interval
        )
        
        markMissedReflectionAsActionedUseCase.execute(missedReflection: missedReflection)
        
        withAnimation {
            missedReflections.removeAll { $0.id == missedReflection.id }
        }
        
        // TODO: Show toast on success
    }
    
    func rejectMissedReflection(_ missedReflection: MissedReflection) {
        markMissedReflectionAsActionedUseCase.execute(missedReflection: missedReflection)
        
        withAnimation {
            missedReflections.removeAll { $0.id == missedReflection.id }
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
                    print("Failed to fetch current heart rate: \(failure.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchReflections() {
        reflections = fetchReflectionsUseCase.execute() ?? []
        applyFilterAndSorting(reviewFilter, reviewSorting)
    }
    
    private func fetchReminders() {
        reminders = fetchRemindersUseCase.execute() ?? []
    }
    
    private func checkMissedReflections() {
        let reminders = fetchRemindersUseCase.execute() ?? []
        let actionedMissedReflectionIDs = fetchActionedMissedReflectionsUseCase.execute()
        
        checkMissedReflectionsUseCase.execute(
            reminders: reminders,
            actionedMissedReflectionIDs: actionedMissedReflectionIDs
        ) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let missedReflections):
                    /// 10 most recent missed reflections
                    self.missedReflections = Array(missedReflections.sorted { $0.date > $1.date }.prefix(10))
                case .failure(let failure):
                    print("DEBUG:", failure)
                }
            }
        }
    }
}

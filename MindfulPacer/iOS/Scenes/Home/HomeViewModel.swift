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
    var filteredReflections: [Reflection] = []
    
    var recentReflections: [Reflection] {
        Array(reflections.prefix(3))
    }
    
    var reminders: [Reminder] = []
    var recentReminders: [Reminder] {
        Array(reminders.prefix(3))
    }
    
    var missedReflections: [MissedReflection] = []
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
        checkMissedReflections()
        fetchHealthData()
    }
    
    func onSheetDismissed() {
        fetchReflections()
        fetchReminders()
        checkMissedReflections()
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
        missedReflection.accept()
    
        withAnimation {
            missedReflections.removeAll { $0.id == missedReflection.id }
        }
        
        _ = createReflectionUseCase.execute(
            date: missedReflection.date,
            activity: nil,
            subactivity: nil,
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
       
        presentToast(.successfullyCreatedReflection)
    }
    
    func rejectMissedReflection(_ missedReflection: MissedReflection) {
        missedReflection.reject()
        
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
    
    private func subscribeToWatchEvents() {
        WatchEventCoordinator.shared.createReflectionSubject
            .receive(on: DispatchQueue.main) // Ensure we're on the main thread
            .sink { [weak self] heartRateData in
                guard let self = self else { return }
                
                // This is where you decide what to do with the incoming data.
                // We will create a *new* Reflection object to pass to the sheet.
                
                // Let's use your existing CreateReflectionUseCase to make a new, empty reflection.
                // This assumes your use case can handle nil for most properties.
                let result = self.createReflectionUseCase.execute(
                    date: Date(), // Use the current date for the new reflection
                    activity: nil,
                    subactivity: nil,
                    mood: nil,
                    didTriggerCrash: false,
                    wellBeing: nil,
                    fatigue: nil,
                    shortnessOfBreath: nil,
                    sleepDisorder: nil,
                    cognitiveImpairment: nil,
                    physicalPain: nil,
                    depressionOrAnxiety: nil,
                    additionalInformation: "Reflection triggered by a heart rate event.",
                    measurementType: .heartRate,
                    reminderType: .strong, // You might want to pass this from the watch
                    threshold: 0, // You might want to pass this from the watch
                    interval: .immediately // You might want to pass this from the watch
                )
                
                switch result {
                case .success(let newReflection):
                    // TODO: You might want a way to attach the `heartRateData` to the `newReflection`
                    // For example: `newReflection.heartRateSamples = heartRateData`
                    // This depends on your `Reflection` model structure.
                    
                    // Now, present the sheet with the newly created Reflection object.
                    self.presentSheet(.editReflectionView(newReflection))
                    
                case .failure(let error):
                    print("Failed to create reflection from watch event: \(error.localizedDescription)")
                }
            }
            .store(in: &cancellables) // Store the subscription to keep it alive
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
        reflections = fetchReflectionsUseCase.execute() ?? []
        applyFilterAndSorting(reviewFilter, reviewSorting)
    }
    
    private func fetchReminders() {
        reminders = fetchRemindersUseCase.execute() ?? []
    }
    
    private func checkMissedReflections() {
        let reminders = fetchRemindersUseCase.execute() ?? []
        
        checkMissedReflectionsUseCase.execute(
            reminders: reminders,
            isDeveloperMode: false
        ) { [weak self] result in
            guard let self = self else { return }
            
            Task { @MainActor in
                switch result {
                case .success(let missedReflections):
                    self.missedReflections = missedReflections
                case .failure(let failure):
                    print("DEBUG:", failure)
                }
            }
        }
    }
}

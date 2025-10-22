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
    private let checkHealthPermissionsUseCase: CheckHealthPermissionsUseCase
    private let createReflectionUseCase: CreateReflectionUseCase
    private let deleteReflectionUseCase: DeleteReflectionUseCase
    private let fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase
    private let fetchHeartRateDataLast24HoursUseCase: FetchHeartRateDataLast24HoursUseCase
    private let fetchMissedReflectionsUseCase: FetchMissedReflectionsUseCase
    private let fetchReflectionsUseCase: FetchReflectionsUseCase
    private let fetchRemindersUseCase: FetchRemindersUseCase
    private let fetchStepDataLast24HoursUseCase: FetchStepsDataLast24HoursUseCase
    private let filterReflectionsUseCase: FilterReflectionsUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: HomeSheet?
    var activeAlert: HomeAlert?
    var activeToast: HomeToast?
    
    var reviewFilter: ReflectionFilter = ReflectionFilter()
    var reviewSorting: ReflectionSorting = .dateDescending
    var reflections: [Reflection] = []
    var missedReflections: [Reflection] = []
    var filteredReflections: [Reflection] = []
    var healthPermissionState: HealthPermissionsState = .ok
    
    var deviceMode: DeviceMode = .iPhoneOnly
    
    var isFetchingMissedReflections = false
    
    var recentReflections: [Reflection] {
        Array(reflections.prefix(3))
    }
    
    var reminders: [Reminder] = []
    var recentReminders: [Reminder] {
        Array(reminders.prefix(3))
    }
    
    var missedPageSize: Int = 10
    var missedVisibleCount: Int = 10
    
    var displayedMissedReflections: [Reflection] {
        Array(missedReflections.prefix(min(missedVisibleCount, missedReflections.count)))
    }
    
    var canLoadMoreMissed: Bool {
        missedVisibleCount < missedReflections.count
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
    
    var watchConnectionStatus: WatchConnectionStatus = .initializing
    var watchConnectionSpeed: WatchConnectionSpeed = .noResponse
    
    var isWatchPaired: Bool {
        return watchConnectionStatus != .noWatchPaired
    }
    
    var isWatchAppInstalled: Bool {
        switch watchConnectionStatus {
        case .noWatchPaired, .appNotInstalled:
            return false
        default:
            return true
        }
    }
    
    // MARK: - Private Properties
    
    var filterAndSortingPublisher = CurrentValueSubject<(ReflectionFilter, ReflectionSorting), Never>((ReflectionFilter(), .dateDescending))
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        checkHealthPermissionsUseCase: CheckHealthPermissionsUseCase,
        createReflectionUseCase: CreateReflectionUseCase,
        deleteReflectionUseCase: DeleteReflectionUseCase,
        fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase,
        fetchHeartRateDataLast24HoursUseCase: FetchHeartRateDataLast24HoursUseCase,
        fetchMissedReflectionsUseCase: FetchMissedReflectionsUseCase,
        fetchReflectionsUseCase: FetchReflectionsUseCase,
        fetchRemindersUseCase: FetchRemindersUseCase,
        fetchStepDataLast24HoursUseCase: FetchStepsDataLast24HoursUseCase,
        filterReflectionsUseCase: FilterReflectionsUseCase
    ) {
        self.modelContext = modelContext
        self.checkHealthPermissionsUseCase = checkHealthPermissionsUseCase
        self.createReflectionUseCase = createReflectionUseCase
        self.deleteReflectionUseCase = deleteReflectionUseCase
        self.fetchCurrentHeartRateUseCase = fetchCurrentHeartRateUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchDefaultActivitiesUseCase = fetchDefaultActivitiesUseCase
        self.fetchHeartRateDataLast24HoursUseCase = fetchHeartRateDataLast24HoursUseCase
        self.fetchMissedReflectionsUseCase = fetchMissedReflectionsUseCase
        self.fetchReflectionsUseCase = fetchReflectionsUseCase
        self.fetchRemindersUseCase = fetchRemindersUseCase
        self.fetchStepDataLast24HoursUseCase = fetchStepDataLast24HoursUseCase
        self.filterReflectionsUseCase = filterReflectionsUseCase
        
        subscribeToWatchEvents()
        subscribeToWatchStatus()
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        setupBindings()
        resetMissedPagination()
        fetchReminders()
        fetchReflections()
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchHealthData()
        fetchMissedReflections()
        checkHealthPermissions()
    }
    
    func onViewAppear() {
        fetchReminders()
        fetchReflections()
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchHealthData()
        checkHealthPermissions()
    }
    
    func onRefresh() {
        checkHealthPermissions()
        fetchReminders()
        fetchReflections()
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchHealthData()
        fetchMissedReflections()
    }
    
    func onSheetDismissed() {
        fetchReflections()
        fetchReminders()
    }
    
    func configure(_ deviceMode: DeviceMode) {
        self.deviceMode = deviceMode
    }
    
    // MARK: - User Actions
    
    func rejectMissedReflection(reflection: Reflection) {
        switch deviceMode {
        case .iPhoneOnly:
            let _ = createReflectionUseCase.execute(
                date: reflection.date,
                activity: reflection.activity,
                subactivity: reflection.subactivity,
                mood: nil,
                didTriggerCrash: false,
                wellBeing: nil,
                fatigue: nil,
                shortnessOfBreath: nil,
                sleepDisorder: nil,
                cognitiveImpairment: nil,
                physicalPain: nil,
                depressionOrAnxiety: nil,
                additionalInformation: ""
                , measurementType: nil,
                reminderType: nil,
                threshold: nil,
                interval: nil,
                triggerSamples: [],
                isRejected: true
            )
        case .iPhoneAndWatch:
            deleteReflectionUseCase.execute(reflection: reflection)
        }
        
        missedReflections.removeAll { $0.id == reflection.id }
        clampMissedPaginationAfterMutation()
    }
    
    func acceptMissedReflection(reflection: Reflection) {
        missedReflections.removeAll { $0.id == reflection.id }
        clampMissedPaginationAfterMutation()
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
    
    func presentSheet(_ sheet: HomeSheet) {
        activeSheet = sheet
    }
    
    func presentAlert(_ alert: HomeAlert) {
        activeAlert = alert
    }
    
    func presentToast(_ toast: HomeToast) {
        activeToast = toast
    }
    
    func resetMissedPagination() {
        missedVisibleCount = min(missedPageSize, missedReflections.count)
    }
    
    @MainActor
    func loadMoreMissed() {
        guard canLoadMoreMissed else { return }
        missedVisibleCount = min(missedVisibleCount + missedPageSize, missedReflections.count)
    }
    
    func clampMissedPaginationAfterMutation() {
        missedVisibleCount = min(missedVisibleCount, missedReflections.count)
        if missedVisibleCount == 0 && !missedReflections.isEmpty {
            resetMissedPagination()
        }
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
        reminders = fetchRemindersUseCase.execute() ?? []
        let allReflections = fetchReflectionsUseCase.execute() ?? []
        reflections = allReflections.filter { !$0.isMissedReflection && !$0.isRejected }
        applyFilterAndSorting(reviewFilter, reviewSorting)
    }
    
    private func fetchMissedReflections() {
        isFetchingMissedReflections = true
        let allReflections = fetchReflectionsUseCase.execute() ?? []
        
        switch deviceMode {
        case .iPhoneOnly:
            fetchMissedReflectionsUseCase.execute(
                reminders: reminders,
                existingReflections: allReflections
            ) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let fetchedMissedReflections):
                    self.missedReflections = Array(fetchedMissedReflections.prefix(100))
                    self.missedReflections = self.missedReflections.filter { $0.triggerSamples.count > 1 }
                    self.resetMissedPagination()
                case .failure(let failure):
                    print("DEBUGY:", failure.localizedDescription)
                }
                self.isFetchingMissedReflections = false
                self.applyFilterAndSorting(self.reviewFilter, self.reviewSorting)
            }
        case .iPhoneAndWatch:
            missedReflections = allReflections.filter { $0.isMissedReflection }
            resetMissedPagination()
            isFetchingMissedReflections = false
            applyFilterAndSorting(reviewFilter, reviewSorting)
        }
    }
    
    private func fetchReminders() {
        reminders = fetchRemindersUseCase.execute() ?? []
    }
    
    private func checkHealthPermissions() {
        checkHealthPermissionsUseCase.execute { [weak self] state in
            Task { @MainActor in
                self?.healthPermissionState = state
                print("DEBUGY: Health", state)
            }
        }
    }
    
    private func subscribeToWatchStatus() {
        ConnectivityService.shared.$connectionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.watchConnectionStatus = status }
            .store(in: &cancellables)
        
        ConnectivityService.shared.$connectionSpeed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speed in self?.watchConnectionSpeed = speed }
            .store(in: &cancellables)
    }
}

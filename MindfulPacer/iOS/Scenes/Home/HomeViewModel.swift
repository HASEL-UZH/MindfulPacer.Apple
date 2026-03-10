//
//  HomeViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Combine
import CoreData
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
    private let fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchHeartRateDataLast24HoursUseCase: FetchHeartRateDataLast24HoursUseCase
    private let fetchMissedReflectionsUseCase: FetchMissedReflectionsUseCase
    private let fetchStepDataLast24HoursUseCase: FetchStepsDataLast24HoursUseCase
    
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
    
    private var activities: [Activity] = []
    
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
        fetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchHeartRateDataLast24HoursUseCase: FetchHeartRateDataLast24HoursUseCase,
        fetchMissedReflectionsUseCase: FetchMissedReflectionsUseCase,
        fetchStepDataLast24HoursUseCase: FetchStepsDataLast24HoursUseCase
    ) {
        self.modelContext = modelContext
        self.checkHealthPermissionsUseCase = checkHealthPermissionsUseCase
        self.fetchCurrentHeartRateUseCase = fetchCurrentHeartRateUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchHeartRateDataLast24HoursUseCase = fetchHeartRateDataLast24HoursUseCase
        self.fetchMissedReflectionsUseCase = fetchMissedReflectionsUseCase
        self.fetchStepDataLast24HoursUseCase = fetchStepDataLast24HoursUseCase
        
        subscribeToWatchEvents()
        subscribeToWatchStatus()
        subscribeToRemoteStoreChanges()
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear(reminders: [Reminder]) {
        setupBindings()
        resetMissedPagination()
        updateReminders(reminders)
        fetchReflections()
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchHealthData()
        fetchMissedReflections(reminders: reminders)
        checkHealthPermissions()
    }

    func onViewAppear() {
        fetchReflections()
        fetchMissedReflections(reminders: reminders)
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchHealthData()
        checkHealthPermissions()
    }
    
    func onRefresh(reminders: [Reminder]) {
        checkHealthPermissions()
        updateReminders(reminders)
        fetchReflections()
        fetchCurrentSteps()
        fetchCurrentHeartRate()
        fetchHealthData()
        fetchMissedReflections(reminders: reminders)
    }
    
    func onSheetDismissed() {
        fetchReflections()
    }
    
    func configure(_ deviceMode: DeviceMode) {
        self.deviceMode = deviceMode
    }
    
    func updateReminders(_ newReminders: [Reminder]) {
        reminders = newReminders
    }
    
    func updateActivities(_ newActivities: [Activity]) {
        activities = newActivities
    }
    
    // MARK: - User Actions
    
    func rejectMissedReflection(reflection: Reflection) {
        switch deviceMode {
        case .iPhoneOnly:
            // Create a rejected reflection
            let rejectedReflection = Reflection(
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
                additionalInformation: "",
                measurementType: reflection.measurementType,
                reminderType: reflection.reminderType,
                threshold: reflection.threshold,
                interval: reflection.interval,
                triggerSamples: reflection.triggerSamples,
                isRejected: true
            )
            
            modelContext.insert(rejectedReflection)
            
            do {
                try modelContext.save()
                BackgroundReflectionsStore.shared.upsert(.init(from: rejectedReflection))
            } catch {
                print("DEBUG: Could not save rejected reflection: \(error.localizedDescription)")
            }
            
        case .iPhoneAndWatch:
            // Delete the reflection
            modelContext.delete(reflection)
            
            do {
                try modelContext.save()
                BackgroundReflectionsStore.shared.remove(id: reflection.id)
            } catch {
                print("DEBUG: Could not delete reflection: \(error.localizedDescription)")
            }
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
                
                // Capture the ID value before using it in the predicate
                let reflectionID = event.reflectionID
                
                // Fetch reflection directly from SwiftData
                do {
                    let descriptor = FetchDescriptor<Reflection>(
                        predicate: #Predicate { $0.id == reflectionID }
                    )
                    guard let reflection = try modelContext.fetch(descriptor).first else {
                        print("ERROR: iPhone could not find reflection with ID \(reflectionID)")
                        return
                    }
                    
                    if let activityID = event.activityID {
                        if let matchingActivity = self.activities.first(where: { $0.id == activityID }) {
                            
                            reflection.activity = matchingActivity
                            
                            if let subactivityID = event.subactivityID,
                               let matchingSubactivity = matchingActivity.subactivities?.first(where: { $0.id == subactivityID }) {
                                reflection.subactivity = matchingSubactivity
                            } else {
                                reflection.subactivity = nil
                            }
                            
                            do {
                                try self.modelContext.save()
                                BackgroundReflectionsStore.shared.upsert(.init(from: reflection))
                            } catch {
                                print("DEBUGY: Failed to save reflection after watch event: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    self.fetchReflections()
                    self.fetchMissedReflections(reminders: self.reminders)
                    self.presentSheet(.editReflectionView(reflection))
                } catch {
                    print("ERROR: Failed to fetch reflection: \(error.localizedDescription)")
                }
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
        filteredReflections = reflections.filtered(by: filter, sorting: sorting)
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
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let allReflections = try modelContext.fetch(descriptor)
            
            syncBackgroundReflectionSnapshots(allReflections: allReflections)
            
            reflections = allReflections.filter { !$0.isMissedReflection && !$0.isRejected }
            applyFilterAndSorting(reviewFilter, reviewSorting)
        } catch {
            print("DEBUG: Could not fetch reflections: \(error.localizedDescription)")
            reflections = []
        }
    }
    
    private func fetchMissedReflections(reminders: [Reminder]) {
        isFetchingMissedReflections = true
        
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let allReflections = try modelContext.fetch(descriptor)
            
            switch deviceMode {
            case .iPhoneOnly:
                fetchMissedReflectionsUseCase.execute(
                    reminders: reminders,
                    existingReflections: allReflections
                ) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let fetchedMissedReflections):
                        self.missedReflections = MissedReflectionsDisplayPolicy.apply(fetchedMissedReflections)
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
        } catch {
            print("DEBUG: Could not fetch reflections: \(error.localizedDescription)")
            isFetchingMissedReflections = false
        }
    }
    
    private func checkHealthPermissions() {
        checkHealthPermissionsUseCase.execute(deviceMode: deviceMode) { [weak self] state in
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
    
    private func subscribeToRemoteStoreChanges() {
        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.fetchReflections()
                self.fetchMissedReflections(reminders: self.reminders)
            }
            .store(in: &cancellables)
    }

    private func syncBackgroundReflectionSnapshots(allReflections: [Reflection]) {
        let snapshots = allReflections.map(BackgroundReflectionSnapshot.init(from:))
        BackgroundReflectionsStore.shared.replace(with: snapshots)
    }
}

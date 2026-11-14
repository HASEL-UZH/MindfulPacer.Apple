//
//  HomeViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import Foundation
import Combine
import CoreData
import WatchKit
import SwiftUI
import SwiftData

enum AlertState: Equatable {
    case none
    case showing(rule: AlertRule, alertID: UUID)
}

extension AlertState {
    static func == (lhs: AlertState, rhs: AlertState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.showing(let lRule, let lId), .showing(let rRule, let rId)):
            return lRule.id == rRule.id && lId == rId
        default:
            return false
        }
    }
}

@MainActor
@Observable
class HomeViewModel {
    var statusMessage: StatusMessage = .notMonitoring
    var heartRate: Double = 0
    var widgetHighlights = ReminderHighlightState()

    var heartRateHighlight: Reminder.ReminderType? {
        widgetHighlights.severity(for: .heartRate, at: Date())
    }

    var stepsHighlight: Reminder.ReminderType? {
        widgetHighlights.severity(for: .steps, at: Date())
    }
    var isMonitoring: Bool = false
    var todaysSteps: Int = 0
    var activeRules: [AlertRule] = []
    var selectedTab: HomePage = .main
    var batteryLevel: Float = WKInterfaceDevice.current().batteryLevel
    
    
    var alertState: AlertState = .none

    var heartRateSamples: [(value: Double, date: Date)] = []
    var hourlyStepData: [(date: Date, steps: Double)] = []
    
    var strongAlertCount: Int = 0
    var mediumAlertCount: Int = 0
    var lightAlertCount: Int = 0
    var isManuallyPaused: Bool = false
    var missedReflectionsCount: Int = 0
    var showActivitiesUnavailableAlert: Bool = false
    
    private let modelContext: ModelContext
    private var usesLiveServices = true
    
    enum ChartMetric { case heartRate, steps }

    struct ChartEmptyState {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource
        let symbol: String
    }

    var hasHeartRateData: Bool { !heartRateSamples.isEmpty }
    var hasStepsData: Bool { !hourlyStepData.isEmpty }

    func emptyState(for metric: ChartMetric) -> ChartEmptyState {
        if statusMessage == .permissionDenied {
            return ChartEmptyState(
                title: "Health Permission Needed",
                subtitle: "Enable \(metric == .heartRate ? "Heart Rate" : "Steps") access in the Health settings on your iPhone.",
                symbol: "hand.raised.fill"
            )
        }

        if isManuallyPaused {
            return ChartEmptyState(title: "Monitoring Paused", subtitle: "Resume monitoring from Controls to collect new readings.", symbol: "pause.circle.fill")
        }

        switch metric {
        case .heartRate:
            return ChartEmptyState(
                title: "No Heart Rate Yet",
                subtitle: "Wear your Watch snugly. New readings will appear here while monitoring is active.",
                symbol: "waveform.path.ecg"
            )

        case .steps:
            return ChartEmptyState(
                title: "No Recent Steps",
                subtitle: "No step data recorded for the last hour.",
                symbol: "figure.walk"
            )
        }
    }
    
    var avgHeartRate: Int {
        guard !heartRateSamples.isEmpty else { return 0 }
        let sum = heartRateSamples.reduce(0) { $0 + $1.value }
        return Int(sum / Double(heartRateSamples.count))
    }
    
    var heartRateThresholdRules: [AlertRule] {
        let allowed: [Reminder.Interval] = [.fifteenMinutes, .oneMinute, .fiveMinutes, .twoMinutes]
        return activeRules.filter { rule in
            allowed.contains(rule.interval) &&
            (rule.measurementType == .heartRate)
        }
    }

    private var heartRateDisplayedThresholds: [Double] {
        heartRateThresholdRules.compactMap {
            if case .heartRate(let t) = $0.ruleType { return t }
            return nil
        }
    }

    var minHeartRate: Int {
        (heartRateSamples.min(by: { $0.value < $1.value })?.value ?? 0).toInt()
    }
    
    var maxHeartRate: Int {
        (heartRateSamples.max(by: { $0.value < $1.value })?.value ?? 0).toInt()
    }
    
    var downsampledHeartRateSamples: [(value: Double, date: Date)] {
        let maxDataPoints = 150
        guard heartRateSamples.count > maxDataPoints else { return heartRateSamples }
        var downsampledData: [(value: Double, date: Date)] = []
        let bucketSize = Double(heartRateSamples.count) / Double(maxDataPoints)
        for i in 0..<maxDataPoints {
            let bucketStart = Int(Double(i) * bucketSize)
            let bucketEnd = Int(Double(i + 1) * bucketSize)
            guard let bucketSlice = heartRateSamples[safe: bucketStart..<bucketEnd] else { continue }
            let bucket = Array(bucketSlice)
            guard !bucket.isEmpty else { continue }
            if let significantPoint = bucket.max(by: { $0.value < $1.value }) {
                downsampledData.append(significantPoint)
            }
        }
        return downsampledData
    }
    
    var heartRateChartYDomain: ClosedRange<Double> {
        HeartRateChartScale.domain(values: heartRateSamples.map(\.value),
                                   thresholds: heartRateDisplayedThresholds)
    }
    
    // This series is cumulative over the displayed hour, so a zero baseline is meaningful.
    // Rolling reminder thresholds use different windows and are not plotted on this series.
    var stepsChartYDomain: ClosedRange<Double> {
        0...max(10, (hourlyStepData.map(\.steps).max() ?? 0) * 1.1)
    }

    var heartRateChartDateRange: ClosedRange<Date> {
        let end = heartRateSamples.last?.date ?? Date()
        return end.addingTimeInterval(-3600)...end
    }

    var stepsChartDateRange: ClosedRange<Date> {
        let end = hourlyStepData.last?.date ?? Date()
        return end.addingTimeInterval(-3600)...end
    }

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let modelContext = ModelContainer.prod.mainContext
        self.modelContext = modelContext
        
        loadPersistentCounts()
        checkForDailyReset()
        setupSubscriptions()
    }
    
    private init(isForPreview: Bool) {
        let previewContext = ModelContainer.preview.mainContext
        self.modelContext = previewContext
        self.usesLiveServices = false
        self.todaysSteps = 2840
        self.batteryLevel = 0.82
        self.missedReflectionsCount = 3
        
        self.statusMessage = .monitoring
        self.isMonitoring = true
        self.heartRate = 78
        self.strongAlertCount = 1
        self.mediumAlertCount = 0
        self.lightAlertCount = 2
        
        let now = Date()
        var samples: [(value: Double, date: Date)] = []
        for i in 0..<60 {
            let timeInterval = Double(i) * -60
            let date = now.addingTimeInterval(timeInterval)
            let sineValue = sin(Double(i) * 0.2)
            let heartRateValue = 75.0 + (sineValue * 15.0) + 2 * sin(Double(i) * 1.7)
            samples.append((value: heartRateValue, date: date))
        }
        self.heartRateSamples = samples.reversed()
        
        var stepData: [(date: Date, steps: Double)] = []
        for i in 0..<12 {
            let timeInterval = Double(i) * -300
            let date = now.addingTimeInterval(timeInterval)
            let steps = Double(12 - i) * 45
            stepData.append((date: date, steps: steps))
        }
        self.hourlyStepData = stepData.reversed()
        self.activeRules = Reminder.ReminderType.allCases.enumerated().flatMap { index, severity in
            [AlertRule(id: UUID(), measurementType: .heartRate, reminderType: severity,
                       ruleType: .heartRate(threshold: Double(90 + index * 10)), duration: 60,
                       alertMessage: "Above \(90 + index * 10) BPM for 1 min", interval: .oneMinute),
             AlertRule(id: UUID(), measurementType: .steps, reminderType: severity,
                       ruleType: .steps(threshold: Double(500 + index * 250)), duration: 1800,
                       alertMessage: "Over \(500 + index * 250) steps in 30 min", interval: .thirtyMinutes)]
        }
    }
    
    static var mock: HomeViewModel {
        HomeViewModel(isForPreview: true)
    }
    
    private func setupSubscriptions() {
        Services.shared.monitorService.$widgetHighlights
            .sink { [weak self] highlights in self?.widgetHighlights = highlights }
            .store(in: &cancellables)
        Services.shared.monitorService.$statusMessage
            .sink { [weak self] newStatus in self?.statusMessage = newStatus }
            .store(in: &cancellables)
        Services.shared.monitorService.$heartRate
            .sink { [weak self] newHeartRate in self?.heartRate = newHeartRate }
            .store(in: &cancellables)
        Services.shared.monitorService.$isSessionActive
            .sink { [weak self] newIsMonitoring in self?.isMonitoring = newIsMonitoring }
            .store(in: &cancellables)
        Services.shared.monitorService.alertTriggeredSubject
               .receive(on: DispatchQueue.main)
               .sink { [weak self] rule in
                   self?.triggerInAppAlert(for: rule)
               }
               .store(in: &cancellables)
        
        Services.shared.monitorService.$recentHeartRateSamples
            .sink { [weak self] samples in
                guard let self else { return }
                guard self.selectedTab == .heartRateChart else { return }
                self.heartRateSamples = samples
            }
            .store(in: &cancellables)
        
        Services.shared.monitorService.$activeRules
            .sink { [weak self] newRules in self?.activeRules = newRules }
            .store(in: &cancellables)
        Services.shared.monitorService.$isManuallyPaused
                  .receive(on: DispatchQueue.main)
                  .sink { [weak self] isPaused in self?.isManuallyPaused = isPaused }
                  .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchMissedReflections()
            }
            .store(in: &cancellables)

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task {
                if await self?.selectedTab == .stepsChart {
                    await self?.fetchChartData()
                }
                await self?.fetchTodaysSteps()
                await self?.updateBattery()
                await self?.fetchMissedReflections()
            }
        }
    }
    
    func refreshHighlights() {
        guard usesLiveServices else { return }
        Services.shared.monitorService.refreshWidgetHighlights()
    }

    func onAppear() {
        guard usesLiveServices else { return }
        refreshHighlights()
        heartRateSamples = Services.shared.monitorService.recentHeartRateSamples
        Services.shared.systemDelegate.configure()
        
        let reminders = fetchReminders()
        Services.shared.monitorService.configure(reminders: reminders)
        
        Task {
            let isAuthorized = try await Services.shared.monitorService.requestAuthorization()
            guard isAuthorized else {
                self.statusMessage = .permissionDenied
                return
            }
            Services.shared.monitorService.refreshState()
            await fetchTodaysSteps()
            await fetchChartData()
        }
        
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        updateBattery()
        fetchMissedReflections()
    }
    
    private func fetchReminders() -> [Reminder] {
        do {
            let descriptor = FetchDescriptor<Reminder>(sortBy: [SortDescriptor(\.threshold, order: .reverse)])
            let reminders = try modelContext.fetch(descriptor)
            
            let groupedReminders = Dictionary(grouping: reminders) { $0.measurementType }
            
            let sortedKeys = groupedReminders.keys.sorted { lhs, rhs in
                if lhs == .heartRate {
                    return true
                } else if rhs == .heartRate {
                    return false
                } else {
                    return lhs.rawValue < rhs.rawValue
                }
            }
            
            return sortedKeys.flatMap { key in
                groupedReminders[key]?.sorted(by: { $0.threshold > $1.threshold }) ?? []
            }
        } catch {
            print("DEBUG: Could not fetch Reminders: \(error.localizedDescription)")
            return []
        }
    }
    
    func requestCreateReflectionOnPhone() {
        Services.shared.systemDelegate.requestCreateReflectionOnPhone()
    }
    
    func togglePauseResume() {
        guard usesLiveServices else {
            isManuallyPaused.toggle()
            isMonitoring = !isManuallyPaused
            statusMessage = isManuallyPaused ? .paused : .monitoring
            return
        }
        if isManuallyPaused {
            Services.shared.monitorService.resumeMonitoring()
        } else {
            Services.shared.monitorService.pauseMonitoring()
        }
    }
    
    func didSelectTab(_ tab: HomePage) {
        guard usesLiveServices else { return }
        switch tab {
        case .heartRateChart:
            heartRateSamples = Services.shared.monitorService.recentHeartRateSamples
        case .stepsChart:
            Task { await fetchChartData() }
        default:
            break
        }
    }
    
    func fetchChartData() async {
        self.hourlyStepData = await Services.shared.monitorService.fetchHourlyStepData()
    }
    
    func fetchTodaysSteps() async {
        let steps = await Services.shared.monitorService.fetchTodaysSteps()
        self.todaysSteps = Int(steps)
    }
    
    private func triggerInAppAlert(for rule: AlertRule) {
        guard alertState == .none else { return }
        guard let alertID = rule.alertID else { return }
        self.alertState = .showing(rule: rule, alertID: alertID)
        
        switch rule.reminderType {
        case .light:
            lightAlertCount += 1
            WKInterfaceDevice.current().play(.success)
        case .medium:
            mediumAlertCount += 1
            WKInterfaceDevice.current().play(.stop)
        case .strong:
            strongAlertCount += 1
            Task {
                for _ in 0..<3 {
                    WKInterfaceDevice.current().play(.failure)
                    try? await Task.sleep(for: .milliseconds(500))
                }
            }
        }
        savePersistentCounts()
        UserDefaults.standard.set(Date(), forKey: StorageKeys.lastAlertDate)
        fetchMissedReflections()
    }
    
    func handleAlertAction(shouldAddDetails: Bool, alertID: UUID) {
        guard case .showing(let rule, _) = alertState else { return }
        
        if usesLiveServices { muteDayStepsIfNeeded(for: rule) }
        defer { alertState = .none }
        
        if shouldAddDetails {
            Services.shared.navigationManager.pendingActivitySelection = ActivitySelectionInfo(
                id: alertID,
                reminderID: rule.id
            )
            return
        }
        
        guard usesLiveServices else { return }
        Services.shared.systemDelegate.createAndSendReflection(
            reminderID: rule.id,
            alertID: alertID,
            activity: nil,
            subactivity: nil
        )
    }
    
    func dismissAlertOverlay() {
        if usesLiveServices, case .showing(let rule, _) = alertState {
            muteDayStepsIfNeeded(for: rule)
        }
        alertState = .none
    }
    
    private func checkForDailyReset() {
        let userDefaults = UserDefaults.standard
        guard let lastDate = userDefaults.object(forKey: StorageKeys.lastAlertDate) as? Date else { return }
        
        if !Calendar.current.isDateInToday(lastDate) {
            strongAlertCount = 0
            mediumAlertCount = 0
            lightAlertCount = 0
            savePersistentCounts()
        }
    }
    
    private func loadPersistentCounts() {
        let userDefaults = UserDefaults.standard
        strongAlertCount = userDefaults.integer(forKey: StorageKeys.strongAlertCount)
        mediumAlertCount = userDefaults.integer(forKey: StorageKeys.mediumAlertCount)
        lightAlertCount = userDefaults.integer(forKey: StorageKeys.lightAlertCount)
    }
    
    private func savePersistentCounts() {
        let userDefaults = UserDefaults.standard
        userDefaults.set(strongAlertCount, forKey: StorageKeys.strongAlertCount)
        userDefaults.set(mediumAlertCount, forKey: StorageKeys.mediumAlertCount)
        userDefaults.set(lightAlertCount, forKey: StorageKeys.lightAlertCount)
    }
    
    private func updateBattery() {
        batteryLevel = WKInterfaceDevice.current().batteryLevel
    }
    
    private func fetchMissedReflections() {
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let allReflections = try modelContext.fetch(descriptor)
            let missedReflections = allReflections.filter { $0.isMissedReflection && !$0.isRejected }
            missedReflectionsCount = missedReflections.count
        } catch {
            print("DEBUG: Could not fetch missed reflections: \(error.localizedDescription)")
            missedReflectionsCount = 0
        }
    }
    
    private func muteDayStepsIfNeeded(for rule: AlertRule) {
        guard rule.measurementType == .steps, rule.interval == .oneDay else { return }
        StepDayMuteStore.muteForToday()
    }
}

extension Double {
    func toInt() -> Int { Int(self) }
}

extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
        if range.startIndex >= self.startIndex && range.endIndex <= self.endIndex {
            return self[range]
        }
        return nil
    }
}

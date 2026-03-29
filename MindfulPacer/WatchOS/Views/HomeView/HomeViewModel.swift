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
    var isMonitoring: Bool = false
    var isShowingActiveRules = false
    var isShowingAppInfoSheet = false
    var todaysSteps: Int = 0
    var activeRules: [AlertRule] = []
    var selectedTab: HomePage = .main
    var batteryLevel: Float = WKInterfaceDevice.current().batteryLevel
    
    var showAppInfo: Bool = false
    var showBatteryInfo: Bool = false
    var showStatusInfo: Bool = false
    var showMissedReflectionsInfo: Bool = false
    
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
    
    enum ChartMetric { case heartRate, steps }

    struct ChartEmptyState {
        let title: LocalizedStringResource
        let subtitle: LocalizedStringResource
        let symbol: String
    }

    var hasHeartRateData: Bool { isMonitoring && !heartRateSamples.isEmpty }
    var hasStepsData: Bool { !hourlyStepData.isEmpty }

    func emptyState(for metric: ChartMetric) -> ChartEmptyState {
        if statusMessage == .permissionDenied {
            return ChartEmptyState(
                title: "Health Permission Needed",
                subtitle: "Enable \(metric == .heartRate ? "Heart Rate" : "Steps") access in the Health settings on your iPhone.",
                symbol: "hand.raised.fill"
            )
        }

        switch metric {
        case .heartRate:
            return ChartEmptyState(
                title: "Not enough heart rate samples yet",
                subtitle: "Keep the app running for a moment. We’ll show the last hour as soon as we have enough data.",
                symbol: "waveform.path.ecg"
            )

        case .steps:
            if isManuallyPaused {
                return ChartEmptyState(
                    title: "Monitoring Paused",
                    subtitle: "Resume monitoring to continue collecting step data.",
                    symbol: "pause.circle.fill"
                )
            }

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

    var stepsThresholdRules: [AlertRule] {
        let allowed: [Reminder.Interval] = [.thirtyMinutes, .oneHour]
        return activeRules.filter { rule in
            allowed.contains(rule.interval) &&
            (rule.measurementType == .steps)
        }
    }
    
    private var heartRateDisplayedThresholds: [Double] {
        heartRateThresholdRules.compactMap {
            if case .heartRate(let t) = $0.ruleType { return t }
            return nil
        }
    }

    private var stepsDisplayedThresholds: [Double] {
        stepsThresholdRules.compactMap {
            if case .steps(let t) = $0.ruleType { return t }
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
        let dataMin = heartRateSamples.map(\.value).min() ?? 60.0
        let dataMax = heartRateSamples.map(\.value).max() ?? 100.0

        let thrMin = heartRateDisplayedThresholds.min()
        let thrMax = heartRateDisplayedThresholds.max()

        let overallMin = min(dataMin, thrMin ?? dataMin)
        let overallMax = max(dataMax, thrMax ?? dataMax)

        guard overallMax > overallMin else {
            return paddedDomain(min: overallMin - 1, max: overallMax + 1)
        }
        return paddedDomain(min: overallMin, max: overallMax)
    }
    
    var stepsChartYDomain: ClosedRange<Double> {
        let dataValues = hourlyStepData.map(\.steps)
        let dataMin = dataValues.min() ?? 0
        let dataMax = dataValues.max() ?? max(500, dataMin)

        let thrMin = stepsDisplayedThresholds.min()
        let thrMax = stepsDisplayedThresholds.max()

        var overallMin = min(dataMin, thrMin ?? dataMin)
        let overallMax = max(dataMax, thrMax ?? dataMax)

        overallMin = max(0, overallMin)

        guard overallMax > overallMin else {
            return paddedDomain(min: overallMin, max: overallMax + 1)
        }
        return paddedDomain(min: overallMin, max: overallMax)
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
            let heartRateValue = 75.0 + (sineValue * 15.0) + Double.random(in: -2...2)
            samples.append((value: heartRateValue, date: date))
        }
        self.heartRateSamples = samples.reversed()
        
        var stepData: [(date: Date, steps: Double)] = []
        for i in 0..<12 {
            let timeInterval = Double(i) * -300
            let date = now.addingTimeInterval(timeInterval)
            let steps = Double.random(in: 50...300)
            stepData.append((date: date, steps: steps))
        }
        self.hourlyStepData = stepData.reversed()
    }
    
    static var mock: HomeViewModel {
        HomeViewModel(isForPreview: true)
    }
    
    private func setupSubscriptions() {
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
    
    func onAppear() {
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
        if isManuallyPaused {
            Services.shared.monitorService.resumeMonitoring()
        } else {
            Services.shared.monitorService.pauseMonitoring()
        }
    }
    
    func didSelectTab(_ tab: HomePage) {
        switch tab {
        case .heartRateChart:
            break
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
        
        muteDayStepsIfNeeded(for: rule)
        defer { alertState = .none }
        
        if shouldAddDetails {
            Services.shared.navigationManager.pendingActivitySelection = ActivitySelectionInfo(
                id: alertID,
                reminderID: rule.id
            )
            return
        }
        
        Services.shared.systemDelegate.createAndSendReflection(
            reminderID: rule.id,
            alertID: alertID,
            activity: nil,
            subactivity: nil
        )
    }
    
    func dismissAlertOverlay() {
        if case .showing(let rule, _) = alertState {
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
    
    var batteryImageName: String {
        switch batteryLevel {
        case 0.75...: return "battery.100percent"
        case 0.5..<0.75: return "battery.75percent"
        case 0.25..<0.5: return "battery.50percent"
        case 0.01..<0.25: return "battery.25percent"
        default: return "battery.0percent"
        }
    }
    
    var batteryTintColor: Color {
        switch batteryLevel {
        case ..<0.2: return .red
        case ..<0.5: return .yellow
        default: return .green
        }
    }
    
    private func fetchMissedReflections() {
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\.date, order: .reverse)]
            )
            let allReflections = try modelContext.fetch(descriptor)
            let missedReflections = allReflections.filter { $0.isMissedReflection }
            missedReflectionsCount = missedReflections.count
        } catch {
            print("DEBUG: Could not fetch missed reflections: \(error.localizedDescription)")
            missedReflectionsCount = 0
        }
    }
    
    private func paddedDomain(
        min minValue: Double,
        max maxValue: Double,
        padFraction: Double = 0.25,
        minSpan: Double = 10
    ) -> ClosedRange<Double> {
        let span = maxValue - minValue
        let pad = Swift.max(span * padFraction, minSpan * 0.1)
        let lo = minValue - pad
        let hi = maxValue + pad
        return lo...hi
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

//
//  HomeViewModel.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import Foundation
import Combine
import WatchKit
import SwiftUI
import SwiftData

struct StorageKeys {
    static let strongAlertCount = "strongAlertCount"
    static let mediumAlertCount = "mediumAlertCount"
    static let lightAlertCount = "lightAlertCount"
    static let lastAlertDate = "lastAlertDate"
}

enum AlertState {
    case none
    case flashing(color: Color, type: Reminder.MeasurementType)
    case solid(color: Color)
    case strong(rule: AlertRule)
}

extension AlertState: Equatable {
    static func == (lhs: AlertState, rhs: AlertState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
            
        case (.flashing(let lhsColor, let lhsType), .flashing(let rhsColor, let rhsType)):
            return lhsColor == rhsColor && lhsType == rhsType
            
        case (.solid(let lhsColor), .solid(let rhsColor)):
            return lhsColor == rhsColor
            
        case (.strong(let lhsRule), .strong(let rhsRule)):
            return lhsRule.id == rhsRule.id
            
        default:
            return false
        }
    }
}

@MainActor
@Observable
class HomeViewModel {
    var statusMessage: StatusMessage = .initializing
    var heartRate: Double = 0
    var isMonitoring: Bool = false
    var isShowingActiveRules = false
    var isShowingAppInfoSheet = false
    var todaysSteps: Int = 0
    var activeRules: [AlertRule] = []
    var defaultActivities: [Activity] = []
    var selectedTab: HomePage = .main
    var batteryLevel: Float = WKInterfaceDevice.current().batteryLevel
    
    var showAppInfo: Bool = false
    var showBatteryInfo: Bool = false
    var showStatusInfo: Bool = false
    
    var alertState: AlertState = .none
    
    var heartRateSamples: [(value: Double, date: Date)] = []
    var hourlyStepData: [(date: Date, steps: Double)] = []
    
    var strongAlertCount: Int = 0
    var mediumAlertCount: Int = 0
    var lightAlertCount: Int = 0
    
    private let fetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase
    
    var avgHeartRate: Int {
        guard !heartRateSamples.isEmpty else { return 0 }
        let sum = heartRateSamples.reduce(0) { $0 + $1.value }
        return Int(sum / Double(heartRateSamples.count))
    }
    
    var minHeartRate: Int {
        (heartRateSamples.min(by: { $0.value < $1.value })?.value ?? 0).toInt()
    }
    
    var maxHeartRate: Int {
        (heartRateSamples.max(by: { $0.value < $1.value })?.value ?? 0).toInt()
    }
    
    var downsampledHeartRateSamples: [(value: Double, date: Date)] {
        let maxDataPoints = 150
        guard heartRateSamples.count > maxDataPoints else {
            return heartRateSamples
        }
        
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
        
        print("DEBUGY: Downsampling HR data from \(heartRateSamples.count) to \(downsampledData.count) points.")
        return downsampledData
    }
    
    var heartRateChartYDomain: ClosedRange<Int> {
        let dataValues = heartRateSamples.map { $0.value }
        let minDataY = dataValues.min() ?? 60.0
        let maxDataY = dataValues.max() ?? 100.0
        
        let thresholdValues = activeRules.compactMap { rule -> Double? in
            if case .heartRate(let threshold) = rule.ruleType {
                return threshold
            }
            return nil
        }
        let minThresholdY = thresholdValues.min()
        let maxThresholdY = thresholdValues.max()
        
        let overallMin = min(minDataY, minThresholdY ?? minDataY)
        let overallMax = max(maxDataY, maxThresholdY ?? maxDataY)
        
        return (Int(overallMin) - 10)...(Int(overallMax) + 10)
    }
    
    var stepsChartYDomain: ClosedRange<Int> {
        let maxDataY = hourlyStepData.map { $0.steps }.max() ?? 500.0
        
        let thresholdValues = activeRules.compactMap { rule -> Double? in
            if case .steps(let threshold) = rule.ruleType {
                return threshold
            }
            return nil
        }
        let maxThresholdY = thresholdValues.max()
        
        let overallMax = max(maxDataY, maxThresholdY ?? maxDataY)
        
        return 0...(Int(overallMax) + 100)
    }
    
    private var refreshTimer: Timer?
    private let monitorService = HealthMonitorService.shared
    private var cancellables = Set<AnyCancellable>()
    private let fetchRemindersUseCase: FetchRemindersUseCase
    
    init() {
        self.fetchRemindersUseCase = DefaultFetchRemindersUseCase(modelContext: ModelContainer.prod.mainContext)
        self.fetchDefaultActivitiesUseCase = DefaultFetchDefaultActivitiesUseCase(modelContext: ModelContainer.prod.mainContext)
        
        SystemDelegate.shared.configure()
        monitorService.configure(fetchRemindersUseCase: self.fetchRemindersUseCase)
        
        loadPersistentCounts()
        checkForDailyReset()
        
        setupSubscriptions()
        loadDefaultActivities()
    }
    
    private init(isForPreview: Bool) {
        let container = try! ModelContainer(for: Reminder.self, Activity.self)
        self.fetchRemindersUseCase = DefaultFetchRemindersUseCase(modelContext: container.mainContext)
        self.fetchDefaultActivitiesUseCase = DefaultFetchDefaultActivitiesUseCase(modelContext: container.mainContext)
        
        self.statusMessage = .monitoring
        self.isMonitoring = true
        self.heartRate = 78
        
        self.strongAlertCount = 1
        self.mediumAlertCount = 0
        self.lightAlertCount = 2
        
        let now = Date()
        var samples: [(value: Double, date: Date)] = []
        for i in 0..<60 { // 60 data points
            let timeInterval = Double(i) * -60
            let date = now.addingTimeInterval(timeInterval)
            let sineValue = sin(Double(i) * 0.2)
            let heartRateValue = 75.0 + (sineValue * 15.0) + Double.random(in: -2...2)
            samples.append((value: heartRateValue, date: date))
        }
        self.heartRateSamples = samples.reversed()
        
        var stepData: [(date: Date, steps: Double)] = []
        for i in 0..<12 {
            let timeInterval = Double(i) * -300 // 5 minutes
            let date = now.addingTimeInterval(timeInterval)
            let steps = Double.random(in: 50...300)
            stepData.append((date: date, steps: steps))
        }
        self.hourlyStepData = stepData.reversed()
    }
    
    private func loadDefaultActivities() {
        if let activities = fetchDefaultActivitiesUseCase.execute() {
            self.defaultActivities = activities
        }
    }
    
    static var mock: HomeViewModel {
        HomeViewModel(isForPreview: true)
    }
    
    private func setupSubscriptions() {
        monitorService.$statusMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newStatus in self?.statusMessage = newStatus }
            .store(in: &cancellables)
        
        monitorService.$heartRate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newHeartRate in self?.heartRate = newHeartRate }
            .store(in: &cancellables)
        
        monitorService.$isSessionActive
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newIsMonitoring in self?.isMonitoring = newIsMonitoring }
            .store(in: &cancellables)
        
        monitorService.alertTriggeredSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rule in self?.triggerInAppAlert(for: rule) }
            .store(in: &cancellables)
        
        monitorService.$recentHeartRateSamples
            .receive(on: DispatchQueue.main)
            .sink { [weak self] samples in self?.heartRateSamples = samples }
            .store(in: &cancellables)
        
        monitorService.$activeRules
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newRules in self?.activeRules = newRules }
            .store(in: &cancellables)
        
        monitorService.mediumAlertCancelledSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.cancelMediumAlert()
            }
            .store(in: &cancellables)
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchChartData()
            }
        }
    }
    
    func onAppear() {
        Task {
            let isAuthorized = try await monitorService.requestAuthorization()
            
            guard isAuthorized else {
                self.statusMessage = .authDenied
                return
            }
            
            self.monitorService.refreshState()
            await fetchTodaysSteps()
            await fetchChartData()
        }
        
        let device = WKInterfaceDevice.current()
        device.isBatteryMonitoringEnabled = true
        updateBattery()
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("WKInterfaceDeviceBatteryLevelDidChangeNotification"),
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                self.updateBattery()
            }
        }
    }
    
    func requestCreateReflectionOnPhone() {
        SystemDelegate.shared.requestCreateReflectionOnPhone()
    }
    
    func fetchChartData() async {
        self.hourlyStepData = await monitorService.fetchHourlyStepData()
    }
    
    func fetchTodaysSteps() async {
        let steps = await monitorService.fetchTodaysSteps()
        self.todaysSteps = Int(steps)
    }
    
    private func triggerInAppAlert(for rule: AlertRule) {
        // --- Light Alert: A quick, transient flash on a specific widget ---
        if rule.reminderType == .light {
            guard alertState == .none else { return }
            
            // Set the state to flashing, passing the color AND the measurement type.
            alertState = .flashing(color: rule.reminderType.color, type: rule.measurementType)
            lightAlertCount += 1
            WKInterfaceDevice.current().play(.success)
            
            // After a delay, reset the state back to none.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.alertState = .none
            }
        }
        
        // --- Medium Alert: A persistent solid background ---
        if rule.reminderType == .medium {
            if alertState != .solid(color: rule.reminderType.color) {
                alertState = .solid(color: rule.reminderType.color)
                mediumAlertCount += 1
                WKInterfaceDevice.current().play(.stop)
            }
        }
        
        if rule.reminderType == .strong {
            if case .strong = alertState {
            } else {
                alertState = .strong(rule: rule)
                strongAlertCount += 1
                Task {
                    for _ in 0..<3 {
                        WKInterfaceDevice.current().play(.failure)
                        try? await Task.sleep(for: .milliseconds(500))
                    }
                }
            }
        }
        
        savePersistentCounts()
        UserDefaults.standard.set(Date(), forKey: StorageKeys.lastAlertDate)
    }
    
    func cancelMediumAlert() {
        if case .solid = alertState {
            print("DEBUGY: ViewModel cancelling medium alert.")
            alertState = .none
        }
    }
    
    func handleStrongAlertAction(shouldAddDetails: Bool) {
        guard case .strong(let rule) = alertState else { return }
        
        if shouldAddDetails {
            NavigationManager.shared.reminderIDForActivitySelection = rule.id
        } else {
            SystemDelegate.shared.createAndSendReflection(reminderID: rule.id, activity: nil, subactivity: nil)
        }
        
        self.alertState = .none
    }
    
    func rejectStrongAlert() {
        self.alertState = .none
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
}

extension Double {
    func toInt() -> Int { Int(self) }
}

extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
        if range.startIndex > self.endIndex || range.endIndex > self.endIndex {
            return nil
        }
        return self[range]
    }
}

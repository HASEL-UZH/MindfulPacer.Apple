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

@MainActor
@Observable
class HomeViewModel {
    var statusMessage: StatusMessage = .initializing
    var heartRate: Double = 0
    var isMonitoring: Bool = false
    var isShowingActiveRules = false
    var isShowingAppInfoSheet = false
    var isAlerting: Bool = false
    var alertColor: Color = .clear
    var todaysSteps: Int = 0
    var activeRules: [AlertRule] = []
    var selectedTab: HomePage = .main
    var batteryLevel: Float = WKInterfaceDevice.current().batteryLevel
    
    var showAppInfo: Bool = false
    var showBatteryInfo: Bool = false
    var showStatusInfo: Bool = false
    
    var heartRateSamples: [(value: Double, date: Date)] = []
    var hourlyStepData: [(date: Date, steps: Double)] = []
    
    var strongAlertCount: Int = 0
    var mediumAlertCount: Int = 0
    var lightAlertCount: Int = 0
    
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
        SystemDelegate.shared.configure()
        monitorService.configure(fetchRemindersUseCase: self.fetchRemindersUseCase)
        
        loadPersistentCounts()
        checkForDailyReset()
        
        setupSubscriptions()
    }
    
    private init(isForPreview: Bool) {
        let container = try! ModelContainer(for: Reminder.self)
        self.fetchRemindersUseCase = DefaultFetchRemindersUseCase(modelContext: container.mainContext)
        
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
    
    private func triggerInAppAlert(for rule: HeartRateAlertRule) {
        guard !isAlerting else { return }
        self.isAlerting = true
        self.alertColor = rule.type.color
        
        switch rule.type {
        case .light:
            lightAlertCount += 1
            WKInterfaceDevice.current().play(.success)
        case .medium:
            mediumAlertCount += 1
            WKInterfaceDevice.current().play(.click)
        case .strong:
            strongAlertCount += 1
            WKInterfaceDevice.current().play(.failure)
        }
        
        savePersistentCounts()
        UserDefaults.standard.set(Date(), forKey: StorageKeys.lastAlertDate)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.isAlerting = false
        }
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

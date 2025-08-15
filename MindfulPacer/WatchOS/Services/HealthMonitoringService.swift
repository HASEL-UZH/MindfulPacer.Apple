//
//  HealthMonitoringService.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import Foundation
import HealthKit
import SwiftData
import UserNotifications
import Combine
import SwiftUI
import CoreData

// MARK: - StatusMessage

enum StatusMessage: String {
    case notConfigured = "Not Configured"
    case configured = "Configured"
    case ready = "Ready"
    case noHRReminders = "No HR Reminders"
    case initializing = "Initializing..."
    case authDenied = "Auth Denied"
    case collectionFailed = "Collection Failed"
    case monitoring = "Monitoring Active"
    case sessionFailed = "Session Failed"
    case stopped = "Stopped"
    case syncing = "Syncing..."
    
    var symbolName: String {
        switch self {
        case .notConfigured: return "exclamationmark.triangle"
        case .configured: return "checkmark.circle"
        case .ready: return "bolt.heart"
        case .noHRReminders: return "bell.slash"
        case .initializing: return "hourglass"
        case .authDenied: return "lock.slash"
        case .collectionFailed: return "xmark.octagon"
        case .monitoring: return "waveform.path.ecg"
        case .sessionFailed: return "exclamationmark.octagon"
        case .stopped: return "stop.circle"
        case .syncing: return "arrow.triangle.2.circlepath.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .notConfigured: return .yellow
        case .configured: return .green
        case .ready: return .blue
        case .noHRReminders: return .gray
        case .initializing: return .orange
        case .authDenied: return .red
        case .collectionFailed: return .red
        case .monitoring: return .brandPrimary
        case .sessionFailed: return .red
        case .stopped: return .gray
        case .syncing: return .cyan
        }
    }
    
    var description: String {
        switch self {
        case .notConfigured:
            return "The health monitoring service has not been configured yet. You may need to set up reminder rules or link required services."
        case .configured:
            return "The service is configured with reminders but not currently running a monitoring session."
        case .ready:
            return "All rules are active and the system is ready to start monitoring at any time."
        case .noHRReminders:
            return "No active heart rate reminders are set, so monitoring will not start until a rule is added."
        case .initializing:
            return "The monitoring service is starting up and preparing the HealthKit session."
        case .authDenied:
            return "HealthKit access was denied. The app cannot read heart rate or step data until access is granted in Settings."
        case .collectionFailed:
            return "The system failed to collect health data from HealthKit. This might be due to missing permissions or unavailable data."
        case .monitoring:
            return "Monitoring is currently active, with HealthKit data being collected and rules evaluated."
        case .sessionFailed:
            return "The monitoring session could not be started or has failed unexpectedly."
        case .stopped:
            return "The monitoring session has ended, and no data is currently being collected."
        case .syncing:
            return "The app is syncing data with CloudKit or another backend service."
        }
    }
}


enum RuleType: Sendable {
    case heartRate(threshold: Double)
    case steps(threshold: Double)
}

public struct AlertRule: Identifiable, Sendable {
    public let id: UUID
    let measurementType: Reminder.MeasurementType
    let ruleType: RuleType
    let duration: TimeInterval
    let color: Color
    let alertMessage: String
    
    var triggerDate: Date? = nil
    var dipDate: Date? = nil
    var collectedData: [(value: Double, date: Date)] = []
    
    var notificationSent: Bool = false
}

public struct HeartRateAlertRule: Identifiable {
    public let id: UUID
    var thresholdBPM: Double
    var duration: TimeInterval
    var alertMessage: String
    var type: Reminder.ReminderType
    var triggerDate: Date? = nil
    var dipDate: Date? = nil
    var collectedData: [(value: Double, date: Date)] = []
}

public struct StepsAlertRule: Identifiable, Sendable {
    public let id: UUID
    var thresholdSteps: Double
    var duration: TimeInterval
    var alertMessage: String
    var type: Reminder.ReminderType
    var notificationSent: Bool = false
}

@MainActor
final class HealthMonitorService: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
    
    static let shared = HealthMonitorService()
    
    @Published var heartRate: Double = 0
    @Published var isSessionActive = false
    @Published var statusMessage: StatusMessage = .notConfigured
    @Published private(set) var recentHeartRateSamples: [(value: Double, date: Date)] = []
    @Published private(set) var activeRules: [AlertRule] = []

    let alertTriggeredSubject = PassthroughSubject<HeartRateAlertRule, Never>() // TODO: Needs to use alert rule not hr alert rule as it needs to work for steps and hr
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    private var fetchRemindersUseCase: FetchRemindersUseCase?
    private var cancellables = Set<AnyCancellable>()
        
    private var stepsCheckTimer: Timer?
    private var alertDataCache: [UUID: [(value: Double, date: Date)]] = [:]
    
    private override init() {
        super.init()
        subscribeToCloudKitChanges()
    }
    
    private func subscribeToCloudKitChanges() {
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("DEBUGY: CloudKit data change detected. Refreshing state.")
                self?.refreshState()
            }
            .store(in: &cancellables)
    }
    
    func configure(fetchRemindersUseCase: FetchRemindersUseCase) {
        self.fetchRemindersUseCase = fetchRemindersUseCase
        self.statusMessage = .configured
    }
    
    func data(for alertID: UUID) -> [(value: Double, date: Date)]? {
        return alertDataCache[alertID]
    }
    
    func refreshState() {
        print("DEBUGY: Refreshing state triggered.")
        let hasRules = updateMonitoringRules()
        
        if isSessionActive {
            self.statusMessage = .monitoring
        } else {
            self.statusMessage = hasRules ? .ready : .noHRReminders
        }
        print("DEBUGY: Final status set to: \(self.statusMessage.rawValue)")
        
        _startOrStopMonitoring(hasRules: hasRules)
    }
    
    func fetchTodaysSteps() async -> Double {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startDate = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )
        
        do {
            let result = try await query.result(for: healthStore)
            
            guard let sum = result?.sumQuantity() else {
                print("DEBUGY: Fetched today's steps: 0 (no data)")
                return 0
            }
            
            let totalSteps = sum.doubleValue(for: HKUnit.count())
            
            print("DEBUGY: Fetched today's steps: \(totalSteps)")
            return totalSteps
        } catch {
            print("DEBUGY: ERROR - Failed to fetch today's steps: \(error.localizedDescription)")
            return 0
        }
    }
    
    private func updateMonitoringRules() -> Bool {
        guard let useCase = fetchRemindersUseCase else {
            self.statusMessage = .notConfigured
            return false
        }
        let allReminders = useCase.execute() ?? []
        
        let heartRateReminders = allReminders.filter { $0.measurementType == .heartRate }
        let stepsReminders = allReminders.filter { $0.measurementType == .steps }
        
        self.activeRules = allReminders.map { reminder in
            let ruleType: RuleType
            if reminder.measurementType == .heartRate {
                ruleType = .heartRate(threshold: Double(reminder.threshold))
            } else {
                ruleType = .steps(threshold: Double(reminder.threshold))
            }
            
            return AlertRule(
                id: reminder.id,
                measurementType: reminder.measurementType,
                ruleType: ruleType,
                duration: reminder.interval.timeInterval,
                color: reminder.reminderType.color, // Store the color directly
                alertMessage: reminder.triggerSummary
            )
        }
        
        let hasActiveRules = !self.activeRules.isEmpty
        self.statusMessage = hasActiveRules ? .ready : .noHRReminders
        
        return hasActiveRules
    }
    
    private func _startOrStopMonitoring(hasRules: Bool) {
        let sessionIsRunning = workoutSession?.state == .running
        if hasRules && !sessionIsRunning {
            startWorkoutSession()
        } else if !hasRules && sessionIsRunning {
            endWorkoutSession()
        }
    }
    
    private func startWorkoutSession() {
        guard workoutSession == nil else { return }
        Task {
            do {
                let isAuthorized = try await requestAuthorization()
                guard isAuthorized else {
                    self.statusMessage = .authDenied
                    return
                }
                
                let configuration = HKWorkoutConfiguration()
                configuration.activityType = .mindAndBody
                configuration.locationType = .unknown
                
                self.workoutSession = try HKWorkoutSession(healthStore: self.healthStore, configuration: configuration)
                self.workoutBuilder = self.workoutSession?.associatedWorkoutBuilder()
                self.workoutSession?.delegate = self
                self.workoutBuilder?.delegate = self // This line will now compile correctly.
                self.workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: configuration)
                
                self.workoutSession?.startActivity(with: Date())
                try await self.workoutBuilder?.beginCollection(at: Date())
                self.isSessionActive = true
                self.statusMessage = .monitoring
                self.startStepsTimer()
            } catch {
                self.statusMessage = .sessionFailed
            }
        }
    }

    private func endWorkoutSession() {
        stepsCheckTimer?.invalidate()
        stepsCheckTimer = nil
        workoutSession?.end()
        workoutSession = nil
        workoutBuilder = nil
        isSessionActive = false
        heartRate = 0
        statusMessage = .stopped
        activeRules = []
    }

    func requestAuthorization() async throws -> Bool {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: success)
            }
        }
    }
    
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType, quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            if let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                Task { @MainActor in
                    self.processHeartRate(value)
                }
            }
        }
    }
    
    func fetchHourlyStepData() async -> [(date: Date, steps: Double)] {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startDate = now.addingTimeInterval(-3600) // 1 hour ago
        let anchorDate = Calendar.current.startOfDay(for: now)
        let interval = DateComponents(minute: 5) // Still aggregate in 5-minute chunks
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let queryDescriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        do {
            let collection = try await queryDescriptor.result(for: healthStore)
            var cumulativeStepData: [(date: Date, steps: Double)] = []
            var runningTotal: Double = 0.0
            
            // Enumerate through the 5-minute intervals in the last hour.
            collection.enumerateStatistics(from: startDate, to: now) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let stepsInInterval = sum.doubleValue(for: .count())
                    // Add the steps from this interval to our running total.
                    runningTotal += stepsInInterval
                    // Append the CUMULATIVE total with the interval's end date.
                    cumulativeStepData.append((date: statistics.endDate, steps: runningTotal))
                }
            }
            print("DEBUGY: Fetched \(cumulativeStepData.count) intervals of CUMULATIVE step data.")
            return cumulativeStepData
        } catch {
            print("DEBUGY: ERROR - Failed to fetch hourly step data: \(error.localizedDescription)")
            return []
        }
    }
    
    private func processHeartRate(_ newHeartRate: Double) {
        self.heartRate = newHeartRate
        
        let now = Date()
        self.recentHeartRateSamples.append((value: newHeartRate, date: now))
        
        let oneHourAgo = now.addingTimeInterval(-3600)
        self.recentHeartRateSamples.removeAll { $0.date < oneHourAgo }
        
        self.evaluateHeartRateRules(for: newHeartRate)
    }
    
    private func evaluateHeartRateRules(for currentHeartRate: Double) {
        let dipGracePeriod: TimeInterval = 30.0
        for i in 0..<activeRules.count {
            guard activeRules[i].measurementType == .heartRate else { continue }
            
            guard case .heartRate(let threshold) = activeRules[i].ruleType else { continue }
            
            var rule = activeRules[i]
            
            if currentHeartRate > threshold {
                if rule.triggerDate == nil { rule.triggerDate = Date() }
                rule.dipDate = nil
                rule.collectedData.append((value: currentHeartRate, date: Date()))
                if let triggerDate = rule.triggerDate, Date().timeIntervalSince(triggerDate) >= rule.duration {
                    self.sendNotification(for: rule)
                    rule.triggerDate = nil
                    rule.collectedData = []
                }
            } else {
                if rule.triggerDate != nil {
                    if rule.dipDate == nil { rule.dipDate = Date() }
                    if let dipDate = rule.dipDate, Date().timeIntervalSince(dipDate) > dipGracePeriod {
                        rule.triggerDate = nil
                        rule.dipDate = nil
                        rule.collectedData = []
                    }
                }
            }
            activeRules[i] = rule
        }
    }
    
    private func startStepsTimer() {
        stepsCheckTimer?.invalidate()
        stepsCheckTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                print("DEBUGY: Steps timer fired. Checking step rules.")
                self?.checkStepRules()
            }
        }
    }
    
    private func checkStepRules() {
        let stepRulesToCheck = self.activeRules.filter { $0.measurementType == .steps }
        guard !stepRulesToCheck.isEmpty else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        for rule in stepRulesToCheck {
            guard case .steps(let threshold) = rule.ruleType else { continue }
            
            let endDate = Date()
            let startDate = endDate.addingTimeInterval(-rule.duration)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    if let error = error { print("DEBUGY: Steps query failed: \(error.localizedDescription)") }
                    return
                }
                let totalSteps = sum.doubleValue(for: HKUnit.count())
                
                Task { @MainActor in
                    guard let index = self.activeRules.firstIndex(where: { $0.id == rule.id }) else {
                        return
                    }
                    
                    if totalSteps > threshold {
                        if !self.activeRules[index].notificationSent {
                            print("DEBUGY: Step threshold EXCEEDED for rule \(rule.id). Sending notification.")
                            self.sendNotification(for: self.activeRules[index])
                            self.activeRules[index].notificationSent = true
                        }
                    } else {
                        if self.activeRules[index].notificationSent {
                            print("DEBUGY: Step count below threshold for rule \(rule.id). Resetting flag.")
                            self.activeRules[index].notificationSent = false
                        }
                    }
                }
            }
            self.healthStore.execute(query)
        }
    }
    
    private func sendNotification(for rule: HeartRateAlertRule) {
        let alertID = UUID()
        alertDataCache[alertID] = rule.collectedData
        let content = UNMutableNotificationContent()
        content.title = "Heart Rate Alert"
        content.body = rule.alertMessage
        content.sound = .defaultCritical
        content.categoryIdentifier = "HEART_RATE_ALERT"
        content.userInfo = ["alert_id": alertID.uuidString]
        let request = UNNotificationRequest(identifier: alertID.uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
        self.alertTriggeredSubject.send(rule)
    }
    
    private func sendNotification(for rule: AlertRule) {
        let alertID = UUID()
        if rule.measurementType == .heartRate {
            alertDataCache[alertID] = rule.collectedData
        }
        
        let content = UNMutableNotificationContent()
        content.title = rule.measurementType == .heartRate ? "Heart Rate Alert" : "Steps Alert"
        content.body = rule.alertMessage
        content.sound = .defaultCritical
        content.categoryIdentifier = "HEART_RATE_ALERT"
        content.userInfo = [
               "alert_id": alertID.uuidString,
               "reminder_id": rule.id.uuidString
           ]
                   
        let request = UNNotificationRequest(identifier: alertID.uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

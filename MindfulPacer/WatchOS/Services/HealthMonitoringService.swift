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
import WidgetKit

// MARK: - StatusMessage

enum StatusMessage: String {
    case monitoring = "Monitoring Active"
    case notMonitoring = "Not Monitoring"
    case noReminders = "No Reminders Set"
    case permissionDenied = "Permission Denied"
    case error = "An Error Occurred"
    case syncing = "Syncing..."
    
    var symbolName: String {
        switch self {
        case .monitoring: return "checkmark"
        case .notMonitoring: return "xmark"
        case .noReminders: return "bell.slash"
        case .permissionDenied: return "lock.slash"
        case .error: return "exclamationmark.triangle"
        case .syncing: return "arrow.triangle.2.circlepath.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .monitoring: return .green
        case .notMonitoring: return .red
        case .noReminders: return .gray
        case .permissionDenied: return .red
        case .error: return .orange
        case .syncing: return .cyan
        }
    }
    
    var description: String {
        switch self {
        case .monitoring:
            return "The app is actively monitoring your health data based on your reminders."
        case .notMonitoring:
            return "Monitoring is currently inactive. This may be because no reminders are set or there was an issue."
        case .noReminders:
            return "Please add a reminder on your iPhone to begin monitoring."
        case .permissionDenied:
            return "Access to HealthKit was denied. Please grant permission in the Health app on your iPhone."
        case .error:
            return "An unexpected error occurred. Please try restarting the app."
        case .syncing:
            return "Syncing your latest reminders from iCloud..."
        }
    }
}

enum RuleType: Sendable {
    case heartRate(threshold: Double)
    case steps(threshold: Double)
}

public struct AlertRule: Identifiable, Sendable {
    public let id: UUID
    var alertID: UUID?
    let measurementType: Reminder.MeasurementType
    let reminderType: Reminder.ReminderType
    let ruleType: RuleType
    let duration: TimeInterval
    let alertMessage: String
    
    var triggerDate: Date? = nil
    var dipDate: Date? = nil
    var collectedData: [(value: Double, date: Date)] = []
    
    var notificationSent: Bool = false
}

@MainActor
final class HealthMonitorService: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
        
    @Published var heartRate: Double = 0
    @Published var isSessionActive = false
    @Published var statusMessage: StatusMessage = .notMonitoring
    @Published private(set) var recentHeartRateSamples: [(value: Double, date: Date)] = []
    @Published private(set) var activeRules: [AlertRule] = []
    
    let alertTriggeredSubject = PassthroughSubject<AlertRule, Never>()
    let mediumAlertCancelledSubject = PassthroughSubject<Void, Never>()
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    
    private var workoutBuilder: HKLiveWorkoutBuilder?
    
    private var fetchRemindersUseCase: FetchRemindersUseCase?
    private var cancellables = Set<AnyCancellable>()
    
    private var stepsCheckTimer: Timer?
    
    override init() {
        super.init()
        subscribeToCloudKitChanges()
    }
    
    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.MindfulPacer")
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
        self.statusMessage = .monitoring
    }
    
    func refreshState() {
        print("DEBUGY: Refreshing state triggered.")
        let hasRules = updateMonitoringRules()
        
        if isSessionActive {
            self.statusMessage = .monitoring
        } else {
            self.statusMessage = hasRules ? .notMonitoring : .noReminders
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
            return false
        }
        let allReminders = useCase.execute() ?? []
        
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
                reminderType: reminder.reminderType,
                ruleType: ruleType,
                duration: reminder.interval.timeInterval,
                alertMessage: reminder.triggerSummary
            )
        }
        
        let hasActiveRules = !self.activeRules.isEmpty
        self.statusMessage = hasActiveRules ? .monitoring : .noReminders
        
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
                    self.statusMessage = .permissionDenied
                    return
                }
                
                let configuration = HKWorkoutConfiguration()
                configuration.activityType = .mindAndBody
                configuration.locationType = .unknown
                
                self.workoutSession = try HKWorkoutSession(healthStore: self.healthStore, configuration: configuration)
                self.workoutBuilder = self.workoutSession?.associatedWorkoutBuilder()
                self.workoutSession?.delegate = self
                self.workoutBuilder?.delegate = self
                self.workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: configuration)
                
                self.workoutSession?.startActivity(with: Date())
                try await self.workoutBuilder?.beginCollection(at: Date())
                self.isSessionActive = true
                self.statusMessage = .monitoring
                self.startStepsTimer()
                
                self.sharedUserDefaults?.set(true, forKey: "isMonitoringActive")
                WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
                print("DEBUGY: Complication timeline reloaded (State: Active)")
            } catch {
                self.statusMessage = .error
            }
        }
    }
    
    private func endWorkoutSession() {
        stepsCheckTimer?.invalidate()
        stepsCheckTimer = nil
        workoutSession?.end()
        workoutBuilder?.discardWorkout()
        workoutSession = nil
        workoutBuilder = nil
        isSessionActive = false
        heartRate = 0
        statusMessage = .notMonitoring
        activeRules = []
        
        self.sharedUserDefaults?.set(false, forKey: "isMonitoringActive")
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
        print("DEBUGY: Complication timeline reloaded (State: Inactive)")
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
                
                if let triggerDate = rule.triggerDate, Date().timeIntervalSince(triggerDate) >= rule.duration {
                    let dataWindowStart = triggerDate.addingTimeInterval(-(rule.duration * 0.20))
                    let eventData = self.recentHeartRateSamples.filter { $0.date >= dataWindowStart }
                    self.sendNotification(for: rule, withData: eventData)
                    rule.triggerDate = nil
                }
            } else {
                if rule.reminderType == .medium {
                    if rule.triggerDate != nil {
                        print("DEBUGY: HR dropped below medium threshold. Sending cancel signal.")
                        self.mediumAlertCancelledSubject.send()
                    }
                }
                
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
                            self.sendNotification(for: self.activeRules[index], with: totalSteps)
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
    
    private func sendNotification(
        for rule: AlertRule,
        with steps: Double? = nil,
        withData heartRateData: [(value: Double, date: Date)] = []
    ) {
        let alertID = UUID()
        var samples: [MeasurementSample] = []
        
        switch rule.measurementType {
        case .heartRate:
            samples = heartRateData.map {
                MeasurementSample(type: .heartRate, value: $0.value, date: $0.date)
            }
        case .steps:
            if let totalSteps = steps {
                samples = [MeasurementSample(type: .steps, value: totalSteps, date: Date())]
            }
        }
        
        Services.shared.systemDelegate.cacheTriggerData(samples, for: alertID)

        let content = UNMutableNotificationContent()
        content.title = rule.measurementType == .heartRate ? "Heart Rate Alert" : "Steps Alert"
        content.body = rule.alertMessage
        content.sound = .defaultCritical
        content.categoryIdentifier = "HEART_RATE_ALERT"
        content.userInfo = [
            "alert_id": alertID.uuidString,
            "reminder_id": rule.id.uuidString
        ]
        
        var ruleToSend = rule
        ruleToSend.alertID = alertID
        
        let request = UNNotificationRequest(identifier: alertID.uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false))
        UNUserNotificationCenter.current().add(request)
        
        if rule.measurementType == .heartRate {
            self.alertTriggeredSubject.send(ruleToSend)
        }
    }
    
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

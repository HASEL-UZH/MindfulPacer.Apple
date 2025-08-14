//
//  HeartRateMonitoringService.swift
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
}

public struct HeartRateAlertRule: @unchecked Sendable {
    public let id: UUID
    var thresholdBPM: Double
    var duration: TimeInterval
    var alertMessage: String
    var triggerDate: Date? = nil
    var dipDate: Date? = nil
    var collectedData: [(value: Double, date: Date)] = []
    var type: Reminder.ReminderType
}

final class HeartRateMonitorService: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
    
    static let shared = HeartRateMonitorService()
    
    @Published var heartRate: Double = 0
    @Published var isSessionActive = false
    @Published var statusMessage: StatusMessage = .notConfigured
    @Published private(set) var activeRules: [HeartRateAlertRule] = []
    
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var alertRules: [HeartRateAlertRule] = []
    
    private var fetchRemindersUseCase: FetchRemindersUseCase?
    
    private var alertDataCache: [UUID: [(value: Double, date: Date)]] = [:]
    
    let alertTriggeredSubject = PassthroughSubject<HeartRateAlertRule, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        
        subscribeToCloudKitChanges()
    }
    
    private func subscribeToCloudKitChanges() {
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("DEBUGY: CloudKit data change detected. Refreshing state from new data.")
                self?.refreshState()
            }
            .store(in: &cancellables)
    }
    
    func configure(fetchRemindersUseCase: FetchRemindersUseCase) {
        self.fetchRemindersUseCase = fetchRemindersUseCase
        self.statusMessage = .configured
        self.registerNotificationCategories()
    }
    
    func data(for alertID: UUID) -> [(value: Double, date: Date)]? {
        return alertDataCache[alertID]
    }
    
    private func _startOrStopMonitoring(hasRules: Bool) {
        let sessionIsRunning = workoutSession?.state == .running
        
        print("DEBUGY: Checking monitoring state. Has Rules: \(hasRules), Session Is Running: \(sessionIsRunning)")
        
        if hasRules && !sessionIsRunning {
            print("DEBUGY: Condition met. Attempting to start workout session.")
            startWorkoutSession()
        } else if !hasRules && sessionIsRunning {
            print("DEBUGY: Condition met. Attempting to end workout session.")
            endWorkoutSession()
        } else {
            print("DEBUGY: No state change needed.")
        }
    }
    
    func startMonitoringIfNeeded() {
        updateMonitoringRules()
        if !alertRules.isEmpty && !isSessionActive {
            startWorkoutSession()
        } else if alertRules.isEmpty && isSessionActive {
            endWorkoutSession()
        }
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
    
    private func updateMonitoringRules() -> Bool {
        guard let useCase = fetchRemindersUseCase else {
            self.statusMessage = .notConfigured
            return false
        }
        let allReminders = useCase.execute() ?? []
        print("DEBUGY: Number of reminders fetched: \(allReminders.count)")
        let heartRateReminders = allReminders.filter { $0.measurementType == .heartRate }
        
        let newRules = heartRateReminders.map { reminder in
            HeartRateAlertRule(
                id: reminder.id,
                thresholdBPM: Double(reminder.threshold),
                duration: reminder.interval.timeInterval,
                alertMessage: reminder.triggerSummary,
                type: reminder.reminderType
            )
        }
        
        self.activeRules = newRules
        
        return !self.activeRules.isEmpty
    }
    
    private func startWorkoutSession() {
        guard workoutSession == nil else {
            print("DEBUGY: ERROR - Attempted to start a session, but a session object already exists.")
            return
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .walking
        configuration.locationType = .unknown
        
        do {
            print("DEBUGY: Creating new HKWorkoutSession object.")
            self.workoutSession = try HKWorkoutSession(healthStore: self.healthStore, configuration: configuration)
            self.workoutBuilder = self.workoutSession?.associatedWorkoutBuilder()
            self.workoutSession?.delegate = self
            self.workoutBuilder?.delegate = self
            self.workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: self.healthStore, workoutConfiguration: configuration)
            
            self.workoutSession?.startActivity(with: Date())
            self.workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("DEBUGY: ERROR - beginCollection failed with error: \(error.localizedDescription)")
                    DispatchQueue.main.async { self.statusMessage = .collectionFailed }
                    return
                }
                guard success else { return }
                DispatchQueue.main.async {
                    print("DEBUGY: Session started successfully. Updating UI.")
                    self.isSessionActive = true
                    self.statusMessage = .monitoring
                }
            }
        } catch {
            print("DEBUGY: ERROR - Failed to create HKWorkoutSession: \(error.localizedDescription)")
            DispatchQueue.main.async { self.statusMessage = .sessionFailed }
        }
    }
    
    private func endWorkoutSession() {
        workoutSession?.end()
        workoutSession = nil
        workoutBuilder = nil
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.heartRate = 0
            self.statusMessage = .stopped
        }
    }
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [HKObjectType.quantityType(forIdentifier: .heartRate)!]
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, _ in
            completion(success)
        }
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType, quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)
            let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
            if let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                DispatchQueue.main.async {
                    self.heartRate = value
                    self.evaluateRules(for: value)
                }
            }
        }
    }
    
    private func evaluateRules(for currentHeartRate: Double) {
        let dipGracePeriod: TimeInterval = 30.0
        
        for i in 0..<activeRules.count {
            var rule = activeRules[i]
            if currentHeartRate > rule.thresholdBPM {
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
    
    private func registerNotificationCategories() {
        let viewDetailsAction = UNNotificationAction(
            identifier: "VIEW_DETAILS_ACTION",
            title: "View Details",
            options: .foreground
        )
        
        let heartRateAlertCategory = UNNotificationCategory(
            identifier: "HEART_RATE_ALERT",
            actions: [viewDetailsAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([heartRateAlertCategory])
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
        
        let request = UNNotificationRequest(
            identifier: alertID.uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
        
        var safeRule = rule
        safeRule.collectedData = Array(rule.collectedData)
        
        DispatchQueue.main.async {
            self.alertTriggeredSubject.send(safeRule)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
}

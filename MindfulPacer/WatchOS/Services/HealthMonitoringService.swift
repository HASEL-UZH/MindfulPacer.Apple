//
//  HealthMonitoringService.swift
//  WatchOS
//

import Foundation
import HealthKit
import UserNotifications
import Combine
import SwiftUI
import CoreData
import WidgetKit

enum AppGroupPaths {
    static let groupID = "group.com.MindfulPacer"

    @discardableResult
    static func prepareApplicationSupport() -> URL? {
        guard let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
            print("AppGroup container not found")
            return nil
        }
        let appSupport = container
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            return appSupport
        } catch {
            print("Failed to create Application Support in group: \(error)")
            return nil
        }
    }
}

// MARK: - StatusMessage

enum StatusMessage: String {
    case monitoring = "Monitoring Active"
    case notMonitoring = "Not Monitoring"
    case noReminders = "No Reminders Set"
    case permissionDenied = "Permission Denied"
    case error = "An Error Occurred"
    case syncing = "Syncing..."
    case paused = "Monitoring Paused"

    var localized: String {
        switch self {
        case .monitoring:
            String(localized: "Monitoring Active")
        case .notMonitoring:
            String(localized: "Not Monitoring")
        case .noReminders:
            String(localized: "No Reminders Set")
        case .permissionDenied:
            String(localized: "Permission Denied")
        case .error:
            String(localized: "An Error Occurred")
        case .syncing:
            String(localized: "Syncing...")
        case .paused:
            String(localized: "Monitoring Paused")
        }
    }
    
    var symbolName: String {
        switch self {
        case .monitoring: return "checkmark"
        case .notMonitoring: return "xmark"
        case .noReminders: return "bell.slash"
        case .permissionDenied: return "lock.slash"
        case .error: return "exclamationmark.triangle"
        case .syncing: return "arrow.triangle.2.circlepath.circle"
        case .paused: return "pause"
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
        case .paused: return .yellow
        }
    }

    var description: String {
        switch self {
        case .monitoring:
            return String(localized: "The app is actively monitoring your health data based on your reminders.")
        case .notMonitoring:
            return String(localized: "Monitoring is currently inactive. This may be because no reminders are set or there was an issue.")
        case .noReminders:
            return String(localized: "Please add a reminder on your iPhone to begin monitoring.")
        case .permissionDenied:
            return String(localized: "Access to HealthKit was denied. Please grant permission in the Health app on your iPhone.")
        case .error:
            return String(localized: "An unexpected error occurred. Please try restarting the app.")
        case .syncing:
            return String(localized: "Syncing your latest reminders from iCloud...")
        case .paused:
            return String(localized: "Monitoring is temporarily paused. Tap the play button to resume.")
        }
    }
}

private let pendingNotificationsKey = "pendingNotificationsKey"

struct PendingNotification: Codable, Identifiable {
    var id: UUID { alertID }
    let alertID: UUID
    let reminderID: UUID
    let sentDate: Date
}

enum RuleType: Sendable, Equatable {
    case heartRate(threshold: Double)
    case steps(threshold: Double)
}

public struct AlertRule: Identifiable, Sendable, Equatable {
    public let id: UUID
    var alertID: UUID?
    let measurementType: Reminder.MeasurementType
    let reminderType: Reminder.ReminderType
    let ruleType: RuleType
    let duration: TimeInterval
    let alertMessage: String
    let interval: Reminder.Interval

    var triggerDate: Date? = nil
    var dipDate: Date? = nil
    var lastNotificationDate: Date? = nil
    var notificationSent: Bool = false
}

// MARK: - Service

@MainActor
final class HealthMonitorService: NSObject, ObservableObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
    
    private struct RuleRuntimeState: Sendable, Equatable {
        var triggerDate: Date? = nil
        var dipDate: Date? = nil
        var lastNotificationDate: Date? = nil
        var notificationSent: Bool = false
    }

    private var runtimeByRuleID: [UUID: RuleRuntimeState] = [:]
    
    @Published var heartRate: Double = 0
    @Published var isSessionActive = false
    @Published var statusMessage: StatusMessage = .notMonitoring
    @Published private(set) var recentHeartRateSamples: [(value: Double, date: Date)] = []
    @Published private(set) var activeRules: [AlertRule] = []
    @Published var isManuallyPaused: Bool = false
    @Published var isMonitoringEnabled: Bool = true
    
    let alertTriggeredSubject = PassthroughSubject<AlertRule, Never>()

    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    var isAppInForeground: Bool = true

    private var fetchRemindersUseCase: FetchRemindersUseCase?
    private var cancellables = Set<AnyCancellable>()
    private var stepsTimer: DispatchSourceTimer?
    private var complicationHeartbeat: DispatchSourceTimer?

    override init() {
        super.init()
        _ = AppGroupPaths.prepareApplicationSupport()
        subscribeToCloudKitChanges()
    }

    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.MindfulPacer")
    }

    // MARK: - CloudKit change handling (debounced)

    private func subscribeToCloudKitChanges() {
        NotificationCenter.default.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshState()
            }
            .store(in: &cancellables)
    }
    
    func configure(fetchRemindersUseCase: FetchRemindersUseCase) {
        self.fetchRemindersUseCase = fetchRemindersUseCase
    }
    
    // MARK: - State refresh
    
    func refreshState() {
        let hadRules = !activeRules.isEmpty
        let hasRules = rebuildRulesPreservingState()
        
        if isManuallyPaused {
            statusMessage = .paused
        } else if isSessionActive {
            statusMessage = hasRules ? .monitoring : .monitoring
        } else {
            statusMessage = isMonitoringEnabled ? .notMonitoring : .notMonitoring
        }
        
        _startOrStopMonitoring(hasRules: hasRules, previouslyHadRules: hadRules)
    }
    
    private func rebuildRulesPreservingState() -> Bool {
        guard let useCase = fetchRemindersUseCase else { return false }
        let reminders = useCase.execute() ?? []

        var next: [AlertRule] = []
        next.reserveCapacity(reminders.count)

        for rem in reminders {
            let newRuleType: RuleType = (rem.measurementType == .heartRate)
                ? .heartRate(threshold: Double(rem.threshold))
                : .steps(threshold: Double(rem.threshold))

            let newRule = AlertRule(
                id: rem.id,
                alertID: nil,
                measurementType: rem.measurementType,
                reminderType: rem.reminderType,
                ruleType: newRuleType,
                duration: rem.interval.timeInterval,
                alertMessage: rem.triggerSummary,
                interval: rem.interval
            )

            next.append(newRule)

            // Ensure runtime entry exists (don’t publish anything)
            if runtimeByRuleID[rem.id] == nil {
                runtimeByRuleID[rem.id] = RuleRuntimeState()
            }
        }

        // Drop runtime for removed rules
        let validIDs = Set(next.map(\.id))
        runtimeByRuleID = runtimeByRuleID.filter { validIDs.contains($0.key) }

        // Only publish if config truly changed
        if next != activeRules {
            activeRules = next
        }

        return !next.isEmpty
    }
    
    private func rulesConfigEqual(lhs: AlertRule, rhs: AlertRule) -> Bool {
        guard lhs.id == rhs.id,
              lhs.measurementType == rhs.measurementType,
              lhs.reminderType == rhs.reminderType,
              lhs.interval == rhs.interval,
              lhs.duration == rhs.duration,
              lhs.alertMessage == rhs.alertMessage else {
            return false
        }
        switch (lhs.ruleType, rhs.ruleType) {
        case (.heartRate(let a), .heartRate(let b)): return a == b
        case (.steps(let a), .steps(let b)): return a == b
        default: return false
        }
    }

    // MARK: - Start/Stop monitoring

    private func _startOrStopMonitoring(hasRules: Bool, previouslyHadRules: Bool) {
        if isManuallyPaused {
            /// paused means user explicitly stopped live collection
            return
        }

        guard isMonitoringEnabled else {
            /// This is your “shutdown” equivalent: user turned monitoring off
            if workoutSession != nil { endWorkoutSession() }
            return
        }

        /// Monitoring enabled => ensure workout session is running (even if no reminders)
        let sessionIsRunning = (workoutSession?.state == .running)
        if !sessionIsRunning {
            startWorkoutSession()
        }

        /// Rules presence only affects rule evaluation + status text, not the workout session
    }

    private func startWorkoutSession() {
        guard workoutSession == nil else { return }

        Task {
            do {
                let isAuthorized = try await requestAuthorization()
                guard isAuthorized else {
                    statusMessage = .permissionDenied
                    return
                }

                let configuration = HKWorkoutConfiguration()
                configuration.activityType = .mindAndBody
                configuration.locationType = .unknown

                let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                let builder = session.associatedWorkoutBuilder()
                session.delegate = self
                builder.delegate = self
                builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

                self.workoutSession = session
                self.workoutBuilder = builder

                session.startActivity(with: Date())
                try await builder.beginCollection(at: Date())
                isSessionActive = true
                startComplicationHeartbeat()
                statusMessage = .monitoring
                startStepsTimer()

                writeComplicationState(.active)
                WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
            } catch {
                statusMessage = .error
            }
        }
    }

    private func endWorkoutSession() {
        stopStepsTimer()
        workoutSession?.end()
        workoutBuilder?.discardWorkout()
        workoutSession = nil
        workoutBuilder = nil
        isSessionActive = false
        heartRate = 0
        isManuallyPaused = false
        statusMessage = .notMonitoring

        stopComplicationHeartbeat()
        writeComplicationState(.inactive)
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
    }

    // MARK: - HealthKit

    func requestAuthorization() async throws -> Bool {
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]

        return try await withCheckedThrowingContinuation { cont in
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error { cont.resume(throwing: error); return }
                cont.resume(returning: success)
            }
        }
    }

    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue else { continue }
            let stats = workoutBuilder.statistics(for: quantityType)
            let unit = HKUnit.count().unitDivided(by: .minute())
            if let value = stats?.mostRecentQuantity()?.doubleValue(for: unit) {
                Task { @MainActor in
                    self.processHeartRate(value)
                }
            }
        }
    }
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {}
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {}
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}

    // MARK: - Steps timer

    private func startStepsTimer() {
        stepsTimer?.cancel()
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now() + 300, repeating: 300)
        t.setEventHandler { [weak self] in
            guard let self else { return }
            self.checkStepRules()
        }
        stepsTimer = t
        t.resume()
    }

    private func stopStepsTimer() {
        stepsTimer?.cancel()
        stepsTimer = nil
    }

    // MARK: - Fetch helpers

    func fetchTodaysSteps() async -> Double {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startDate = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )
        do {
            let result = try await descriptor.result(for: healthStore)
            guard let sum = result?.sumQuantity() else { return 0 }
            return sum.doubleValue(for: .count())
        } catch {
            return 0
        }
    }

    func fetchHourlyStepData() async -> [(date: Date, steps: Double)] {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let now = Date()
        let startDate = now.addingTimeInterval(-3600)
        let anchorDate = Calendar.current.startOfDay(for: now)
        let interval = DateComponents(minute: 5)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)

        let qd = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: anchorDate,
            intervalComponents: interval
        )

        do {
            let collection = try await qd.result(for: healthStore)
            var cumulative: [(date: Date, steps: Double)] = []
            var total = 0.0
            collection.enumerateStatistics(from: startDate, to: now) { stats, _ in
                if let sum = stats.sumQuantity() {
                    total += sum.doubleValue(for: .count())
                    cumulative.append((stats.endDate, total))
                }
            }
            return cumulative
        } catch {
            return []
        }
    }

    // MARK: - Heart rate processing

    private func processHeartRate(_ newHeartRate: Double) {
        heartRate = newHeartRate
        let now = Date()
        recentHeartRateSamples.append((value: newHeartRate, date: now))
        let oneHourAgo = now.addingTimeInterval(-3600)
        recentHeartRateSamples.removeAll { $0.date < oneHourAgo }
        evaluateHeartRateRules(for: newHeartRate)
    }

    private func evaluateHeartRateRules(for currentHeartRate: Double) {
        guard !isManuallyPaused else { return }

        let now = Date()
        let dipGrace: TimeInterval = 30.0

        for rule in activeRules {
            guard rule.measurementType == .heartRate else { continue }
            guard case .heartRate(let threshold) = rule.ruleType else { continue }

            var state = runtimeByRuleID[rule.id] ?? RuleRuntimeState()
            let original = state

            if currentHeartRate > threshold {
                if state.triggerDate == nil { state.triggerDate = now }
                if state.dipDate != nil { state.dipDate = nil }

                if let started = state.triggerDate {
                    let elapsed = now.timeIntervalSince(started)
                    if elapsed >= rule.duration {
                        let buffer = BufferManager.shared.buffer(for: rule.interval, context: .heartRate)
                        if let last = state.lastNotificationDate, now.timeIntervalSince(last) < buffer {
                            // suppressed
                        } else {
                            let dataWindowStart = started.addingTimeInterval(-(rule.duration * 0.20))
                            let eventData = recentHeartRateSamples.filter { $0.date >= dataWindowStart }
                            sendNotification(for: rule, withData: eventData)

                            state.lastNotificationDate = now
                            state.triggerDate = nil
                        }
                    }
                }
            } else {
                if state.triggerDate != nil {
                    if state.dipDate == nil { state.dipDate = now }
                    if let dipStart = state.dipDate, now.timeIntervalSince(dipStart) > dipGrace {
                        state.triggerDate = nil
                        state.dipDate = nil
                    }
                }
            }

            if state != original {
                runtimeByRuleID[rule.id] = state
            }
        }
    }

    // MARK: - Steps rules

    private func checkStepRules() {
        guard !isManuallyPaused else { return }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let stepRules = activeRules.filter { $0.measurementType == .steps }
        guard !stepRules.isEmpty else { return }

        let now = Date()

        for rule in stepRules {
            guard case .steps(let threshold) = rule.ruleType else { continue }

            let endDate = now
            let startDate = endDate.addingTimeInterval(-rule.duration)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                guard let self else { return }
                guard error == nil, let sum = result?.sumQuantity() else { return }
                let total = sum.doubleValue(for: .count())

                if total > threshold {
                    Task { @MainActor in
                        guard let idx = self.activeRules.firstIndex(where: { $0.id == rule.id }) else { return }
                        let r = self.activeRules[idx]

                        var state = self.runtimeByRuleID[r.id] ?? RuleRuntimeState()

                        let buffer = BufferManager.shared.buffer(for: r.interval, context: .steps)
                        if let last = state.lastNotificationDate, now.timeIntervalSince(last) < buffer { return }

                        let series = await self.buildStepSeries(for: r, windowEnd: now)

                        self.sendNotification(for: r, stepsSeries: series)

                        state.notificationSent = true
                        state.lastNotificationDate = now
                        self.runtimeByRuleID[r.id] = state
                    }
                } else {
                    Task { @MainActor in
                        guard let idx = self.activeRules.firstIndex(where: { $0.id == rule.id }) else { return }
                        let r = self.activeRules[idx]
                        var state = self.runtimeByRuleID[r.id] ?? RuleRuntimeState()
                        if state.notificationSent {
                            state.notificationSent = false
                            self.runtimeByRuleID[r.id] = state
                        }
                    }
                }
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Notifications

    private func sendNotification(
        for rule: AlertRule,
        stepsSeries: [MeasurementSample]? = nil,
        withData heartRateData: [(value: Double, date: Date)] = []
    ) {
        let alertID = UUID()

        var samples: [MeasurementSample] = []
        switch rule.measurementType {
        case .heartRate:
            samples = heartRateData.map { MeasurementSample(type: .heartRate, value: $0.value, date: $0.date) }
        case .steps:
            // Use the per-minute series if provided; otherwise fall back to a single point
            if let stepsSeries, !stepsSeries.isEmpty {
                samples = stepsSeries
            } else {
                // fallback: single timestamp sample; not ideal but preserves behavior
                samples = [MeasurementSample(type: .steps, value: 0, date: Date())]
            }
        }

        Services.shared.systemDelegate.cacheTriggerData(samples, for: alertID)

        if isAppInForeground {
            var r = rule
            r.alertID = alertID
            alertTriggeredSubject.send(r)
        } else {
            let content = UNMutableNotificationContent()
            content.title = rule.measurementType == .heartRate ? "Heart Rate Alert" : "Steps Alert"
            content.body = rule.alertMessage
            content.sound = .defaultCritical
            content.categoryIdentifier = "HEART_RATE_ALERT"
            content.userInfo = [
                "alert_id": alertID.uuidString,
                "reminder_id": rule.id.uuidString
            ]
            let req = UNNotificationRequest(
                identifier: alertID.uuidString,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            )
            UNUserNotificationCenter.current().add(req)
        }
    }

    private func logPendingNotification(alertID: UUID, reminderID: UUID) {
        let userDefaults = UserDefaults.standard
        let newPending = PendingNotification(alertID: alertID, reminderID: reminderID, sentDate: Date())
        do {
            var all = getPendingNotifications()
            all.append(newPending)
            let data = try JSONEncoder().encode(all)
            userDefaults.set(data, forKey: pendingNotificationsKey)
        } catch {
            // ignore
        }
    }

    private func getPendingNotifications() -> [PendingNotification] {
        let userDefaults = UserDefaults.standard
        guard let data = userDefaults.data(forKey: pendingNotificationsKey),
              let pending = try? JSONDecoder().decode([PendingNotification].self, from: data) else {
            return []
        }
        return pending
    }
    
    func pauseMonitoring() {
        guard isSessionActive, !isManuallyPaused else { return }
        workoutSession?.pause()
        isManuallyPaused = true
        statusMessage = .paused

        stopComplicationHeartbeat()
        writeComplicationState(.paused)
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
    }

    func resumeMonitoring() {
        guard isSessionActive, isManuallyPaused else { return }
        workoutSession?.resume()
        isManuallyPaused = false
        statusMessage = .monitoring

        writeComplicationState(.active)
        startComplicationHeartbeat()
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
    }
    
    private func fetchStepBuckets(
        from start: Date,
        to end: Date,
        bucket: DateComponents = DateComponents(minute: 1)
    ) async -> [(date: Date, steps: Double)] {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let anchorDate = Calendar.current.startOfDay(for: end)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        if #available(watchOS 10.0, *) {
            let qd = HKStatisticsCollectionQueryDescriptor(
                predicate: .quantitySample(type: stepType, predicate: predicate),
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: bucket
            )
            do {
                let collection = try await qd.result(for: healthStore)
                var out: [(Date, Double)] = []
                collection.enumerateStatistics(from: start, to: end) { stats, _ in
                    if let sum = stats.sumQuantity() {
                        let count = sum.doubleValue(for: .count())
                        if count > 0 { out.append((stats.endDate, count)) }
                    }
                }
                return out
            } catch {
                return []
            }
        } else {
            return await withCheckedContinuation { cont in
                let query = HKStatisticsCollectionQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: [.cumulativeSum],
                    anchorDate: anchorDate,
                    intervalComponents: bucket
                )
                query.initialResultsHandler = { _, collection, _ in
                    guard let collection else { cont.resume(returning: []); return }
                    var out: [(Date, Double)] = []
                    collection.enumerateStatistics(from: start, to: end) { stats, _ in
                        if let sum = stats.sumQuantity() {
                            let count = sum.doubleValue(for: .count())
                            if count > 0 { out.append((stats.endDate, count)) }
                        }
                    }
                    cont.resume(returning: out)
                }
                self.healthStore.execute(query)
            }
        }
    }
    
    private func buildStepSeries(for rule: AlertRule, windowEnd: Date) async -> [MeasurementSample] {
        let windowStart = windowEnd.addingTimeInterval(-rule.duration)

        // For .oneDay rules, still send per-bucket raw samples
        let start = (rule.interval == .oneDay)
            ? Calendar.current.startOfDay(for: windowEnd)
            : windowStart

        let buckets = await fetchStepBuckets(from: start, to: windowEnd, bucket: DateComponents(minute: 1))
        // Map to MeasurementSample (raw bucket values)
        return buckets.map { MeasurementSample(type: .steps, value: $0.steps, date: $0.date) }
    }
    
    private func writeComplicationState(_ state: ComplicationState) {
        let defaults = UserDefaults(suiteName: AppGroupPaths.groupID)
        defaults?.set(state.rawValue, forKey: ComplicationKeys.state)
        defaults?.set(Date().timeIntervalSince1970, forKey: ComplicationKeys.lastUpdated)
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
    }
    
    private func startComplicationHeartbeat() {
        complicationHeartbeat?.cancel()

        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: 60) // every 60 s
        t.setEventHandler { [weak self] in
            guard let self else { return }
            guard self.isSessionActive, !self.isManuallyPaused else { return }
            self.writeComplicationState(.active)
        }

        complicationHeartbeat = t
        t.resume()
    }

    private func stopComplicationHeartbeat() {
        complicationHeartbeat?.cancel()
        complicationHeartbeat = nil
    }
}

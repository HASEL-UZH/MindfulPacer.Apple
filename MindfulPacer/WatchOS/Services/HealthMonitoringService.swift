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
import SwiftData
import WidgetKit

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

/// What the monitoring button in Controls does for the current state.
/// There is always an action, so the button can never be a dead end.
enum MonitoringControlAction: Equatable {
    case pause
    case resume
    /// Monitoring is neither running nor paused, e.g. after the system ended the workout.
    case restart

    init(isSessionActive: Bool, isManuallyPaused: Bool) {
        if isManuallyPaused {
            self = .resume
        } else if isSessionActive {
            self = .pause
        } else {
            self = .restart
        }
    }

    var startsMonitoring: Bool { self != .pause }
}

extension AlertRule {
    init(reminder: Reminder) {
        let threshold = Double(reminder.threshold)
        self.init(
            id: reminder.id,
            alertID: nil,
            measurementType: reminder.measurementType,
            reminderType: reminder.reminderType,
            ruleType: reminder.measurementType == .heartRate ? .heartRate(threshold: threshold) : .steps(threshold: threshold),
            duration: reminder.interval.timeInterval,
            alertMessage: reminder.triggerSummary,
            interval: reminder.interval
        )
    }

    /// Rules for the reminders currently in the store: heart rate first, then by descending threshold.
    /// Rules are value snapshots, so nothing keeps a reference to a reminder that is deleted later.
    @MainActor
    static func currentRules(in context: ModelContext) throws -> [AlertRule] {
        try context.fetch(FetchDescriptor<Reminder>())
            .sorted { lhs, rhs in
                guard lhs.measurementType == rhs.measurementType else {
                    if lhs.measurementType == .heartRate { return true }
                    if rhs.measurementType == .heartRate { return false }
                    return lhs.measurementType.rawValue < rhs.measurementType.rawValue
                }
                return lhs.threshold > rhs.threshold
            }
            .map(AlertRule.init(reminder:))
    }

    var highlightRule: ReminderHighlightState.Rule {
        let threshold: Double
        switch ruleType {
        case .heartRate(let value), .steps(let value): threshold = value
        }
        return .init(id: id, measurement: measurementType, severity: reminderType,
                     threshold: threshold, interval: interval)
    }
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

    private enum MonitoringIntent: Int {
        case active = 0
        case paused = 1
        case stopped = 2
    }

    private var runtimeByRuleID: [UUID: RuleRuntimeState] = [:]
    
    @Published private(set) var widgetHighlights = ReminderHighlightState()
    private var highlightExpirationTimer: Timer?

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
    private var isStartingWorkoutSession = false
    private var isEndingWorkoutSession = false
    private var isCheckingRecoveredWorkoutSession = false
    private var lastAutomaticRestart: Date?
    /// Counts start attempts, so an attempt whose session already ended cannot change newer state.
    private var workoutStartAttempt = 0
    private var monitoringIntent: MonitoringIntent = .active

    var isAppInForeground: Bool = true

    private lazy var modelContext: ModelContext = ModelContainer.prod.mainContext
    private var reminderSyncTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var stepsTimer: DispatchSourceTimer?
    private var complicationHeartbeat: DispatchSourceTimer?
    private let monitoringIntentKey = "com.mindfulpacer.watch.monitoringIntent"

    override init() {
        super.init()
        #if DEBUG && targetEnvironment(simulator)
        // Capture fixtures must not react to CloudKit events by starting a workout.
        if WatchDesignPreview.isEnabled { return }
        #endif
        _ = AppGroupPaths.prepareApplicationSupport()
        monitoringIntent = loadMonitoringIntent()
        isManuallyPaused = (monitoringIntent == .paused)
        isMonitoringEnabled = (monitoringIntent != .stopped)
        subscribeToCloudKitChanges()
    }

    private var sharedUserDefaults: UserDefaults? {
        UserDefaults(suiteName: "group.com.MindfulPacer")
    }

    private func loadMonitoringIntent() -> MonitoringIntent {
        guard let rawValue = sharedUserDefaults?.object(forKey: monitoringIntentKey) as? Int,
              let intent = MonitoringIntent(rawValue: rawValue) else {
            return .active
        }
        return intent
    }

    private func setMonitoringIntent(_ intent: MonitoringIntent) {
        monitoringIntent = intent
        if intent != .active { clearWidgetHighlights() }
        sharedUserDefaults?.set(intent.rawValue, forKey: monitoringIntentKey)
        isMonitoringEnabled = (intent != .stopped)
        isManuallyPaused = (intent == .paused)
    }

    // MARK: - CloudKit change handling (debounced)

    private func subscribeToCloudKitChanges() {
        let center = NotificationCenter.default
        center.publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .merge(with: center.publisher(for: .NSPersistentStoreRemoteChange))
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshState()
            }
            .store(in: &cancellables)
    }

    /// The iPhone announces a reminder change before iCloud has delivered it to the Watch.
    /// Re-read the store a few times, so the change appears even when no store notification
    /// arrives and the status cannot stay on "Syncing...".
    func remindersChangedOnPhone() {
        statusMessage = .syncing
        reminderSyncTask?.cancel()
        reminderSyncTask = Task { [weak self] in
            for delay in [2, 5, 15] {
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }
                self?.refreshState()
            }
        }
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
        // Read the store on every refresh, so reminders created, edited or deleted on the iPhone
        // take effect without relaunching the app. A failed read keeps the current rules.
        guard let next = try? AlertRule.currentRules(in: modelContext) else {
            return !activeRules.isEmpty
        }

        var runtime: [UUID: RuleRuntimeState] = [:]
        for rule in next {
            let isUnchanged = activeRules.contains { rulesConfigEqual(lhs: $0, rhs: rule) }
            // An edited reminder starts fresh, so progress towards the old threshold cannot trigger the new one.
            runtime[rule.id] = isUnchanged ? (runtimeByRuleID[rule.id] ?? RuleRuntimeState()) : RuleRuntimeState()
        }
        runtimeByRuleID = runtime

        if next != activeRules {
            activeRules = next
            widgetHighlights.retainRules(next.map(\.highlightRule))
            refreshWidgetHighlights()
            Task { await refreshStepHighlights() }
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
        if monitoringIntent == .paused || isManuallyPaused {
            statusMessage = .paused
            if workoutSession != nil {
                endWorkoutSession(
                    statusAfterEnd: .paused,
                    shouldClearManualPause: false,
                    complicationStateAfterEnd: .paused
                )
            }
            return
        }

        guard isMonitoringEnabled, monitoringIntent == .active else {
            /// User turned monitoring off
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
        discardEndedWorkoutSessionIfNeeded()
        guard workoutSession == nil else { return }
        guard !isStartingWorkoutSession, !isEndingWorkoutSession, !isCheckingRecoveredWorkoutSession else { return }
        guard monitoringIntent == .active, !isManuallyPaused else { return }

        isStartingWorkoutSession = true
        workoutStartAttempt += 1
        let attempt = workoutStartAttempt

        Task {
            var pendingSession: HKWorkoutSession?
            var pendingBuilder: HKLiveWorkoutBuilder?

            do {
                let isAuthorized = try await requestAuthorization()
                guard attempt == workoutStartAttempt else { return }
                guard isAuthorized else {
                    isStartingWorkoutSession = false
                    statusMessage = .permissionDenied
                    return
                }
                guard monitoringIntent == .active, !isManuallyPaused else {
                    isStartingWorkoutSession = false
                    return
                }

                let configuration = HKWorkoutConfiguration()
                configuration.activityType = .mindAndBody
                configuration.locationType = .unknown

                let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                let builder = session.associatedWorkoutBuilder()
                pendingSession = session
                pendingBuilder = builder
                session.delegate = self
                builder.delegate = self
                builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

                self.workoutSession = session
                self.workoutBuilder = builder

                session.startActivity(with: Date())
                try await builder.beginCollection(at: Date())
                // The session ended or failed while it was starting and was already cleaned up.
                guard attempt == workoutStartAttempt else { return }
                guard monitoringIntent == .active, !isManuallyPaused else {
                    isStartingWorkoutSession = false
                    discardAndEndUnsavedWorkoutSession(session: session, builder: builder)
                    if self.workoutSession === session {
                        self.workoutSession = nil
                    }
                    if self.workoutBuilder === builder {
                        self.workoutBuilder = nil
                    }
                    return
                }
                isStartingWorkoutSession = false
                isSessionActive = true
                startComplicationHeartbeat()
                statusMessage = .monitoring
                startStepsTimer()

                writeComplicationState(.active)
                WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
                await refreshStepHighlights()
            } catch {
                guard attempt == workoutStartAttempt else { return }
                if pendingSession != nil || pendingBuilder != nil {
                    discardAndEndUnsavedWorkoutSession(session: pendingSession, builder: pendingBuilder)
                    if self.workoutSession === pendingSession {
                        self.workoutSession = nil
                    }
                    if self.workoutBuilder === pendingBuilder {
                        self.workoutBuilder = nil
                    }
                }
                isStartingWorkoutSession = false
                statusMessage = .error
            }
        }
    }

    private func endWorkoutSession(
        statusAfterEnd: StatusMessage = .notMonitoring,
        shouldClearManualPause: Bool = true,
        complicationStateAfterEnd: ComplicationState = .inactive
    ) {
        guard !isEndingWorkoutSession else { return }

        let session = workoutSession
        let builder = workoutBuilder
        isEndingWorkoutSession = true
        stopStepsTimer()
        stopComplicationHeartbeat()
        isSessionActive = false
        clearWidgetHighlights()
        heartRate = 0
        if shouldClearManualPause {
            isManuallyPaused = false
        }
        statusMessage = statusAfterEnd
        writeComplicationState(complicationStateAfterEnd)
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")

        discardAndEndUnsavedWorkoutSession(session: session, builder: builder)
        if self.workoutSession === session {
            self.workoutSession = nil
        }
        if self.workoutBuilder === builder {
            self.workoutBuilder = nil
        }
        self.isEndingWorkoutSession = false
        if self.monitoringIntent == .active, !self.isManuallyPaused {
            self.startWorkoutSession()
        }
    }

    private func discardAndEndUnsavedWorkoutSession(session: HKWorkoutSession?, builder: HKLiveWorkoutBuilder?) {
        let endDate = Date()

        if let builder {
            // MP uses workouts only for live monitoring/background execution; do not save workout records.
            builder.dataSource = nil
            builder.discardWorkout()
            builder.delegate = nil
        }

        guard let session, session.state != .ended else { return }

        switch session.state {
        case .running, .paused:
            session.stopActivity(with: endDate)
            session.end()
        case .stopped:
            session.end()
        case .notStarted, .prepared:
            session.end()
        @unknown default:
            session.stopActivity(with: endDate)
            session.end()
        }

        session.delegate = nil
    }

    // MARK: - Sessions ended outside the app

    /// The system can end or fail a workout the app did not stop itself, for example while the Watch charges.
    /// Keeping that dead session makes `startWorkoutSession()` return early forever, which left monitoring
    /// stuck in "Not Monitoring" until the app was relaunched.
    private func handleSessionEndedOutsideApp(sessionID: ObjectIdentifier) {
        guard let session = workoutSession, ObjectIdentifier(session) == sessionID else { return }
        guard !isEndingWorkoutSession else { return }

        if isStartingWorkoutSession {
            // This session was still starting. Invalidate that attempt so it cannot mark monitoring active.
            workoutStartAttempt += 1
            isStartingWorkoutSession = false
        }

        let builder = workoutBuilder
        stopStepsTimer()
        stopComplicationHeartbeat()
        isSessionActive = false
        clearWidgetHighlights()
        heartRate = 0
        discardAndEndUnsavedWorkoutSession(session: session, builder: builder)
        workoutSession = nil
        workoutBuilder = nil

        guard monitoringIntent == .active, !isManuallyPaused else {
            if monitoringIntent == .paused {
                statusMessage = .paused
                writeComplicationState(.paused)
            }
            return
        }

        statusMessage = .notMonitoring
        writeComplicationState(.inactive)
        restartAfterUnexpectedEnd()
    }

    /// At most one automatic attempt per minute, so a workout the system keeps ending cannot cause a restart loop.
    /// If the attempt is not possible right now, the next app activation or the Controls button starts it.
    private func restartAfterUnexpectedEnd() {
        let now = Date()
        if let last = lastAutomaticRestart, now.timeIntervalSince(last) < 60 { return }
        lastAutomaticRestart = now
        startWorkoutSession()
    }

    /// A session that already ended can never run again; holding on to it would block every later start.
    private func discardEndedWorkoutSessionIfNeeded() {
        guard !isStartingWorkoutSession, !isEndingWorkoutSession,
              let session = workoutSession,
              session.state == .ended || session.state == .stopped else { return }

        discardAndEndUnsavedWorkoutSession(session: session, builder: workoutBuilder)
        workoutSession = nil
        workoutBuilder = nil
        isSessionActive = false
    }

    /// Starts monitoring again when it is neither running nor paused. Called from Controls and on app activation.
    func restartMonitoring() {
        guard !isSessionActive else { return }
        setMonitoringIntent(.active)
        lastAutomaticRestart = nil
        refreshState()
    }

    private func endRecoveredWorkoutSession(_ session: HKWorkoutSession) {
        let builder = session.associatedWorkoutBuilder()
        session.delegate = self
        builder.delegate = self
        builder.dataSource = nil

        Task {
            discardAndEndUnsavedWorkoutSession(session: session, builder: builder)
            if self.workoutSession === session {
                self.workoutSession = nil
            }
            if self.workoutBuilder === builder {
                self.workoutBuilder = nil
            }
            self.isSessionActive = false
            self.clearWidgetHighlights()
            self.heartRate = 0
            self.statusMessage = .paused
            self.isCheckingRecoveredWorkoutSession = false
            self.stopStepsTimer()
            self.stopComplicationHeartbeat()
            self.writeComplicationState(.paused)
            WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")
        }
    }

    func handleActiveWorkoutRecovery() {
        recoverActiveWorkoutSessionForTeardown(pauseImmediately: true)
    }

    func checkForRecoveredWorkoutSessionOnLaunch() {
        recoverActiveWorkoutSessionForTeardown(pauseImmediately: false)
    }

    private func recoverActiveWorkoutSessionForTeardown(pauseImmediately: Bool) {
        guard !isCheckingRecoveredWorkoutSession else { return }
        isCheckingRecoveredWorkoutSession = true

        if pauseImmediately {
            stopCurrentWorkoutForRecovery()
        }

        healthStore.recoverActiveWorkoutSession { [weak self] session, _ in
            Task { @MainActor in
                guard let self else { return }

                guard let session else {
                    self.isCheckingRecoveredWorkoutSession = false
                    self.refreshState()
                    return
                }

                self.setMonitoringIntent(.paused)
                self.stopCurrentWorkoutForRecovery()
                self.endRecoveredWorkoutSession(session)
            }
        }
    }

    private func stopCurrentWorkoutForRecovery() {
        setMonitoringIntent(.paused)
        statusMessage = .paused
        stopStepsTimer()
        stopComplicationHeartbeat()
        writeComplicationState(.paused)
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")

        if workoutSession != nil {
            endWorkoutSession(
                statusAfterEnd: .paused,
                shouldClearManualPause: false,
                complicationStateAfterEnd: .paused
            )
        }
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
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        let sessionID = ObjectIdentifier(workoutSession)
        Task { @MainActor in
            // Only update complication if the state change wasn't triggered by user (manual pause/resume)
            // This handles system-triggered pauses (wrist down, app backgrounded, etc.)
            switch toState {
            case .running:
                if !self.isManuallyPaused {
                    self.writeComplicationState(.active)
                    self.startComplicationHeartbeat()
                }
            case .paused:
                if !self.isManuallyPaused {
                    self.writeComplicationState(.paused)
                    self.stopComplicationHeartbeat()
                }
            case .stopped, .ended:
                // A session that was already replaced must not change the state of its successor.
                guard let current = self.workoutSession, ObjectIdentifier(current) == sessionID else { return }
                self.isSessionActive = false
                self.writeComplicationState(self.monitoringIntent == .paused ? .paused : .inactive)
                self.stopComplicationHeartbeat()
                self.handleSessionEndedOutsideApp(sessionID: sessionID)
            default:
                break
            }
        }
    }
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        let sessionID = ObjectIdentifier(workoutSession)
        Task { @MainActor in
            self.handleSessionEndedOutsideApp(sessionID: sessionID)
        }
    }
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
        // Use empty options [] to include step samples that may span across midnight
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: [])
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
        guard isSessionActive, !isManuallyPaused else { return }
        widgetHighlights.updateHeartRate(newHeartRate)
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

        Task { await refreshStepHighlights() }

        let now = Date()
        let calendar = Calendar.current

        let dayStepsMutedToday = StepDayMuteStore.isMutedToday(now: now, calendar: calendar)

        for rule in stepRules {
            guard case .steps(let threshold) = rule.ruleType else { continue }

            if rule.interval == .oneDay, dayStepsMutedToday {
                continue
            }

            let endDate = now
            let startDate: Date
            
            // For 1-day intervals, we MUST use calendar day (midnight to now), not rolling 24 hours
            // Check both the interval enum AND duration to be defensive against any data inconsistencies
            let isOneDayInterval = (rule.interval == .oneDay) || (rule.duration == 86400)
            
            if isOneDayInterval {
                startDate = calendar.startOfDay(for: now)
            } else {
                startDate = endDate.addingTimeInterval(-rule.duration)
            }

            // For 1-day intervals, we need to capture all steps from midnight onwards.
            // Using empty options [] ensures we include samples that may span across midnight
            // (e.g., a sample from 11:58 PM yesterday to 12:02 AM today).
            // For other intervals, .strictStartDate is appropriate.
            let options: HKQueryOptions = isOneDayInterval ? [] : .strictStartDate
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: options)

            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { [weak self] _, result, error in
                guard let self else { return }
                guard error == nil, let sum = result?.sumQuantity() else { return }
                let total = sum.doubleValue(for: .count())

                if total > threshold {
                    Task { @MainActor in
                        guard let idx = self.activeRules.firstIndex(where: { $0.id == rule.id }) else { return }
                        let r = self.activeRules[idx]
                        var state = self.runtimeByRuleID[r.id] ?? RuleRuntimeState()

                        if r.interval == .oneDay {
                            if let last = state.lastNotificationDate, calendar.isDate(last, inSameDayAs: now) {
                                return
                            }
                            if StepDayMuteStore.isMutedToday(now: now, calendar: calendar) {
                                return
                            }
                        } else {
                            let buffer = BufferManager.shared.buffer(for: r.interval, context: .steps)
                            if let last = state.lastNotificationDate, now.timeIntervalSince(last) < buffer { return }
                        }

                        let series = await self.buildStepSeries(for: r, windowEnd: now)
                        // A query can finish after monitoring stops or the reminder changes.
                        guard self.isSessionActive, !self.isManuallyPaused,
                              self.activeRules.contains(where: { self.rulesConfigEqual(lhs: $0, rhs: r) }) else { return }
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

    // MARK: - Widget highlights

    func refreshWidgetHighlights() {
        var highlights = widgetHighlights
        highlights.expireSteps(at: Date())
        if highlights != widgetHighlights { widgetHighlights = highlights }
        highlightExpirationTimer?.invalidate()
        highlightExpirationTimer = nil
        guard let expiration = widgetHighlights.nextExpiration else { return }
        let timer = Timer(fire: expiration, interval: 0, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshWidgetHighlights()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        highlightExpirationTimer = timer
    }

    /// Step highlights follow the step count, not the notifications: a passed threshold shows even when
    /// its notification was sent earlier, is muted for the day or is held back by the cooldown.
    func refreshStepHighlights() async {
        guard isSessionActive, !isManuallyPaused else { return }

        let now = Date()
        var totals: [(rule: AlertRule, total: Double)] = []
        for rule in activeRules where rule.measurementType == .steps {
            guard let total = await stepTotal(for: rule, at: now) else { continue }
            totals.append((rule, total))
        }

        // Monitoring or the reminders can change while the counts are read.
        guard isSessionActive, !isManuallyPaused else { return }
        var highlights = widgetHighlights
        for (rule, total) in totals where activeRules.contains(where: { rulesConfigEqual(lhs: $0, rhs: rule) }) {
            highlights.updateSteps(total, for: rule.highlightRule, at: now)
        }
        if highlights != widgetHighlights { widgetHighlights = highlights }
        refreshWidgetHighlights()
    }

    /// Steps counted in a reminder's interval, using the same windows as `checkStepRules()`:
    /// since midnight for one-day reminders, otherwise the last interval. `nil` when the count is unknown.
    private func stepTotal(for rule: AlertRule, at now: Date) async -> Double? {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let isOneDayInterval = (rule.interval == .oneDay) || (rule.duration == 86400)
        let start = isOneDayInterval ? Calendar.current.startOfDay(for: now) : now.addingTimeInterval(-rule.duration)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: now,
            options: isOneDayInterval ? [] : .strictStartDate
        )
        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum
        )
        do {
            let result = try await descriptor.result(for: healthStore)
            return result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
        } catch let error as HKError where error.code == .errorNoData {
            return 0
        } catch {
            return nil
        }
    }

    private func clearWidgetHighlights() {
        highlightExpirationTimer?.invalidate()
        highlightExpirationTimer = nil
        widgetHighlights = ReminderHighlightState()
    }

    // MARK: - Notifications

    private func sendNotification(
        for rule: AlertRule,
        stepsSeries: [MeasurementSample]? = nil,
        withData heartRateData: [(value: Double, date: Date)] = []
    ) {
        widgetHighlights.recordTrigger(for: rule.highlightRule, at: Date())
        refreshWidgetHighlights()
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
        guard !isManuallyPaused else { return }
        setMonitoringIntent(.paused)
        statusMessage = .paused

        stopComplicationHeartbeat()
        writeComplicationState(.paused)
        WidgetCenter.shared.reloadTimelines(ofKind: "MindfulPacerStatus")

        if workoutSession != nil {
            endWorkoutSession(
                statusAfterEnd: .paused,
                shouldClearManualPause: false,
                complicationStateAfterEnd: .paused
            )
        }
    }

    func resumeMonitoring() {
        guard isManuallyPaused else { return }
        setMonitoringIntent(.active)
        statusMessage = .monitoring

        writeComplicationState(.active)
        startWorkoutSession()
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

        // For 1-day intervals, MUST use calendar day (midnight to now), not rolling 24 hours
        // Check both the interval enum AND duration to be defensive
        let isOneDayInterval = (rule.interval == .oneDay) || (rule.duration == 86400)
        let start = isOneDayInterval
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
    
    // MARK: - App Launch State Verification
    
    /// Verifies that the complication state matches actual monitoring state on app launch.
    /// This fixes stale state issues when the app was force-closed.
    func verifyComplicationStateOnLaunch() {
        let defaults = UserDefaults(suiteName: AppGroupPaths.groupID)
        let savedStateRaw = defaults?.integer(forKey: ComplicationKeys.state) ?? ComplicationState.inactive.rawValue
        let savedState = ComplicationState(rawValue: savedStateRaw) ?? .inactive
        
        if savedState == .active {
            if workoutSession == nil || workoutSession?.state != .running {
                writeComplicationState(.inactive)
            } else if !isManuallyPaused {
                startComplicationHeartbeat()
            }
        }
    }
}

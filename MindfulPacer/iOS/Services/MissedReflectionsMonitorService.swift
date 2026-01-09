//
//  MissedReflectionsMonitorService.swift
//  iOS
//
//  Created by Grigor Dochev on 19.10.2025.
//

import Foundation
import BackgroundTasks
import UserNotifications
import SwiftUI
import os

enum MissedReflectionsDisplayPolicy {
    static func apply(_ refs: [Reflection]) -> [Reflection] {
        Array(refs.filter { $0.triggerSamples.count > 1 }.prefix(100))
    }

    static func countForUIAndBG(_ refs: [Reflection]) -> Int {
        apply(refs).count
    }
}

// MARK: - BGDebug

enum DefaultsStore {
    static var shared: UserDefaults {
        UserDefaults(suiteName: "group.com.MindfulPacer") ?? .standard
    }
}

enum BGDebug {
    static let log = Logger(subsystem: "com.MindfulPacer", category: "BackgroundTasks")
    
    enum Keys {
        static let lastSchedule       = "BGDebug.lastSchedule"
        static let lastRunStart       = "BGDebug.lastRunStart"
        static let lastRunEnd         = "BGDebug.lastRunEnd"
        static let lastResult         = "BGDebug.lastResult"
        static let lastError          = "BGDebug.lastError"
        static let runsCount          = "BGDebug.runsCount"
        static let lastFound          = "BGDebug.lastFoundCount"
        static let lastRunCount       = "BGDebug.lastRunCount"
        
        // Notification throttle state
        static let lastNotifyDateISO  = "BGDebug.lastNotifyDateISO"
        static let lastNotifyCount    = "BGDebug.lastNotifyCount"
        
        // High-level decision state (for “why/when did we show?”)
        static let lastNotifyDecision = "BGDebug.lastNotifyDecision"
        static let lastNotifyReason   = "BGDebug.lastNotifyReason"
        
        // History of runs
        static let history            = "BGDebug.history"
    }
    
    /// One entry in the background-task history.
    struct HistoryEntry: Codable, Identifiable {
        let id: UUID
        let createdAt: Date
        
        let lastSchedule: String?
        let lastRunStart: String?
        let lastRunEnd: String?
        let lastResult: String?
        let lastError: String?
        let runsCount: Int
        let lastFound: Int
        
        let lastNotifyDateISO: String?
        let lastNotifyCount: Int?
        let lastNotifyDecision: String?
        let lastNotifyReason: String?
    }
    
    private static let historyMaxEntries = 100
    
    @MainActor @discardableResult
    static func set(_ key: String, value: Any?) -> Any? {
        DefaultsStore.shared.set(value, forKey: key)
        return value
    }
    
    @MainActor
    static func touch(_ key: String) {
        set(key, value: ISO8601DateFormatter().string(from: Date()))
    }
    
    @MainActor
    static func increment(_ key: String) {
        let n = DefaultsStore.shared.integer(forKey: key)
        DefaultsStore.shared.set(n + 1, forKey: key)
    }

    /// Store a human-readable decision + reason about notifications/background behavior.
    @MainActor
    static func setDecision(_ decision: String, reason: String? = nil) {
        set(Keys.lastNotifyDecision, value: decision)
        set(Keys.lastNotifyReason, value: reason)
        
        if let reason {
            log.info("BG 🧠 decision=\(decision, privacy: .public), reason=\(reason, privacy: .public)")
        } else {
            log.info("BG 🧠 decision=\(decision, privacy: .public)")
        }
    }
    
    /// Load the full stored history (oldest → newest).
    nonisolated static func loadHistory() -> [HistoryEntry] {
        let d = DefaultsStore.shared
        guard let data = d.data(forKey: Keys.history) else {
            return []
        }
        return (try? JSONDecoder().decode([HistoryEntry].self, from: data)) ?? []
    }
    
    /// Append a snapshot of the current BGDebug state as a new history entry.
    @MainActor
    static func appendHistorySnapshot() {
        let d = DefaultsStore.shared
        
        let entry = HistoryEntry(
            id: UUID(),
            createdAt: Date(),
            lastSchedule: d.string(forKey: Keys.lastSchedule),
            lastRunStart: d.string(forKey: Keys.lastRunStart),
            lastRunEnd: d.string(forKey: Keys.lastRunEnd),
            lastResult: d.string(forKey: Keys.lastResult),
            lastError: d.string(forKey: Keys.lastError),
            runsCount: d.integer(forKey: Keys.runsCount),
            lastFound: d.integer(forKey: Keys.lastFound),
            lastNotifyDateISO: d.string(forKey: Keys.lastNotifyDateISO),
            lastNotifyCount: d.object(forKey: Keys.lastNotifyCount) as? Int,
            lastNotifyDecision: d.string(forKey: Keys.lastNotifyDecision),
            lastNotifyReason: d.string(forKey: Keys.lastNotifyReason)
        )
        
        var history = loadHistory()
        history.append(entry)
        
        // Keep only the last N entries
        if history.count > historyMaxEntries {
            history = Array(history.suffix(historyMaxEntries))
        }
        
        if let data = try? JSONEncoder().encode(history) {
            d.set(data, forKey: Keys.history)
        }
        
        log.info("BG 🧾 appended history entry (total=\(history.count, privacy: .public))")
    }
    
    @MainActor
    static func dumpState(prefix: String = "BGDebug") {
        let d = DefaultsStore.shared
        log.info("""
        \(prefix, privacy: .public) ▶︎ \
        lastSchedule=\(d.string(forKey: Keys.lastSchedule) ?? "nil", privacy: .public), \
        lastRunStart=\(d.string(forKey: Keys.lastRunStart) ?? "nil", privacy: .public), \
        lastRunEnd=\(d.string(forKey: Keys.lastRunEnd) ?? "nil", privacy: .public), \
        lastResult=\(d.string(forKey: Keys.lastResult) ?? "nil", privacy: .public), \
        lastError=\(d.string(forKey: Keys.lastError) ?? "nil", privacy: .public), \
        runsCount=\(d.integer(forKey: Keys.runsCount), privacy: .public), \
        lastFound=\(d.integer(forKey: Keys.lastFound), privacy: .public), \
        lastNotifyDecision=\(d.string(forKey: Keys.lastNotifyDecision) ?? "nil", privacy: .public), \
        lastNotifyReason=\(d.string(forKey: Keys.lastNotifyReason) ?? "nil", privacy: .public)
        """)
    }
}

// MARK: - MissedReflectionsMonitorService

actor MissedReflectionsMonitorService {
    static let shared = MissedReflectionsMonitorService()
    nonisolated static let identifier = "com.MindfulPacer.Apple.iOS.checkMissedReflections"

    // ✅ Desired cadence
    private let desiredRunInterval: TimeInterval = 2 * 60 * 60
    private let notificationThrottleInterval: TimeInterval = 2 * 60 * 60

    private func isiPhoneOnly() -> Bool {
        DeviceMode.current(from: DefaultsStore.shared) == .iPhoneOnly
    }

    func onDeviceModeChanged(_ newMode: DeviceMode) {
        if newMode == .iPhoneOnly {
            scheduleNextRun(in: 30) // schedule soon after mode switch (still self-throttled)
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.identifier)
            Task { @MainActor in
                BGDebug.log.info("BG ▶︎ cancelled pending app refresh (mode=Watch).")
                BGDebug.setDecision("no_run", reason: "mode_changed_to_watch")
            }
        }
    }

    // MARK: - Scheduling

    func scheduleNextRun(in seconds: TimeInterval = 2 * 60 * 60) {
        guard isiPhoneOnly() else {
            Task { @MainActor in
                BGDebug.log.info("BG ⏭ not scheduling (mode != iPhoneOnly)")
                BGDebug.setDecision("no_schedule", reason: "mode_not_iPhoneOnly")
            }
            return
        }

        // ✅ cancel existing to avoid piling up
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.identifier)

        let req = BGAppRefreshTaskRequest(identifier: Self.identifier)
        req.earliestBeginDate = Date(timeIntervalSinceNow: seconds)

        do {
            try BGTaskScheduler.shared.submit(req)
            Task { @MainActor in
                BGDebug.touch(BGDebug.Keys.lastSchedule)
                BGDebug.log.info("BG ▶︎ scheduled app refresh (~\(Int(seconds))s)")
            }
        } catch {
            Task { @MainActor in
                BGDebug.set(BGDebug.Keys.lastError, value: "schedule error: \(error.localizedDescription)")
                BGDebug.log.error("BG ✖︎ schedule failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Self throttle (don’t run more often than desiredRunInterval)

    private func shouldRunNow() -> (ok: Bool, wait: TimeInterval, reason: String?) {
        let d = DefaultsStore.shared
        guard
            let lastEndISO = d.string(forKey: BGDebug.Keys.lastRunEnd),
            let lastEnd = ISO8601DateFormatter().date(from: lastEndISO)
        else {
            return (true, desiredRunInterval, nil)
        }

        let dt = Date().timeIntervalSince(lastEnd)
        if dt < desiredRunInterval {
            return (false, desiredRunInterval - dt, "self_throttle_dt=\(Int(dt))s")
        }

        return (true, desiredRunInterval, nil)
    }

    // MARK: - Notify gate (count changed vs previous run + notification throttle)

    private func shouldNotify(count: Int, previousCount: Int?) -> (Bool, String) {
        guard count > 0 else { return (false, "count_zero") }

        if let previousCount, previousCount == count {
            return (false, "same_as_previous_run:\(count)")
        }

        // Throttle notifications (extra safety)
        let d = DefaultsStore.shared
        if let lastISO = d.string(forKey: BGDebug.Keys.lastNotifyDateISO),
           let lastDate = ISO8601DateFormatter().date(from: lastISO) {
            let dt = Date().timeIntervalSince(lastDate)
            if dt < notificationThrottleInterval {
                return (false, "notify_throttled_dt=\(Int(dt))s")
            }
        }

        if previousCount == nil {
            return (true, "no_previous_count_baseline")
        }

        return (true, "count_changed_prev=\(previousCount!)_now=\(count)")
    }

    private func recordNotificationState(count: Int) {
        let d = DefaultsStore.shared
        let iso = ISO8601DateFormatter().string(from: Date())
        d.set(iso, forKey: BGDebug.Keys.lastNotifyDateISO)
        d.set(count, forKey: BGDebug.Keys.lastNotifyCount)

        Task { @MainActor in
            BGDebug.log.info("BG 💾 updated notify state: count=\(count, privacy: .public), date=\(iso, privacy: .public)")
        }
    }

    // MARK: - BG entry point

    func handleTask() async {
        // mode gate
        guard isiPhoneOnly() else {
            await MainActor.run {
                BGDebug.log.info("BG ⏭ skipped (mode != iPhoneOnly)")
                BGDebug.touch(BGDebug.Keys.lastRunStart)
                BGDebug.touch(BGDebug.Keys.lastRunEnd)
                BGDebug.set(BGDebug.Keys.lastResult, value: "skipped_due_to_mode")
                BGDebug.setDecision("no_run", reason: "mode_not_iPhoneOnly")
                BGDebug.appendHistorySnapshot()
            }
            return
        }

        // ✅ self-throttle gate
        let gate = shouldRunNow()
        if !gate.ok {
            await MainActor.run {
                BGDebug.setDecision("no_run", reason: gate.reason ?? "self_throttle")
                BGDebug.touch(BGDebug.Keys.lastRunStart)
                BGDebug.touch(BGDebug.Keys.lastRunEnd)
                BGDebug.set(BGDebug.Keys.lastResult, value: "skipped_self_throttle")
                BGDebug.appendHistorySnapshot()
            }
            scheduleNextRun(in: gate.wait)
            return
        }

        await MainActor.run {
            BGDebug.touch(BGDebug.Keys.lastRunStart)
            BGDebug.set(BGDebug.Keys.lastResult, value: "running")
            BGDebug.log.info("BG ▶︎ handleAppRefresh START")
        }

        do {
            // ✅ load reminders + reflection snapshots from App Group defaults
            let cachedReminders = await MainActor.run { BackgroundRemindersStore.shared.load() }
            let existingSnapshots = await MainActor.run { BackgroundReflectionsStore.shared.load() }

            let count = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Int, Error>) in
                Task { @MainActor in
                    let useCase = UseCasesContainer.shared.fetchMissedReflectionsUseCase()
                    useCase.execute(
                        reminderConfigs: cachedReminders,
                        existingReflectionSnapshots: existingSnapshots
                    ) { result in
                        switch result {
                        case .success(let refs): cont.resume(returning: refs.count)
                        case .failure(let e):    cont.resume(throwing: e)
                        }
                    }
                }
            }

            // previous count baseline
            let d = DefaultsStore.shared
            let prev = d.object(forKey: BGDebug.Keys.lastRunCount) as? Int

            await MainActor.run {
                BGDebug.increment(BGDebug.Keys.runsCount)
                BGDebug.set(BGDebug.Keys.lastFound, value: count)
                BGDebug.set(BGDebug.Keys.lastRunCount, value: count)
                BGDebug.log.info("BG ✔︎ missed reflections count=\(count, privacy: .public) (prev=\(prev ?? -1, privacy: .public))")
            }

            let notifyDecision = shouldNotify(count: count, previousCount: prev)
            if notifyDecision.0 {
                await postMissedReflectionsNotification(count: count)
                recordNotificationState(count: count)
                await MainActor.run {
                    BGDebug.setDecision("notification_sent", reason: notifyDecision.1)
                }
            } else {
                await MainActor.run {
                    BGDebug.setDecision("no_notification", reason: notifyDecision.1)
                }
            }

            await MainActor.run {
                BGDebug.touch(BGDebug.Keys.lastRunEnd)
                BGDebug.set(BGDebug.Keys.lastResult, value: "success(\(count))")
                BGDebug.dumpState(prefix: "BG COMPLETE")
                BGDebug.appendHistorySnapshot()
            }

        } catch {
            await MainActor.run {
                BGDebug.touch(BGDebug.Keys.lastRunEnd)
                BGDebug.set(BGDebug.Keys.lastError, value: "execute error: \(error.localizedDescription)")
                BGDebug.set(BGDebug.Keys.lastResult, value: "failure")
                BGDebug.setDecision("failure", reason: "execute_error:\(error.localizedDescription)")
                BGDebug.log.error("BG ✖︎ execute failed: \(error.localizedDescription, privacy: .public)")
                BGDebug.appendHistorySnapshot()
            }
        }

        // ✅ reschedule at the very end (2h)
        scheduleNextRun(in: desiredRunInterval)
    }

    private func postMissedReflectionsNotification(count: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "You Have Missed Reflections"
        content.body  = "You have \(count) new missed reflection(s) waiting for you."
        content.sound = .default
        #if DEBUG
        content.subtitle = "(\(ISO8601DateFormatter().string(from: Date())))"
        #endif

        do {
            try await UNUserNotificationCenter.current().add(
                UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            )
            await MainActor.run {
                BGDebug.log.info("BG 🔔 posted local notification for count=\(count, privacy: .public)")
            }
        } catch {
            await MainActor.run {
                BGDebug.set(BGDebug.Keys.lastError, value: "notify error: \(error.localizedDescription)")
                BGDebug.setDecision("notification_failed", reason: error.localizedDescription)
                BGDebug.log.error("BG ✖︎ failed to post notification: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

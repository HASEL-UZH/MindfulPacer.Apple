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

        // Notification throttle state
        static let lastNotifyDateISO  = "BGDebug.lastNotifyDateISO"
        static let lastNotifyCount    = "BGDebug.lastNotifyCount"
    }
    
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
    
    @MainActor
    static func dumpState(prefix: String = "BGDebug") {
        let d = DefaultsStore.shared
        log.info("\(prefix, privacy: .public) ▶︎ lastSchedule=\(d.string(forKey: Keys.lastSchedule) ?? "nil", privacy: .public), lastRunStart=\(d.string(forKey: Keys.lastRunStart) ?? "nil", privacy: .public), lastRunEnd=\(d.string(forKey: Keys.lastRunEnd) ?? "nil", privacy: .public), lastResult=\(d.string(forKey: Keys.lastResult) ?? "nil", privacy: .public), lastError=\(d.string(forKey: Keys.lastError) ?? "nil", privacy: .public), runsCount=\(d.integer(forKey: Keys.runsCount), privacy: .public), lastFound=\(d.integer(forKey: Keys.lastFound), privacy: .public)")
    }
}

// MARK: - MissedReflectionsMonitorService

actor MissedReflectionsMonitorService {
    static let shared = MissedReflectionsMonitorService()
    nonisolated static let identifier = "com.MindfulPacer.Apple.iOS.checkMissedReflections"

    // 2-hour throttle for notifications
    private let throttleInterval: TimeInterval = 2 * 60 * 60

    // MARK: Mode check
    private func isiPhoneOnly() -> Bool {
        DeviceMode.current(from: DefaultsStore.shared) == .iPhoneOnly
    }

    func onDeviceModeChanged(_ newMode: DeviceMode) {
        if newMode == .iPhoneOnly {
            schedule(in: 5 * 60) // (re)schedule soon
        } else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.identifier)
            Task { @MainActor in
                BGDebug.log.info("BG ▶︎ cancelled pending app refresh (mode=Watch).")
            }
        }
    }

    // MARK: - Notification throttling

    /// Returns true if we're allowed to show a notification for this `count`
    /// based on: (a) >= 2h since last notification AND (b) count changed.
    private func shouldNotify(for count: Int) -> Bool {
        let d = DefaultsStore.shared

        // (b) Count must have changed since last notification
        let lastCount = d.object(forKey: BGDebug.Keys.lastNotifyCount) as? Int
        if let lastCount, lastCount == count {
            Task { @MainActor in
                BGDebug.log.info("BG 🔕 skip notify: same missed count (\(count, privacy: .public))")
            }
            return false
        }

        // (a) Respect the 2h throttle
        if let lastDateISO = d.string(forKey: BGDebug.Keys.lastNotifyDateISO),
           let lastDate = ISO8601DateFormatter().date(from: lastDateISO) {
            let dt = Date().timeIntervalSince(lastDate)
            if dt < throttleInterval {
                Task { @MainActor in
                    BGDebug.log.info("BG 🔕 skip notify: last notification \(Int(dt))s ago (< \(Int(self.throttleInterval))s)")
                }
                return false
            }
        }

        return true
    }

    /// Store latest notification metadata after we actually fire it.
    private func recordNotificationState(count: Int) {
        let d = DefaultsStore.shared
        let iso = ISO8601DateFormatter().string(from: Date())
        d.set(iso, forKey: BGDebug.Keys.lastNotifyDateISO)
        d.set(count, forKey: BGDebug.Keys.lastNotifyCount)

        Task { @MainActor in
            BGDebug.log.info("BG 💾 updated notify state: count=\(count, privacy: .public), date=\(iso, privacy: .public)")
        }
    }

    // MARK: Entry point from BGTask handler
    func handleTask() async {
        // Bail fast if not iPhone-only
        guard isiPhoneOnly() else {
            await MainActor.run {
                BGDebug.log.info("BG ⏭ skipped (mode != iPhoneOnly)")
                BGDebug.touch(BGDebug.Keys.lastRunStart)
                BGDebug.touch(BGDebug.Keys.lastRunEnd)
                BGDebug.set(BGDebug.Keys.lastResult, value: "skipped_due_to_mode")
            }
            // Do NOT reschedule—let App/Settings change drive that.
            return
        }

        // Normal flow
        schedule(in: 5 * 60)

        await MainActor.run {
            BGDebug.touch(BGDebug.Keys.lastRunStart)
            BGDebug.log.info("BG ▶︎ handleAppRefresh START")
        }

        do {
            let cachedReminders = await MainActor.run { BackgroundRemindersStore.shared.load() }
            let count = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Int, Error>) in
                Task { @MainActor in
                    let useCase = UseCasesContainer.shared.fetchMissedReflectionsUseCase()
                    useCase.execute(reminderConfigs: cachedReminders, existingReflections: []) { result in
                        switch result {
                        case .success(let refs): cont.resume(returning: refs.count)
                        case .failure(let e):    cont.resume(throwing: e)
                        }
                    }
                }
            }

            await MainActor.run {
                BGDebug.increment(BGDebug.Keys.runsCount)
                BGDebug.set(BGDebug.Keys.lastFound, value: count)
                BGDebug.log.info("BG ✔︎ missed reflections count=\(count, privacy: .public)")
            }

            // Throttle before sending notification
            if count > 0, shouldNotify(for: count) {
                await postMissedReflectionsNotification(count: count)
                recordNotificationState(count: count)
            } else {
                await MainActor.run {
                    BGDebug.log.info("BG 🔕 no notification (count=\(count, privacy: .public))")
                }
            }

            await MainActor.run {
                BGDebug.touch(BGDebug.Keys.lastRunEnd)
                BGDebug.set(BGDebug.Keys.lastResult, value: "success(\(count))")
                BGDebug.dumpState(prefix: "BG COMPLETE")
            }
        } catch {
            await MainActor.run {
                BGDebug.touch(BGDebug.Keys.lastRunEnd)
                BGDebug.set(BGDebug.Keys.lastError, value: "execute error: \(error.localizedDescription)")
                BGDebug.set(BGDebug.Keys.lastResult, value: "failure")
                BGDebug.log.error("BG ✖︎ execute failed: \(error.localizedDescription, privacy: .public)")
                BGDebug.dumpState(prefix: "BG COMPLETE (failure)")
            }
        }
    }

    func schedule(in seconds: TimeInterval) {
        // Gate scheduling too
        guard isiPhoneOnly() else {
            Task { @MainActor in
                BGDebug.log.info("BG ⏭ not scheduling (mode != iPhoneOnly)")
            }
            return
        }

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
    
    private func postMissedReflectionsNotification(count: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "You Have Missed Reflections"
        content.body  = "You have \(count) new missed reflection(s) waiting for you."
        content.sound = .default
        #if DEBUG
        content.subtitle = "(\(ISO8601DateFormatter().string(from: Date())))"
        #endif

        _ = try? await UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        )

        await MainActor.run {
            BGDebug.log.info("BG 🔔 posted local notification for count=\(count, privacy: .public)")
        }
    }
}

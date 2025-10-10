//
//  MissedReflectionsMonitorService.swift
//  iOS
//
//  Created by Grigor Dochev on 07.09.2025.
//

import Foundation
import BackgroundTasks
import UserNotifications
import SwiftUI
import os

// MARK: - BGDebug (shared user defaults + logging)

@MainActor
private enum DefaultsStore {
    static var shared: UserDefaults {
        // App group first, fall back to standard (e.g. unit tests)
        UserDefaults(suiteName: "group.com.MindfulPacer") ?? .standard
    }
}

enum BGDebug {
    static let log = Logger(subsystem: "com.MindfulPacer", category: "BackgroundTasks")

    enum Keys {
        static let lastSchedule = "BGDebug.lastSchedule"
        static let lastRunStart = "BGDebug.lastRunStart"
        static let lastRunEnd   = "BGDebug.lastRunEnd"
        static let lastResult   = "BGDebug.lastResult"
        static let lastError    = "BGDebug.lastError"
        static let runsCount    = "BGDebug.runsCount"
        static let lastFound    = "BGDebug.lastFoundCount"
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

@MainActor
final class MissedReflectionsMonitorService {
    
    static let shared = MissedReflectionsMonitorService()
    
    private let taskIdentifier = "com.MindfulPacer.Apple.iOS.checkMissedReflections"
    
    private init() {}
    
    // MARK: - Public
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            BGDebug.touch(BGDebug.Keys.lastSchedule)
            BGDebug.log.info("BG ▶︎ scheduled app refresh (earliestBeginDate ~5m).")
        } catch {
            BGDebug.set(BGDebug.Keys.lastError, value: "schedule error: \(error.localizedDescription)")
            BGDebug.log.error("BG ✖︎ schedule failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refresh = task as? BGAppRefreshTask else {
                BGDebug.log.error("BG ✖︎ received non-refresh task.")
                task.setTaskCompleted(success: false)
                return
            }
            BGDebug.log.info("BG ▶︎ received app refresh task callback.")
            DispatchQueue.main.async {
                self.handleAppRefreshOnMain(task: refresh)
            }
        }
        BGDebug.log.info("BG ▶︎ registerBackgroundTask completed for \(self.taskIdentifier, privacy: .public)")
    }
    
    /// Debug helper to introspect pending BG requests and dump our last-known state
    func dumpPendingTasks(reason: String) {
        if #available(iOS 17.0, *) {
            BGTaskScheduler.shared.getPendingTaskRequests { requests in
                let list = requests
                    .map { req in
                        if let r = req as? BGAppRefreshTaskRequest {
                            return "\(r.identifier) @ \(String(describing: r.earliestBeginDate))"
                        } else {
                            return req.identifier
                        }
                    }
                    .joined(separator: " | ")
                BGDebug.log.info("BG [\(reason, privacy: .public)] pending: \(list, privacy: .public)")
            }
        } else {
            BGDebug.log.info("BG [\(reason, privacy: .public)] pending requests not available on this iOS.")
        }
        BGDebug.dumpState(prefix: "BG STATE \(reason)")
    }
    
    // MARK: - Private (MainActor)
    
    @MainActor
    private func handleAppRefreshOnMain(task: BGAppRefreshTask) {
        // Chain next run early to keep the pipeline alive
        scheduleAppRefresh()
        
        BGDebug.touch(BGDebug.Keys.lastRunStart)
        BGDebug.log.info("BG ▶︎ handleAppRefreshOnMain START")
        
        var didComplete = false
        func complete(_ success: Bool, result: String) {
            guard !didComplete else { return }
            didComplete = true
            BGDebug.touch(BGDebug.Keys.lastRunEnd)
            BGDebug.set(BGDebug.Keys.lastResult, value: result)
            task.setTaskCompleted(success: success)
            BGDebug.dumpState(prefix: "BG COMPLETE")
            #if DEBUG
            let content = UNMutableNotificationContent()
            content.title = "BG Task \(success ? "Success" : "Failed")"
            content.body  = "Result=\(result)"
            UNUserNotificationCenter.current()
                .add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
            #endif
        }
        
        task.expirationHandler = { [weak self] in
            DispatchQueue.main.async {
                BGDebug.log.error("BG ⚠︎ Task expired by system.")
                BGDebug.set(BGDebug.Keys.lastError, value: "expired")
                self?.dumpPendingTasks(reason: "expired")
                complete(false, result: "expired")
            }
        }
        
        let fetchMissedReflectionsUseCase = UseCasesContainer.shared.fetchMissedReflectionsUseCase()
        let cachedReminders = BackgroundRemindersStore.shared.load()
        
        fetchMissedReflectionsUseCase.execute(
            reminderConfigs: cachedReminders,
            existingReflections: []
        ) { result in
            switch result {
            case .success(let refs):
                let count = refs.count
                BGDebug.increment(BGDebug.Keys.runsCount)
                BGDebug.set(BGDebug.Keys.lastFound, value: count)
                BGDebug.log.info("BG ✔︎ Fetched missed reflections. count=\(count, privacy: .public)")
                if count > 0 {
                    self.postMissedReflectionsNotification(count: count)
                }
                complete(true, result: "success(\(count))")
            case .failure(let error):
                BGDebug.set(BGDebug.Keys.lastError, value: "execute error: \(error.localizedDescription)")
                BGDebug.log.error("BG ✖︎ execute failed: \(error.localizedDescription, privacy: .public)")
                complete(false, result: "failure")
            }
        }
    }
    
    func postMissedReflectionsNotification(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "You Have Missed Reflections"
        content.body  = "You have \(count) new missed reflection(s) waiting for you."
        content.sound = .default
        #if DEBUG
        content.subtitle = "(\(ISO8601DateFormatter().string(from: Date())))"
        #endif
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        BGDebug.log.info("BG 🔔 posted local notification for count=\(count, privacy: .public)")
    }
}

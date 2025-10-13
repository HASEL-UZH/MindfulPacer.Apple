//
//  MissedReflectionsMonitorService.swift
//  iOS
//
//  iOS 17+ : driven via SwiftUI `.backgroundTask(.appRefresh(...))`
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

// MARK: - Service

actor MissedReflectionsMonitorService {
    
    static let shared = MissedReflectionsMonitorService()
    nonisolated static let identifier = "com.MindfulPacer.Apple.iOS.checkMissedReflections"
    
    func handleTask() async {
        schedule(in: 5 * 60)
        
        await MainActor.run {
            BGDebug.touch(BGDebug.Keys.lastRunStart)
            BGDebug.log.info("BG ▶︎ handleAppRefresh START")
        }
        
        do {
            let cachedReminders = await MainActor.run {
                BackgroundRemindersStore.shared.load()
            }
            
            let count = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Int, Error>) in
                Task { @MainActor in
                    let useCase = UseCasesContainer.shared.fetchMissedReflectionsUseCase()
                    useCase.execute(reminderConfigs: cachedReminders, existingReflections: []) { result in
                        switch result {
                        case .success(let refs):
                            cont.resume(returning: refs.count)
                        case .failure(let error):
                            cont.resume(throwing: error)
                        }
                    }
                }
            }
            
            await MainActor.run {
                BGDebug.increment(BGDebug.Keys.runsCount)
                BGDebug.set(BGDebug.Keys.lastFound, value: count)
                BGDebug.log.info("BG ✔︎ Fetched missed reflections. count=\(count, privacy: .public)")
            }
            
            if count > 0 {
                await postMissedReflectionsNotification(count: count)
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
        let req = BGAppRefreshTaskRequest(identifier: Self.identifier)
        req.earliestBeginDate = Date(timeIntervalSinceNow: seconds)
        do {
            try BGTaskScheduler.shared.submit(req)
            Task { @MainActor in
                BGDebug.touch(BGDebug.Keys.lastSchedule)
                BGDebug.log.info("BG ▶︎ scheduled app refresh (earliestBeginDate ~\(Int(seconds))s).")
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

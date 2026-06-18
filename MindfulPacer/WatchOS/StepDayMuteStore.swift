//
//  StepDayMuteStore.swift
//  WatchOS
//
//  Created by Grigor Dochev on 17.02.2026.
//

import Foundation

// MARK: - Step Day Mute Store

/// Stores and checks a one-day mute for step reminders via UserDefaults.
///
/// Changed: Added an optional `store` parameter to `muteForToday` and `isMutedToday`
/// so callers can inject a custom `UserDefaults` instance (defaults to the shared app-group suite).
/// This makes both functions testable without relying on the real app-group container.
enum StepDayMuteStore {
    private static let key = "com.mindfulpacer.mute.steps.oneday.lastResponse"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupPaths.groupID)
    }

    static func muteForToday(now: Date = Date(), store: UserDefaults? = nil) {
        (store ?? defaults)?.set(now.timeIntervalSince1970, forKey: key)
    }

    static func isMutedToday(now: Date = Date(), calendar: Calendar = .current, store: UserDefaults? = nil) -> Bool {
        guard let ts = (store ?? defaults)?.object(forKey: key) as? TimeInterval else { return false }
        return calendar.isDate(Date(timeIntervalSince1970: ts), inSameDayAs: now)
    }
}

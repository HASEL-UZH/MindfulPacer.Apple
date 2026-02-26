//
//  StepDayMuteStore.swift
//  WatchOS
//
//  Created by Grigor Dochev on 17.02.2026.
//

import Foundation

// MARK: - Step Day Mute Store

enum StepDayMuteStore {
    private static let key = "com.mindfulpacer.mute.steps.oneday.lastResponse"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppGroupPaths.groupID)
    }

    static func muteForToday(now: Date = Date()) {
        defaults?.set(now.timeIntervalSince1970, forKey: key)
    }

    static func isMutedToday(now: Date = Date(), calendar: Calendar = .current) -> Bool {
        guard let ts = defaults?.object(forKey: key) as? TimeInterval else { return false }
        return calendar.isDate(Date(timeIntervalSince1970: ts), inSameDayAs: now)
    }
}

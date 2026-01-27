//
//  BufferManager.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 24.08.2025.
//

import Foundation

// MARK: - BufferManager

final class BufferManager: @unchecked Sendable {
    static let shared = BufferManager()

    private init() {}

    private let appGroupID = "group.com.MindfulPacer"

    private var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    func buffer(for interval: Reminder.Interval, context: IntervalContext) -> TimeInterval {
        let type: Reminder.MeasurementType = (context == .heartRate) ? .heartRate : .steps
        let key = StorageKeys.bufferKey(for: interval, type: type)

        if defaults.object(forKey: key) != nil {
            return defaults.double(forKey: key)
        }

        return defaultBuffer(for: interval, context: context)
    }

    func defaultBuffer(for interval: Reminder.Interval, context: IntervalContext) -> TimeInterval {
        switch context {
        case .heartRate:
            switch interval {
            case .oneMinute:      return 15 * 60
            case .fiveMinutes:    return 15 * 60
            case .tenMinutes:     return 15 * 60
            case .fifteenMinutes: return 15 * 60
            case .thirtyMinutes:  return 15 * 60
            case .oneHour:        return 60 * 60
            default:              return 0
            }

        case .steps:
            switch interval {
            case .thirtyMinutes:  return 30 * 60
            case .oneHour:        return 60 * 60
            case .twoHours:       return 2 * 60 * 60
            case .fourHours:      return 4 * 60 * 60
            case .oneDay:         return 4 * 60 * 60
            default:              return 0
            }
        }
    }

    func allowedRange(for interval: Reminder.Interval, context: IntervalContext) -> ClosedRange<TimeInterval> {
        let base = defaultBuffer(for: interval, context: context)
        return 0...(base * 2.0)
    }

    func setOverride(_ value: TimeInterval, for interval: Reminder.Interval, context: IntervalContext) {
        let type: Reminder.MeasurementType = (context == .heartRate) ? .heartRate : .steps
        let key = StorageKeys.bufferKey(for: interval, type: type)
        defaults.set(Double(value), forKey: key)
        defaults.synchronize()
    }

    func clearOverride(for interval: Reminder.Interval, context: IntervalContext) {
        let type: Reminder.MeasurementType = (context == .heartRate) ? .heartRate : .steps
        let key = StorageKeys.bufferKey(for: interval, type: type)
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }
}

//
//  BufferManager.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 24.08.2025.
//

import Foundation

class BufferManager {
    @MainActor static let shared = BufferManager()
    
    private var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: "group.com.MindfulPacer")
    }
    
    func buffer(for interval: Reminder.Interval, context: IntervalContext) -> TimeInterval {
        let type: Reminder.MeasurementType = (context == .heartRate) ? .heartRate : .steps
        let key = StorageKeys.bufferKey(for: interval, type: type)
        
        if let userValue = sharedUserDefaults?.object(forKey: key) as? TimeInterval {
            print("DEBUGY WATCH: Found custom buffer of \(userValue)s for key: \(key)")
            return userValue
        }
        
        switch context {
        case .heartRate:
            return defaultHeartRateBuffer(for: interval)
        case .steps:
            return defaultStepsBuffer(for: interval)
        }
    }
    
    private func defaultHeartRateBuffer(for interval: Reminder.Interval) -> TimeInterval {
        switch interval {
        case .oneMinute: return 12
        case .fiveMinutes: return 60
        case .fifteenMinutes: return 180
        case .oneHour: return 720
        default: return 0
        }
    }
    
    private func defaultStepsBuffer(for interval: Reminder.Interval) -> TimeInterval {
        switch interval {
        case .thirtyMinutes: return 450
        case .oneHour: return 900
        case .twoHours: return 1800
        case .fourHours: return 3600
        case .oneDay: return 0
        default: return 0
        }
    }
}

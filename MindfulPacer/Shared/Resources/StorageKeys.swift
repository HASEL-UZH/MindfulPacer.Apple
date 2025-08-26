//
//  StorageKeys.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 24.08.2025.
//

import Foundation

struct StorageKeys {
    // Keys for persistent alert counts on the watch
    static let strongAlertCount = "strongAlertCount"
    static let mediumAlertCount = "mediumAlertCount"
    static let lightAlertCount = "lightAlertCount"
    static let lastAlertDate = "lastAlertDate"
    
    // Key for the pending notifications ledger on the watch
    static let pendingNotificationsKey = "pendingNotificationsKey"
    
    // Key for the trigger data cache on the watch
    static let alertCacheKey = "com.mindfulpacer.alertDataCache"
    
    // Helper function to create unique keys for each customizable buffer.
    static func bufferKey(for interval: Reminder.Interval, type: Reminder.MeasurementType) -> String {
        return "buffer_\(type.rawValue)_\(interval.rawValue)"
    }
}

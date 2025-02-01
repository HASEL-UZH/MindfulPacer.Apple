//
//  Reminder.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Foundation
import HealthKit
import SwiftData
import SwiftUI
#if os(watchOS)
import WatchKit
#endif

// MARK: - Reminder

typealias Reminder = SchemaV1.Reminder
typealias MeasurementType = SchemaV1.Reminder.MeasurementType

extension SchemaV1 {
    @Model
    final class Reminder: @unchecked Sendable { // TODO: Check if it's ok to have this as un unchecked sendable
        var id: UUID = UUID()
        var measurementType: MeasurementType = MeasurementType.heartRate
        var reminderType: ReminderType = ReminderType.light
        var threshold: Int = 0
        var interval: Interval = Interval.tenSeconds
        
        init(
            id: UUID = UUID(),
            measurementType: MeasurementType = MeasurementType.heartRate,
            reminderType: ReminderType = ReminderType.light,
            threshold: Int = 0,
            interval: Interval = Interval.tenSeconds
        ) {
            self.id = id
            self.measurementType = measurementType
            self.reminderType = reminderType
            self.threshold = threshold
            self.interval = interval
        }
        
        var triggerSummary: String {
            switch measurementType {
            case .heartRate:
                "Above \(threshold) bpm for \(interval.rawValue.lowercased())"
            case .steps:
                "Above \(threshold) steps within \(interval.rawValue.lowercased())"
            }
        }
        
        var thresholdUnits: String {
            switch measurementType {
            case .heartRate:
                "bpm"
            case .steps:
                "steps"
            }
        }
    }
}

// MARK: - Measurement Type

extension Reminder {
    enum MeasurementType: String, Codable, CaseIterable {
        case heartRate = "Heart Rate"
        case steps = "Steps"
        
        var quantityTypeIdentifier: HKQuantityTypeIdentifier? {
            switch self {
            case .heartRate:
                return .heartRate
            case .steps:
                return .stepCount
            }
        }
        
        var icon: String {
            switch self {
            case .heartRate: "heart.fill"
            case .steps: "figure.walk"
            }
        }
        
        var color: Color {
            switch self {
            case .heartRate: .pink
            case .steps: .teal
            }
        }
    }
}

// MARK: - Reminder Type

extension Reminder {
    enum ReminderType: String, Codable, CaseIterable {
        case light = "Light"
        case medium = "Medium"
        case strong = "Strong"
        
        var icon: String {
            switch self {
            case .light: "sun.min"
            case .medium: "hand.tap"
            case .strong: "lightbulb"
            }
        }
        
        var description: String {
            switch self {
            case .light:
                "Shows a yellow color"
            case .medium:
                "Shows an orange color"
            case .strong:
                "Shows a red color"
            }
        }
        
        var color: Color {
            switch self {
            case .light: .yellow
            case .medium: .orange
            case .strong: .red
            }
        }
    }
}

// MARK: - Interval

extension Reminder {
    enum Interval: String, Codable, CaseIterable {
        
        // MARK: Heart Rate
        
        case immediately = "Immediately"
        case tenSeconds = "10 Seconds"
        case thirtySeconds = "30 Seconds"
        case oneMinute = "1 Minute"
        
        // MARK: Steps
        
        case thirtyMinutes = "30 Minutes"
        case oneHour = "1 Hour"
        case twoHours = "2 Hours"
        case fourHours = "4 Hours"
        case oneDay = "1 Day"
        
        var icon: String {
            switch self {
            case .immediately: "alarm"
            case .tenSeconds: "10.circle"
            case .thirtySeconds: "30.circle"
            case .oneMinute: "1.circle"
            case .thirtyMinutes: "30.circle"
            case .oneHour: "1.circle"
            case .twoHours: "2.circle"
            case .fourHours: "4.circle"
            case .oneDay: "1.circle"
            }
        }
        
        var timeInterval: TimeInterval {
            switch self {
            case .thirtyMinutes: return 30 * 60
            case .oneHour: return 60 * 60
            case .twoHours: return 2 * 60 * 60
            case .fourHours: return 4 * 60 * 60
            case .oneDay: return 24 * 60 * 60
            case .immediately: return 0
            case .tenSeconds: return 10
            case .thirtySeconds: return 30
            case .oneMinute: return 60
            }
        }
        
        static var heartRateIntervals: [Interval] {
            [.immediately, .tenSeconds, .thirtySeconds, .oneMinute]
        }
        
        static var stepsIntervals: [Interval] {
            [.thirtyMinutes, .oneHour, .twoHours, .fourHours, .oneDay]
        }
    }
}

// MARK: - Missed Reflection

struct MissedReflection: Identifiable {
    let measurementType: MeasurementType
    let reminderType: Reminder.ReminderType
    let threshold: Int
    let interval: Reminder.Interval
    var date: Date
    
    var id: String {
        "\(measurementType.rawValue)-\(reminderType.rawValue)-\(threshold)-\(interval.rawValue)-\(date.timeIntervalSince1970)"
    }
    
    var triggerSummary: String {
        switch measurementType {
        case .heartRate:
            "Above \(threshold) bpm for \(interval.rawValue.lowercased())"
        case .steps:
            "Above \(threshold) steps within \(interval.rawValue.lowercased())"
        }
    }
    
    var thresholdUnits: String {
        switch measurementType {
        case .heartRate:
            "bpm"
        case .steps:
            "steps"
        }
    }
    
    init(_ reminder: Reminder, date: Date) {
        self.measurementType = reminder.measurementType
        self.reminderType = reminder.reminderType
        self.threshold = reminder.threshold
        self.interval = reminder.interval
        self.date = date
    }
    
    static let actionedKey: String = "actionedMissedReflections"
}

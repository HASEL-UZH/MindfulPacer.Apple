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
typealias Interval = SchemaV1.Reminder.Interval

extension SchemaV1 {
    @Model
    final class Reminder: @unchecked Sendable { // TODO: Check if it's ok to have this as un unchecked sendable
        var id: UUID = UUID()
        var measurementType: MeasurementType = MeasurementType.heartRate
        var reminderType: ReminderType = ReminderType.light
        var threshold: Int = 0
        var interval: Interval = Interval.immediately
        
        init(
            id: UUID = UUID(),
            measurementType: MeasurementType = MeasurementType.heartRate,
            reminderType: ReminderType = ReminderType.light,
            threshold: Int = 0,
            interval: Interval = Interval.immediately
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
                let timeString = interval.timeInterval < 60 ? "\(Int(interval.timeInterval)) sec" : "\(Int(interval.timeInterval / 60)) min"
                return String(localized: "Above \(threshold) bpm for \(timeString)")
            case .steps:
                let timeString = interval.timeInterval < 3600 ? "\(Int(interval.timeInterval / 60)) min" : "\(Int(interval.timeInterval / 3600)) hr"
                return String(localized: "Above \(threshold) steps within \(timeString)")
            }
        }
        
        var thresholdUnits: String {
            switch measurementType {
            case .heartRate:
                String(localized: "bpm")
            case .steps:
                String(localized: "steps")
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
        
        var localized: String {
            switch self {
            case .heartRate:
                String(localized: "Heart Rate")
            case .steps:
                String(localized: "Steps")
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
        
        var units: String {
            switch self {
            case .heartRate:
                String(localized: "bpm")
            case .steps:
                String(localized: "steps")
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
        
        var localized: String {
            switch self {
            case .light: String(localized: "Light")
            case .medium: String(localized: "Medium")
            case .strong: String(localized: "Strong")
            }
        }
        
        var image: Image {
            switch self {
            case .light: Image(.lightReminder)
            case .medium: Image(.mediumReminder)
            case .strong: Image(.strongReminder)
            }
        }
        
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
                String(localized: "Shows a yellow color")
            case .medium:
                String(localized: "Shows an orange color")
            case .strong:
                String(localized: "Shows a red color")
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
        case oneMinute = "1 Minute"
        case twoMinutes = "2 Minutes"
        case fiveMinutes = "5 Minutes"
        case tenMinutes = "10 Minutes"
        case fifteenMinutes = "15 Minutes"
        
        // MARK: Steps
        
        case thirtyMinutes = "30 Minutes"
        case oneHour = "1 Hour"
        case twoHours = "2 Hours"
        case fourHours = "4 Hours"
        case oneDay = "1 Day"
        
        var localized: String {
            switch self {
            case .immediately: String(localized: "Immediately")
            case .oneMinute: String(localized: "1 Minute")
            case .twoMinutes: String(localized: "2 Minutes")
            case .fiveMinutes: String(localized: "5 Minutes")
            case .tenMinutes: String(localized: "10 Minutes")
            case .fifteenMinutes: String(localized: "15 Minutes")
            case .thirtyMinutes: String(localized: "30 Minutes")
            case .oneHour: String(localized: "1 Hour")
            case .twoHours: String(localized: "2 Hours")
            case .fourHours: String(localized: "4 Hours")
            case .oneDay: String(localized: "1 Day")
            }
        }
        
        var icon: String {
            switch self {
            case .immediately: "alarm"
            case .oneMinute: "1.circle"
            case .twoMinutes: "2.circle"
            case .fiveMinutes: "5.circle"
            case .tenMinutes: "10.circle"
            case .fifteenMinutes: "15.circle"
            case .thirtyMinutes: "30.circle"
            case .oneHour: "1.circle"
            case .twoHours: "2.circle"
            case .fourHours: "4.circle"
            case .oneDay: "1.circle"
            }
        }
        
        var timeInterval: TimeInterval {
            IntervalSettingsManager.shared.timeInterval(for: self)
        }
        
        func buffer(for context: IntervalContext) -> TimeInterval {
            BufferManager.shared.buffer(for: self, context: context)
        }
        
        static var heartRateIntervals: [Interval] {
            [.oneMinute, .twoMinutes, .fiveMinutes, .fifteenMinutes, .oneHour]
        }
        
        static var stepsIntervals: [Interval] {
            [.thirtyMinutes, .oneHour, .twoHours, .fourHours, .oneDay]
        }
    }
}

// MARK: - IntervalContext

enum IntervalContext {
    case heartRate
    case steps
}

// MARK: - IntervalSettingsManager

final class IntervalSettingsManager: ObservableObject, @unchecked Sendable {
    static let shared = IntervalSettingsManager()

    private let defaultTimeIntervals: [Reminder.Interval: TimeInterval] = [
        .immediately: 0,
        .oneMinute: 60,
        .twoMinutes: 2 * 60,
        .fiveMinutes: 5 * 60,
        .tenMinutes: 10 * 60,
        .fifteenMinutes: 15 * 60,

        .thirtyMinutes: 30 * 60,
        .oneHour: 60 * 60,
        .twoHours: 2 * 60 * 60,
        .fourHours: 4 * 60 * 60,
        .oneDay: 24 * 60 * 60
    ]

    private init() {}

    func timeInterval(for interval: Reminder.Interval) -> TimeInterval {
        defaultTimeIntervals[interval] ?? 0
    }
}

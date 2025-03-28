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
                String(localized: "Above \(threshold) bpm for \(interval.rawValue.lowercased())")
            case .steps:
                String(localized: "Above \(threshold) steps within \(interval.rawValue.lowercased())")
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
        
        static func timeInterval(_ interval: Interval) -> TimeInterval {
            switch interval {
            case .immediately: return 0
            case .fiveMinutes: return 5 * 60
            case .tenMinutes: return 10 * 60
            case .fifteenMinutes: return 15 * 60
            case .thirtyMinutes: return 30 * 60
            case .oneHour: return 60 * 60
            case .twoHours: return 2 * 60 * 60
            case .fourHours: return 4 * 60 * 60
            case .oneDay: return 24 * 60 * 60
            }
        }
        
        static func buffer(_ interval: Interval) -> TimeInterval {
            switch interval {
            case .immediately: return 0
            case .fiveMinutes: return 1
            case .tenMinutes: return 2
            case .fifteenMinutes: return 3
            case .thirtyMinutes: return 6
            case .oneHour: return 12
            case .twoHours: return 30
            case .fourHours: return 60
            case .oneDay: return 0
            }
        }
        
        static var heartRateIntervals: [Interval] {
            [.immediately, .fiveMinutes, .tenMinutes, .fifteenMinutes, .thirtyMinutes, .oneHour]
        }
        
        static var stepsIntervals: [Interval] {
            [.thirtyMinutes, .oneHour, .twoHours, .fourHours, .oneDay]
        }
    }
}

// MARK: - Reflection Action State Enum

enum ReflectionAction: String, Codable {
    case accepted
    case rejected
}

// MARK: - Missed Reflection

struct MissedReflection: Identifiable, Equatable {
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
    
    static let actionedKey: String = "actionedMissedReflections"
    
    init(_ reminder: Reminder, date: Date) {
        self.measurementType = reminder.measurementType
        self.reminderType = reminder.reminderType
        self.threshold = reminder.threshold
        self.interval = reminder.interval
        self.date = date
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: MissedReflection, rhs: MissedReflection) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Action Tracking Methods
    
    /// Checks if this MissedReflection has been actioned (accepted or rejected).
    var isActioned: Bool {
        return actionState != nil
    }
    
    /// Retrieves the action state (accepted or rejected) for this MissedReflection, if any.
    var actionState: ReflectionAction? {
        let actionedReflections = Self.loadActionedReflections()
        return actionedReflections[id]
    }
    
    /// Marks this MissedReflection as accepted.
    func accept() {
        markAction(.accepted)
    }
    
    /// Marks this MissedReflection as rejected.
    func reject() {
        markAction(.rejected)
    }
    
    /// Private helper to mark this MissedReflection with a specific action.
    private func markAction(_ action: ReflectionAction) {
        var actionedReflections = Self.loadActionedReflections()
        actionedReflections[id] = action
        Self.saveActionedReflections(actionedReflections)
    }
    
    /// Loads the dictionary of actioned MissedReflections from UserDefaults.
    private static func loadActionedReflections() -> [String: ReflectionAction] {
        guard let data = UserDefaults.standard.data(forKey: actionedKey),
              let dictionary = try? JSONDecoder().decode([String: ReflectionAction].self, from: data) else {
            return [:]
        }
        return dictionary
    }
    
    /// Saves the dictionary of actioned MissedReflections to UserDefaults.
    private static func saveActionedReflections(_ dictionary: [String: ReflectionAction]) {
        if let data = try? JSONEncoder().encode(dictionary) {
            UserDefaults.standard.set(data, forKey: actionedKey)
        }
    }
}

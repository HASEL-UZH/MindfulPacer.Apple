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
            IntervalSettingsManager.shared.buffer(for: self, context: context)
        }
        
        static var heartRateIntervals: [Interval] {
            [.oneMinute, .fiveMinutes, .fifteenMinutes, .oneHour]
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

// MARK: - IntervalContext

enum IntervalContext {
    case heartRate
    case steps
}

// MARK: - IntervalSettingsManager

class IntervalSettingsManager: ObservableObject, @unchecked Sendable {
    static let shared = IntervalSettingsManager()
    
    // Default values for each interval (used as fixed values for timeInterval and fallback for buffer)
    private let defaultTimeIntervals: [Reminder.Interval: TimeInterval] = [
        .immediately: 0,
        .oneMinute: 60,
        .fiveMinutes: 5 * 60,
        .tenMinutes: 10 * 60,
        .fifteenMinutes: 15 * 60,
        .thirtyMinutes: 30 * 60,
        .oneHour: 60 * 60,
        .twoHours: 2 * 60 * 60,
        .fourHours: 4 * 60 * 60,
        .oneDay: 24 * 60 * 60
    ]
    
    // Updated default buffers based on DELAY_MAPPING (converted from minutes to seconds)
    private let defaultBuffers: [Reminder.Interval: TimeInterval] = [
        .immediately: 0,         // None (0 seconds)
        .oneMinute: 5,
        .fiveMinutes: 60,        // 1 minute = 60 seconds
        .tenMinutes: 120,        // 2 minutes = 120 seconds
        .fifteenMinutes: 180,    // 3 minutes = 180 seconds
        .thirtyMinutes: 450,     // 7.5 minutes = 450 seconds (steps); HR uses 360 seconds (6 minutes)
        .oneHour: 900,           // 15 minutes = 900 seconds (steps); HR uses 720 seconds (12 minutes)
        .twoHours: 1800,         // 30 minutes = 1800 seconds
        .fourHours: 3600,        // 60 minutes = 3600 seconds
        .oneDay: 0               // 0 minutes = 0 seconds
    ]
    
    // AppStorage properties for heart rate buffers (using HR-specific values)
    @AppStorage("hr_immediately_buffer") private var hr_immediatelyBuffer: Double = 0      // 0 seconds
    @AppStorage("hr_oneMinute_buffer") private var hr_oneMinuteBuffer: Double = 30      // 30 seconds
    @AppStorage("hr_fiveMinutes_buffer") private var hr_fiveMinutesBuffer: Double = 60      // 1 minute
    @AppStorage("hr_tenMinutes_buffer") private var hr_tenMinutesBuffer: Double = 120       // 2 minutes
    @AppStorage("hr_fifteenMinutes_buffer") private var hr_fifteenMinutesBuffer: Double = 180  // 3 minutes
    @AppStorage("hr_thirtyMinutes_buffer") private var hr_thirtyMinutesBuffer: Double = 360   // 6 minutes
    @AppStorage("hr_oneHour_buffer") private var hr_oneHourBuffer: Double = 720             // 12 minutes
    
    // AppStorage properties for steps buffers (using steps-specific values)
    @AppStorage("steps_thirtyMinutes_buffer") private var steps_thirtyMinutesBuffer: Double = 450  // 7.5 minutes
    @AppStorage("steps_oneHour_buffer") private var steps_oneHourBuffer: Double = 900        // 15 minutes
    @AppStorage("steps_twoHours_buffer") private var steps_twoHoursBuffer: Double = 1800     // 30 minutes
    @AppStorage("steps_fourHours_buffer") private var steps_fourHoursBuffer: Double = 3600   // 60 minutes
    @AppStorage("steps_oneDay_buffer") private var steps_oneDayBuffer: Double = 0            // 0 minutes
    
    private init() {}
    
    // Get the timeInterval for a given interval (fixed value, no context needed since it's not editable)
    func timeInterval(for interval: Reminder.Interval) -> TimeInterval {
        return defaultTimeIntervals[interval] ?? 0
    }
    
    // Get the buffer for a given interval and context
    func buffer(for interval: Reminder.Interval, context: IntervalContext) -> TimeInterval {
        switch (interval, context) {
        case (.immediately, .heartRate): return hr_immediatelyBuffer
        case (.oneMinute, .heartRate): return hr_oneMinuteBuffer
        case (.fiveMinutes, .heartRate): return hr_fiveMinutesBuffer
        case (.tenMinutes, .heartRate): return hr_tenMinutesBuffer
        case (.fifteenMinutes, .heartRate): return hr_fifteenMinutesBuffer
        case (.thirtyMinutes, .heartRate): return hr_thirtyMinutesBuffer
        case (.oneHour, .heartRate): return hr_oneHourBuffer
        case (.thirtyMinutes, .steps): return steps_thirtyMinutesBuffer
        case (.oneHour, .steps): return steps_oneHourBuffer
        case (.twoHours, .steps): return steps_twoHoursBuffer
        case (.fourHours, .steps): return steps_fourHoursBuffer
        case (.oneDay, .steps): return steps_oneDayBuffer
        default: return defaultBuffers[interval] ?? 0 // Fallback
        }
    }
    
    // Set the buffer for a given interval and context
    func setBuffer(_ value: Double, for interval: Reminder.Interval, context: IntervalContext) {
        switch (interval, context) {
        case (.immediately, .heartRate): hr_immediatelyBuffer = value
        case (.oneMinute, .heartRate): hr_oneMinuteBuffer = value
        case (.fiveMinutes, .heartRate): hr_fiveMinutesBuffer = value
        case (.tenMinutes, .heartRate): hr_tenMinutesBuffer = value
        case (.fifteenMinutes, .heartRate): hr_fifteenMinutesBuffer = value
        case (.thirtyMinutes, .heartRate): hr_thirtyMinutesBuffer = value
        case (.oneHour, .heartRate): hr_oneHourBuffer = value
        case (.thirtyMinutes, .steps): steps_thirtyMinutesBuffer = value
        case (.oneHour, .steps): steps_oneHourBuffer = value
        case (.twoHours, .steps): steps_twoHoursBuffer = value
        case (.fourHours, .steps): steps_fourHoursBuffer = value
        case (.oneDay, .steps): steps_oneDayBuffer = value
        default: break // Invalid combination
        }
    }
    
    // Reset buffers to default values
    func resetToDefaults() {
        hr_immediatelyBuffer = defaultBuffers[.immediately]!
        hr_oneMinuteBuffer = defaultBuffers[.oneMinute]!
        hr_fiveMinutesBuffer = defaultBuffers[.fiveMinutes]!
        hr_tenMinutesBuffer = defaultBuffers[.tenMinutes]!
        hr_fifteenMinutesBuffer = defaultBuffers[.fifteenMinutes]!
        hr_thirtyMinutesBuffer = defaultBuffers[.thirtyMinutes]! // Uses HR value (360 seconds)
        hr_oneHourBuffer = defaultBuffers[.oneHour]!            // Uses HR value (720 seconds)
        steps_thirtyMinutesBuffer = defaultBuffers[.thirtyMinutes]! // Uses steps value (450 seconds)
        steps_oneHourBuffer = defaultBuffers[.oneHour]!         // Uses steps value (900 seconds)
        steps_twoHoursBuffer = defaultBuffers[.twoHours]!
        steps_fourHoursBuffer = defaultBuffers[.fourHours]!
        steps_oneDayBuffer = defaultBuffers[.oneDay]!
    }
}

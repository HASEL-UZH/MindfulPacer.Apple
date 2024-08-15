//
//  ReviewReminder.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Foundation
import SwiftData

// MARK: - Review Reminder

typealias ReviewReminder = SchemaV1.ReviewReminder

extension SchemaV1 {
    @Model
    final class ReviewReminder {
        var id: UUID = UUID()
        var measurementType: MeasurementType = MeasurementType.heartRate
        var alarmType: AlarmType = AlarmType.light
        var threshold: Int = 0
        var vibrationStrength: VibrationStrength = VibrationStrength.none
        var interval: Interval = Interval._10seconds
        
        init(
            id: UUID = UUID(),
            measurementType: MeasurementType = MeasurementType.heartRate,
            alarmType: AlarmType = AlarmType.light,
            threshold: Int = 0,
            vibrationStrength: VibrationStrength = VibrationStrength.none,
            interval: Interval = Interval._10seconds
        ) {
            self.id = id
            self.measurementType = measurementType
            self.alarmType = alarmType
            self.threshold = threshold
            self.vibrationStrength = vibrationStrength
            self.interval = interval
        }
    }
}

// MARK: - Measurement Type

extension ReviewReminder {
    enum MeasurementType: String, Codable, CaseIterable {
        case heartRate = "Heart Rate"
        case steps = "Steps"
        
        var icon: String {
            switch self {
            case .heartRate: "heart"
            case .steps: "figure.walk"
            }
        }
    }
}

// MARK: - Alarm Type

extension ReviewReminder {
    enum AlarmType: String, Codable, CaseIterable {
        case light
        case medium
        case strong
        
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
                "Coloured display, vibration"
            case .medium:
                "Vibration, confirmation required"
            case .strong:
                "Blinking display, vibration, sound, confirmation required"
            }
        }
    }
}

// MARK: - Vibration Strength

extension ReviewReminder {
    enum VibrationStrength: String, Codable, CaseIterable {
        case none
        case light
        case medium
        case strong
    }
}

// MARK: - Interval

extension ReviewReminder {
    enum Interval: String, Codable, CaseIterable {
        case immediately
        case _10seconds
        case _30second
        case _1minute
        
        var icon: String {
            switch self {
            case .immediately: "alarm"
            case ._10seconds: "10.circle"
            case ._30second: "30.circle"
            case ._1minute: "1.circle"
            }
        }
    }
}

//
//  ReviewReminder.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Foundation
import SwiftData
import SwiftUI
#if os(watchOS)
import WatchKit
#endif

// MARK: - Review Reminder

typealias ReviewReminder = SchemaV1.ReviewReminder

extension SchemaV1 {
    @Model
    final class ReviewReminder {
        var id: UUID = UUID()
        var measurementType: MeasurementType = MeasurementType.heartRate
        var alarmType: AlarmType = AlarmType.light
        var threshold: Int = 0
//        var vibrationStrength: VibrationStrength = VibrationStrength.none
        var interval: Interval = Interval._10seconds
        
        init(
            id: UUID = UUID(),
            measurementType: MeasurementType = MeasurementType.heartRate,
            alarmType: AlarmType = AlarmType.light,
            threshold: Int = 0,
//            vibrationStrength: VibrationStrength = VibrationStrength.none,
            interval: Interval = Interval._10seconds
        ) {
            self.id = id
            self.measurementType = measurementType
//            self.alarmType = alarmType
            self.threshold = threshold
//            self.vibrationStrength = vibrationStrength
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

// MARK: - Vibration Strength

extension ReviewReminder {
    enum VibrationStrength: String, Codable, CaseIterable {
        case none = "None"
        case light = "Light"
        case medium = "Medium"
        case strong = "Strong"
        
        #if os(watchOS)
        /// Since there is no direct mapping to the concept of 'strength' with haptic feedback on the Apple Watch, we are using default types to mimic a scale from 'light' to 'strong'
        func hapticType() -> WKHapticType? {
            switch self {
            case .none:
                return nil
            case .light:
                return .start
            case .medium:
                return .success
            case .strong:
                return .failure
            }
        }
        #endif
    }
}

// MARK: - Interval

extension ReviewReminder {
    enum Interval: String, Codable, CaseIterable {
        case immediately = "Immediately"
        case _10seconds = "10 Seconds"
        case _30second = "30 Seconds"
        case _1minute = "1 Minute"
        
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

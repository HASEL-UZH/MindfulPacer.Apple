//
//  ReviewReminder.swift
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

// MARK: - Review Reminder

typealias ReviewReminder = SchemaV1.ReviewReminder
typealias MeasurementType = SchemaV1.ReviewReminder.MeasurementType

extension SchemaV1 {
    @Model
    final class ReviewReminder {
        var id: UUID = UUID()
        var measurementType: MeasurementType = MeasurementType.heartRate
        var reviewReminderType: ReviewReminderType = ReviewReminderType.light
        var threshold: Int = 0
        var interval: Interval = Interval.tenSeconds

        init(
            id: UUID = UUID(),
            measurementType: MeasurementType = MeasurementType.heartRate,
            reviewReminderType: ReviewReminderType = ReviewReminderType.light,
            threshold: Int = 0,
            interval: Interval = Interval.tenSeconds
        ) {
            self.id = id
            self.measurementType = measurementType
            self.reviewReminderType = reviewReminderType
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
    }
}

// MARK: - Measurement Type

extension ReviewReminder {
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

// MARK: - Review Reminder Type

extension ReviewReminder {
    enum ReviewReminderType: String, Codable, CaseIterable {
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

extension ReviewReminder {
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
        
        static var heartRateIntervals: [Interval] {
            [.immediately, .tenSeconds, .thirtyMinutes, .oneMinute]
        }
        
        static var stepsIntervals: [Interval] {
            [.thirtyMinutes, .oneHour, .twoHours, .fourHours, .oneDay]
        }
    }
}

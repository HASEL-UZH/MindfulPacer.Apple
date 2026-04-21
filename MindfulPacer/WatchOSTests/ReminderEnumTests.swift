//
//  ReminderEnumTests.swift
//  WatchOSTests
//
//  Tests for the enums and constants that make up the Reminder model layer:
//
//  - `Reminder.Interval` – the check frequency for a rule (e.g. every 5 minutes).
//  - `Reminder.MeasurementType` – heart rate vs. steps.
//  - `Reminder.ReminderType` – alert intensity (light / medium / strong).
//  - `ComplicationState` – the watch complication's displayed state.
//  - `ComplicationKeys` – UserDefaults keys for complication data.
//  - `MessageCommand` – commands sent between iPhone and Watch via WCSession.
//

import Testing
import Foundation
@testable import WatchOS

// MARK: - Interval

/// `Reminder.Interval` defines how often the app checks whether a measurement
/// exceeds the threshold. Heart-rate intervals range from 1 minute to 1 hour;
/// step intervals range from 30 minutes to 1 day.
@Suite("Reminder.Interval")
struct IntervalTests {

    /// The subset of intervals available when creating a heart-rate reminder.
    @Test func heartRateIntervals_containsExpectedCases() {
        let intervals = Reminder.Interval.heartRateIntervals
        #expect(intervals.contains(.oneMinute))
        #expect(intervals.contains(.twoMinutes))
        #expect(intervals.contains(.fiveMinutes))
        #expect(intervals.contains(.fifteenMinutes))
        #expect(intervals.contains(.oneHour))
        #expect(intervals.count == 5)
    }

    /// The subset of intervals available when creating a steps reminder.
    @Test func stepsIntervals_containsExpectedCases() {
        let intervals = Reminder.Interval.stepsIntervals
        #expect(intervals.contains(.thirtyMinutes))
        #expect(intervals.contains(.oneHour))
        #expect(intervals.contains(.twoHours))
        #expect(intervals.contains(.fourHours))
        #expect(intervals.contains(.oneDay))
        #expect(intervals.count == 5)
    }

    /// Every interval must provide an SF Symbol icon for use in the UI.
    @Test func icon_allCasesReturnNonEmptyString() {
        for interval in Reminder.Interval.allCases {
            #expect(!interval.icon.isEmpty)
        }
    }

    /// Raw values must be unique since they are used as Codable identifiers
    /// and UserDefaults key components.
    @Test func rawValue_allCasesHaveUniqueRawValues() {
        let rawValues = Reminder.Interval.allCases.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
    }

    /// "Immediately" has a 0-second time interval (alert fires instantly).
    @Test func timeInterval_immediatelyIsZero() {
        #expect(Reminder.Interval.immediately.timeInterval == 0)
    }

    /// "1 Day" maps to exactly 86 400 seconds (24 hours).
    @Test func timeInterval_oneDayIs86400() {
        #expect(Reminder.Interval.oneDay.timeInterval == 86400)
    }
}

// MARK: - MeasurementType

/// `Reminder.MeasurementType` distinguishes the two health metrics the app
/// monitors: heart rate (BPM via Apple Watch sensors) and step count (via
/// HealthKit pedometer data).
@Suite("Reminder.MeasurementType")
struct MeasurementTypeTests {

    /// Heart rate uses the "heart.fill" SF Symbol.
    @Test func icon_heartRate() {
        #expect(Reminder.MeasurementType.heartRate.icon == "heart.fill")
    }

    /// Steps uses the "figure.walk" SF Symbol.
    @Test func icon_steps() {
        #expect(Reminder.MeasurementType.steps.icon == "figure.walk")
    }

    /// Both types must provide a non-empty units string (e.g. "bpm", "steps").
    @Test func units_heartRate() {
        #expect(!Reminder.MeasurementType.heartRate.units.isEmpty)
    }

    @Test func units_steps() {
        #expect(!Reminder.MeasurementType.steps.units.isEmpty)
    }

    /// The enum has exactly two cases.
    @Test func allCases_hasTwo() {
        #expect(Reminder.MeasurementType.allCases.count == 2)
    }

    /// Each measurement type maps to a HealthKit quantity type identifier so the
    /// app knows which HK data to query.
    @Test func quantityTypeIdentifier_isNotNil() {
        #expect(Reminder.MeasurementType.heartRate.quantityTypeIdentifier != nil)
        #expect(Reminder.MeasurementType.steps.quantityTypeIdentifier != nil)
    }
}

// MARK: - ReminderType

/// `Reminder.ReminderType` controls alert intensity: light (yellow, gentle
/// haptic), medium (orange, firm haptic), or strong (red, repeated haptic).
@Suite("Reminder.ReminderType")
struct ReminderTypeTests {

    /// The enum has exactly three cases.
    @Test func allCases_hasThree() {
        #expect(Reminder.ReminderType.allCases.count == 3)
    }

    /// Each type provides an SF Symbol icon for the reminder creation UI.
    @Test func icon_allCasesReturnNonEmptyString() {
        for type in Reminder.ReminderType.allCases {
            #expect(!type.icon.isEmpty)
        }
    }

    /// Each type provides a user-facing description explaining its behavior.
    @Test func description_allCasesReturnNonEmptyString() {
        for type in Reminder.ReminderType.allCases {
            #expect(!type.description.isEmpty)
        }
    }

    /// Raw values match the English labels used for Codable serialization.
    @Test func rawValue_light() {
        #expect(Reminder.ReminderType.light.rawValue == "Light")
    }

    @Test func rawValue_medium() {
        #expect(Reminder.ReminderType.medium.rawValue == "Medium")
    }

    @Test func rawValue_strong() {
        #expect(Reminder.ReminderType.strong.rawValue == "Strong")
    }
}

// MARK: - ComplicationState

/// `ComplicationState` represents what the watch complication displays:
/// active (monitoring in progress), paused (user paused), or inactive (stopped).
@Suite("ComplicationState")
struct ComplicationStateTests {

    /// Raw values are stable integers used in UserDefaults, so they must not change.
    @Test func rawValues() {
        #expect(ComplicationState.active.rawValue == 0)
        #expect(ComplicationState.paused.rawValue == 1)
        #expect(ComplicationState.inactive.rawValue == 2)
    }

    /// The state must survive a JSON encode/decode round trip since it is
    /// shared between the app and the widget extension via UserDefaults.
    @Test func codable_roundTrip() throws {
        let original = ComplicationState.paused
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ComplicationState.self, from: data)
        #expect(decoded == original)
    }
}

// MARK: - ComplicationKeys

/// `ComplicationKeys` holds the UserDefaults key strings used to share
/// monitoring state between the watchOS app and its complication widget.
@Suite("ComplicationKeys")
struct ComplicationKeysTests {

    /// Both keys must be non-empty strings.
    @Test func keysAreNonEmpty() {
        #expect(!ComplicationKeys.state.isEmpty)
        #expect(!ComplicationKeys.lastUpdated.isEmpty)
    }

    /// The two keys must be distinct to avoid overwriting each other.
    @Test func keysAreUnique() {
        #expect(ComplicationKeys.state != ComplicationKeys.lastUpdated)
    }
}

// MARK: - MessageCommand

/// `MessageCommand` defines the vocabulary of messages exchanged between the
/// iPhone app and the Watch app over WatchConnectivity (WCSession). Each
/// command triggers a specific action on the receiving side.
@Suite("MessageCommand")
struct MessageCommandTests {

    /// All commands must have unique raw values to avoid routing collisions.
    @Test func allCommandsHaveUniqueRawValues() {
        let commands: [MessageCommand] = [
            .triggerLocalNotification,
            .remindersUpdated,
            .createReflection,
            .requestCreateReflection,
            .openReflectionForEditing,
            .ping
        ]
        let rawValues = commands.map(\.rawValue)
        #expect(Set(rawValues).count == rawValues.count)
    }

    /// A command must survive a raw-value round trip (used for WCSession
    /// message dictionary encoding).
    @Test func roundTrip() {
        let command = MessageCommand.ping
        let raw = command.rawValue
        #expect(MessageCommand(rawValue: raw) == .ping)
    }
}

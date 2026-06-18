//
//  BackgroundStoreTests.swift
//  iOSTests
//
//  Tests for `BackgroundReminderConfig` and `BackgroundReflectionSnapshot`,
//  the lightweight Codable structs used to share reminder and reflection data
//  between the iOS app and its background processing extensions via App Group
//  UserDefaults. These structs are serialized to JSON and stored in shared
//  UserDefaults so that background tasks (e.g. health monitoring, notifications)
//  can access the latest reminder configurations and reflection states without
//  needing a full SwiftData context.
//

import Testing
import Foundation
@testable import iOS

// MARK: - BackgroundReminderConfig Codable

/// Validates that `BackgroundReminderConfig` correctly encodes and decodes
/// via JSON. This is critical because the struct is serialized to Data and
/// stored in shared UserDefaults for background task access.
struct BackgroundReminderConfigCodableTests {

    /// A config with all fields populated should survive JSON round-trip.
    @Test func codable_roundTrip() throws {
        let id = UUID()
        let original = BackgroundReminderConfig(
            id: id,
            measurementType: .heartRate,
            reminderType: .medium,
            threshold: 120,
            interval: .fiveMinutes
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BackgroundReminderConfig.self, from: data)
        #expect(decoded.id == id)
        #expect(decoded.measurementType == .heartRate)
        #expect(decoded.reminderType == .medium)
        #expect(decoded.threshold == 120)
        #expect(decoded.interval == .fiveMinutes)
    }

    /// An array of configs (as stored in UserDefaults) should round-trip.
    @Test func codable_array_roundTrip() throws {
        let configs = [
            BackgroundReminderConfig(id: UUID(), measurementType: .heartRate, reminderType: .light, threshold: 100, interval: .tenMinutes),
            BackgroundReminderConfig(id: UUID(), measurementType: .steps, reminderType: .strong, threshold: 5000, interval: .oneHour)
        ]
        let data = try JSONEncoder().encode(configs)
        let decoded = try JSONDecoder().decode([BackgroundReminderConfig].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].measurementType == .heartRate)
        #expect(decoded[1].measurementType == .steps)
    }
}

// MARK: - BackgroundReminderConfig Equatable

/// Validates Equatable conformance, used when comparing configs for changes.
struct BackgroundReminderConfigEqualityTests {

    /// Two configs with the same values should be equal.
    @Test func equality_sameValues() {
        let id = UUID()
        let a = BackgroundReminderConfig(id: id, measurementType: .heartRate, reminderType: .light, threshold: 80, interval: .oneMinute)
        let b = BackgroundReminderConfig(id: id, measurementType: .heartRate, reminderType: .light, threshold: 80, interval: .oneMinute)
        #expect(a == b)
    }

    /// Configs with different thresholds should not be equal.
    @Test func equality_differentThreshold() {
        let id = UUID()
        let a = BackgroundReminderConfig(id: id, measurementType: .heartRate, reminderType: .light, threshold: 80, interval: .oneMinute)
        let b = BackgroundReminderConfig(id: id, measurementType: .heartRate, reminderType: .light, threshold: 90, interval: .oneMinute)
        #expect(a != b)
    }
}

// MARK: - BackgroundReflectionSnapshot Codable

/// Validates that `BackgroundReflectionSnapshot` correctly encodes and decodes.
/// The snapshot captures essential reflection state for background processing
/// without requiring a full SwiftData Reflection object.
struct BackgroundReflectionSnapshotCodableTests {

    /// A snapshot with all fields should round-trip through JSON.
    @Test func codable_roundTrip_withMeasurementType() throws {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1700000000)
        let original = BackgroundReflectionSnapshot(
            id: id,
            date: date,
            measurementType: .heartRate,
            isRejected: false,
            isHandled: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BackgroundReflectionSnapshot.self, from: data)
        #expect(decoded.id == id)
        #expect(decoded.date == date)
        #expect(decoded.measurementType == .heartRate)
        #expect(decoded.isRejected == false)
        #expect(decoded.isHandled == true)
    }

    /// A snapshot with nil measurementType (e.g. a manual reflection without
    /// a trigger) should also round-trip correctly.
    @Test func codable_roundTrip_nilMeasurementType() throws {
        let original = BackgroundReflectionSnapshot(
            id: UUID(),
            date: Date(),
            measurementType: nil,
            isRejected: true,
            isHandled: false
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BackgroundReflectionSnapshot.self, from: data)
        #expect(decoded.measurementType == nil)
        #expect(decoded.isRejected == true)
        #expect(decoded.isHandled == false)
    }

    /// An array of snapshots should round-trip through JSON.
    @Test func codable_array_roundTrip() throws {
        let snapshots = [
            BackgroundReflectionSnapshot(id: UUID(), date: Date(), measurementType: .heartRate, isRejected: false, isHandled: true),
            BackgroundReflectionSnapshot(id: UUID(), date: Date(), measurementType: .steps, isRejected: true, isHandled: false)
        ]
        let data = try JSONEncoder().encode(snapshots)
        let decoded = try JSONDecoder().decode([BackgroundReflectionSnapshot].self, from: data)
        #expect(decoded.count == 2)
    }
}

// MARK: - BackgroundReflectionSnapshot Equatable

/// Validates Equatable conformance for snapshots.
struct BackgroundReflectionSnapshotEqualityTests {

    /// Two snapshots with identical values should be equal.
    @Test func equality_sameValues() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1700000000)
        let a = BackgroundReflectionSnapshot(id: id, date: date, measurementType: .steps, isRejected: false, isHandled: true)
        let b = BackgroundReflectionSnapshot(id: id, date: date, measurementType: .steps, isRejected: false, isHandled: true)
        #expect(a == b)
    }

    /// Snapshots with different isHandled should not be equal.
    @Test func equality_differentIsHandled() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1700000000)
        let a = BackgroundReflectionSnapshot(id: id, date: date, measurementType: nil, isRejected: false, isHandled: true)
        let b = BackgroundReflectionSnapshot(id: id, date: date, measurementType: nil, isRejected: false, isHandled: false)
        #expect(a != b)
    }
}

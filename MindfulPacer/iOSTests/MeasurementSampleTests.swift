//
//  MeasurementSampleTests.swift
//  iOSTests
//
//  Tests for `MeasurementSample`, a lightweight value type that stores a single
//  health data point (heart rate reading or step count) with its timestamp.
//  These samples are collected when a reminder threshold is exceeded and stored
//  as JSON in the Reflection's `triggerData` field, providing context about
//  what health data triggered the alert.
//

import Testing
import Foundation
@testable import iOS

// MARK: - MeasurementSample Codable

/// Validates that `MeasurementSample` correctly survives JSON encoding and
/// decoding. This is critical because trigger samples are serialized to Data
/// and stored in the Reflection model's `triggerData` property.
struct MeasurementSampleCodableTests {

    /// A heart rate sample should encode and decode with all fields preserved.
    @Test func codable_roundTrip_heartRate() throws {
        let date = Date(timeIntervalSince1970: 1700000000)
        let original = MeasurementSample(type: .heartRate, value: 120.5, date: date)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MeasurementSample.self, from: data)
        #expect(decoded.type == .heartRate)
        #expect(decoded.value == 120.5)
        #expect(decoded.date == date)
    }

    /// A steps sample should also round-trip correctly.
    @Test func codable_roundTrip_steps() throws {
        let date = Date(timeIntervalSince1970: 1700000000)
        let original = MeasurementSample(type: .steps, value: 8500, date: date)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(MeasurementSample.self, from: data)
        #expect(decoded.type == .steps)
        #expect(decoded.value == 8500)
    }

    /// An array of samples (as stored in triggerData) should round-trip correctly.
    @Test func codable_array_roundTrip() throws {
        let samples = [
            MeasurementSample(type: .heartRate, value: 95.0, date: Date(timeIntervalSince1970: 1700000000)),
            MeasurementSample(type: .heartRate, value: 102.3, date: Date(timeIntervalSince1970: 1700000060))
        ]
        let data = try JSONEncoder().encode(samples)
        let decoded = try JSONDecoder().decode([MeasurementSample].self, from: data)
        #expect(decoded.count == 2)
        #expect(decoded[0].value == 95.0)
        #expect(decoded[1].value == 102.3)
    }
}

// MARK: - MeasurementSample Hashable

/// Validates Hashable conformance, which allows MeasurementSample to be
/// used in Sets and as Dictionary keys.
struct MeasurementSampleHashableTests {

    /// Identical samples should have the same hash and be considered equal.
    @Test func hashable_identicalSamples() {
        let date = Date(timeIntervalSince1970: 1700000000)
        let a = MeasurementSample(type: .heartRate, value: 80, date: date)
        let b = MeasurementSample(type: .heartRate, value: 80, date: date)
        #expect(a == b)
        #expect(a.hashValue == b.hashValue)
    }

    /// Samples with different values should not be equal.
    @Test func hashable_differentValues() {
        let date = Date(timeIntervalSince1970: 1700000000)
        let a = MeasurementSample(type: .heartRate, value: 80, date: date)
        let b = MeasurementSample(type: .heartRate, value: 90, date: date)
        #expect(a != b)
    }
}

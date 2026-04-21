//
//  BufferManagerTests.swift
//  WatchOSTests
//
//  Tests for `BufferManager`, which controls the cooldown ("buffer") period
//  between repeated alert notifications. After the app fires a heart-rate or
//  step-count alert, it suppresses the next notification for the same reminder
//  until the buffer expires. The default buffer varies by measurement type and
//  check interval (e.g. a 1-hour heart-rate interval has a 60-minute cooldown,
//  while shorter intervals share a 15-minute cooldown). Users can override the
//  default within an allowed range of 0…2x the default.
//

import Testing
import Foundation
@testable import WatchOS

@Suite("BufferManager")
struct BufferManagerTests {

    private let sut = BufferManager.shared

    // MARK: - defaultBuffer – Heart Rate
    //
    // Heart-rate intervals up to 30 minutes share a 15-minute (900 s) buffer.
    // The 1-hour interval has a longer 60-minute (3600 s) buffer.

    @Test(arguments: [
        (Reminder.Interval.oneMinute, 15.0 * 60),
        (.twoMinutes, 15.0 * 60),
        (.fiveMinutes, 15.0 * 60),
        (.tenMinutes, 15.0 * 60),
        (.fifteenMinutes, 15.0 * 60),
        (.thirtyMinutes, 15.0 * 60),
        (.oneHour, 60.0 * 60),
    ] as [(Reminder.Interval, TimeInterval)])
    func defaultBuffer_heartRate(interval: Reminder.Interval, expected: TimeInterval) {
        #expect(sut.defaultBuffer(for: interval, context: .heartRate) == expected)
    }

    /// Intervals not mapped to heart-rate monitoring (e.g. "1 Day") return 0,
    /// meaning no cooldown is applied.
    @Test func defaultBuffer_heartRate_returnsZeroForUnmappedInterval() {
        #expect(sut.defaultBuffer(for: .oneDay, context: .heartRate) == 0)
    }

    // MARK: - defaultBuffer – Steps
    //
    // Step buffers scale with the interval: 30 min → 30 min buffer,
    // 1 hr → 1 hr, 2 hr → 2 hr, 4 hr → 4 hr. The "1 Day" interval
    // also uses a 4-hour buffer (not 24 hr), since daily alerts use a
    // separate once-per-day muting mechanism (StepDayMuteStore).

    @Test(arguments: [
        (Reminder.Interval.thirtyMinutes, 30.0 * 60),
        (.oneHour, 60.0 * 60),
        (.twoHours, 2.0 * 60 * 60),
        (.fourHours, 4.0 * 60 * 60),
        (.oneDay, 4.0 * 60 * 60),
    ] as [(Reminder.Interval, TimeInterval)])
    func defaultBuffer_steps(interval: Reminder.Interval, expected: TimeInterval) {
        #expect(sut.defaultBuffer(for: interval, context: .steps) == expected)
    }

    /// Heart-rate-only intervals (e.g. "1 Minute") have no step buffer.
    @Test func defaultBuffer_steps_returnsZeroForUnmappedInterval() {
        #expect(sut.defaultBuffer(for: .oneMinute, context: .steps) == 0)
    }

    // MARK: - allowedRange
    //
    // Users can customize the buffer within 0…(2 × default). This ensures
    // users cannot accidentally disable the cooldown beyond twice the default.

    /// For a 1-hour heart-rate interval (default buffer = 3600 s), the allowed
    /// range should be 0…7200 s.
    @Test func allowedRange_isZeroToDoubleDefault() {
        let base = sut.defaultBuffer(for: .oneHour, context: .heartRate)
        let range = sut.allowedRange(for: .oneHour, context: .heartRate)
        #expect(range == 0...(base * 2.0))
    }

    /// When the default buffer is 0 (unmapped interval), the allowed range
    /// collapses to 0…0.
    @Test func allowedRange_zeroBaseProducesZeroRange() {
        let range = sut.allowedRange(for: .oneDay, context: .heartRate)
        #expect(range == 0...0)
    }
}

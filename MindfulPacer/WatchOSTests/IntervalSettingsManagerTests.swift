//
//  IntervalSettingsManagerTests.swift
//  WatchOSTests
//
//  Tests for `IntervalSettingsManager`, a singleton that maps each
//  `Reminder.Interval` enum case to its duration in seconds. These durations
//  define how long a measurement (heart rate or steps) must exceed a threshold
//  before an alert fires — e.g. "5 Minutes" → 300 seconds.
//

import Testing
import Foundation
@testable import WatchOS

@Suite("IntervalSettingsManager")
struct IntervalSettingsManagerTests {

    private let sut = IntervalSettingsManager.shared

    /// Each interval case must map to its expected duration in seconds.
    /// "Immediately" is 0 s; "1 Day" is 86 400 s (24 × 60 × 60).
    @Test(arguments: [
        (Reminder.Interval.immediately, 0.0),
        (.oneMinute, 60.0),
        (.twoMinutes, 120.0),
        (.fiveMinutes, 300.0),
        (.tenMinutes, 600.0),
        (.fifteenMinutes, 900.0),
        (.thirtyMinutes, 1800.0),
        (.oneHour, 3600.0),
        (.twoHours, 7200.0),
        (.fourHours, 14400.0),
        (.oneDay, 86400.0),
    ] as [(Reminder.Interval, TimeInterval)])
    func timeInterval_returnsExpectedValue(interval: Reminder.Interval, expected: TimeInterval) {
        #expect(sut.timeInterval(for: interval) == expected)
    }
}

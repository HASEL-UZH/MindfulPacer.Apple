//
//  CalendarExtensionsTests.swift
//  iOSTests
//
//  Tests for Calendar extensions used in the iOS app:
//  - `endOfDay(for:)` returns the last second of a given day (23:59:59),
//    used in analytics and date range calculations to create inclusive end bounds.
//  - `startOfNextDay(for:)` returns midnight of the following day, used by
//    the reflection-filtering system to build exclusive upper bounds for date ranges.
//

import Testing
import Foundation
@testable import iOS

// MARK: - EndOfDay Tests

/// Validates that `Calendar.endOfDay(for:)` consistently returns 23:59:59
/// of the same calendar day, regardless of what time the input falls on.
struct CalendarEndOfDayTests {

    private let calendar = Calendar.current

    /// When given the very start of a day (midnight), the end-of-day should
    /// still be 23:59:59 of that same day — not the next day.
    @Test func endOfDay_forMidnight_returnsSameDayAt235959() {
        let midnight = calendar.startOfDay(for: Date())
        let end = calendar.endOfDay(for: midnight)
        let components = calendar.dateComponents([.hour, .minute, .second], from: end)
        #expect(components.hour == 23)
        #expect(components.minute == 59)
        #expect(components.second == 59)
        #expect(calendar.isDate(midnight, inSameDayAs: end))
    }

    /// When given an arbitrary afternoon time, the result should still be
    /// 23:59:59 of that same day — the input time is irrelevant.
    @Test func endOfDay_forAfternoon_returnsSameDayAt235959() {
        let components = DateComponents(year: 2025, month: 6, day: 15, hour: 14, minute: 30)
        let afternoon = calendar.date(from: components)!
        let end = calendar.endOfDay(for: afternoon)
        let endComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: end)
        #expect(endComponents.year == 2025)
        #expect(endComponents.month == 6)
        #expect(endComponents.day == 15)
        #expect(endComponents.hour == 23)
        #expect(endComponents.minute == 59)
        #expect(endComponents.second == 59)
    }

    /// End-of-day for December 31 should still be Dec 31 at 23:59:59 — 
    /// the year boundary must not cause it to roll over.
    @Test func endOfDay_yearBoundary_staysInSameYear() {
        let dec31 = calendar.date(from: DateComponents(year: 2025, month: 12, day: 31))!
        let end = calendar.endOfDay(for: dec31)
        let components = calendar.dateComponents([.year, .month, .day], from: end)
        #expect(components.year == 2025)
        #expect(components.month == 12)
        #expect(components.day == 31)
    }
}

// MARK: - StartOfNextDay Tests

/// Validates that `Calendar.startOfNextDay(for:)` returns midnight (00:00:00)
/// of the following calendar day, used to build exclusive upper bounds in
/// date-range filters.
struct CalendarStartOfNextDayTests {

    private let calendar = Calendar.current

    /// Given a date on June 15, the start of the next day should be
    /// June 16 at exactly midnight.
    @Test func startOfNextDay_returnsNextDayAtMidnight() {
        let june15 = calendar.date(from: DateComponents(year: 2025, month: 6, day: 15, hour: 10))!
        let result = calendar.startOfNextDay(for: june15)
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: result)
        #expect(components.year == 2025)
        #expect(components.month == 6)
        #expect(components.day == 16)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    /// At a month boundary (Jan 31), the next day should correctly roll over
    /// to February 1 rather than producing an invalid date.
    @Test func startOfNextDay_monthBoundary_rollsOverToNextMonth() {
        let jan31 = calendar.date(from: DateComponents(year: 2025, month: 1, day: 31))!
        let result = calendar.startOfNextDay(for: jan31)
        let components = calendar.dateComponents([.year, .month, .day], from: result)
        #expect(components.month == 2)
        #expect(components.day == 1)
    }

    /// At a year boundary (Dec 31), the next day should roll over to
    /// January 1 of the following year.
    @Test func startOfNextDay_yearBoundary_rollsOverToNextYear() {
        let dec31 = calendar.date(from: DateComponents(year: 2025, month: 12, day: 31))!
        let result = calendar.startOfNextDay(for: dec31)
        let components = calendar.dateComponents([.year, .month, .day], from: result)
        #expect(components.year == 2026)
        #expect(components.month == 1)
        #expect(components.day == 1)
    }
}

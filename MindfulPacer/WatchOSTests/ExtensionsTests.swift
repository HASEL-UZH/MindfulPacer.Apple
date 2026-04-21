//
//  ExtensionsTests.swift
//  WatchOSTests
//
//  Tests for shared Swift extensions used across the app:
//    - `[Double].average` – arithmetic mean of a numeric array
//    - `Optional` helpers – `isNil`, `isNotNil`, `ifLet`, `whenSome`,
//      `whenNone`, `isNilOrEmpty`
//    - `Date.weekdayInt` – shorthand for the Gregorian weekday component
//    - `Double.toInt()` – truncating conversion to Int
//    - `Array[safe:]` – bounds-checked range subscript that returns nil
//      instead of crashing on out-of-bounds access
//

import Testing
import Foundation
@testable import WatchOS

// MARK: - Array<Double>.average

/// `average` computes the arithmetic mean of a `[Double]`. Used for computing
/// average heart rate from a window of samples.
@Suite("Array<Double>.average")
struct ArrayAverageTests {

    /// An empty array has no meaningful average, so the extension returns 0.
    @Test func average_ofEmptyArray_returnsZero() {
        let arr: [Double] = []
        #expect(arr.average == 0)
    }

    /// A single-element array returns that element as the average.
    @Test func average_ofSingleElement() {
        #expect([42.0].average == 42.0)
    }

    /// The mean of [10, 20, 30] is 20.
    @Test func average_ofMultipleElements() {
        #expect([10.0, 20.0, 30.0].average == 20.0)
    }
}

// MARK: - Optional extensions

/// Convenience helpers on `Optional` used throughout the codebase to reduce
/// boilerplate around nil-checking and conditional execution.
@Suite("Optional extensions")
struct OptionalExtensionsTests {

    /// `isNil` returns true when the optional has no value.
    @Test func isNil_whenNil_returnsTrue() {
        let value: Int? = nil
        #expect(value.isNil)
    }

    /// `isNil` returns false when the optional wraps a value.
    @Test func isNil_whenSome_returnsFalse() {
        let value: Int? = 5
        #expect(!value.isNil)
    }

    /// `isNotNil` is the inverse of `isNil` for readability.
    @Test func isNotNil_whenSome_returnsTrue() {
        let value: Int? = 5
        #expect(value.isNotNil)
    }

    @Test func isNotNil_whenNil_returnsFalse() {
        let value: Int? = nil
        #expect(!value.isNotNil)
    }

    /// `ifLet(then:else:)` runs the `then` closure when a value exists,
    /// passing the unwrapped value.
    @Test func ifLet_whenSome_callsThen() {
        let value: Int? = 10
        let result = value.ifLet(then: { "\($0)" }, else: { "none" })
        #expect(result == "10")
    }

    /// `ifLet(then:else:)` runs the `else` closure when the optional is nil.
    @Test func ifLet_whenNil_callsElse() {
        let value: Int? = nil
        let result = value.ifLet(then: { "\($0)" }, else: { "none" })
        #expect(result == "none")
    }

    /// `whenSome` executes a side-effecting closure only if a value exists.
    @Test func whenSome_executesBlock() {
        var called = false
        let value: Int? = 1
        value.whenSome { _ in called = true }
        #expect(called)
    }

    /// `whenSome` does nothing when the optional is nil.
    @Test func whenSome_doesNotExecuteForNil() {
        var called = false
        let value: Int? = nil
        value.whenSome { _ in called = true }
        #expect(!called)
    }

    /// `whenNone` executes a side-effecting closure only when the optional is nil.
    @Test func whenNone_executesBlockForNil() {
        var called = false
        let value: Int? = nil
        value.whenNone { called = true }
        #expect(called)
    }

    /// `whenNone` does nothing when the optional wraps a value.
    @Test func whenNone_doesNotExecuteForSome() {
        var called = false
        let value: Int? = 1
        value.whenNone { called = true }
        #expect(!called)
    }

    /// `isNilOrEmpty` returns true when the optional collection is nil.
    @Test func isNilOrEmpty_nilCollection_returnsTrue() {
        let value: [Int]? = nil
        #expect(value.isNilOrEmpty)
    }

    /// `isNilOrEmpty` returns true when the collection exists but is empty.
    @Test func isNilOrEmpty_emptyCollection_returnsTrue() {
        let value: [Int]? = []
        #expect(value.isNilOrEmpty)
    }

    /// `isNilOrEmpty` returns false when the collection has at least one element.
    @Test func isNilOrEmpty_nonEmptyCollection_returnsFalse() {
        let value: [Int]? = [1]
        #expect(!value.isNilOrEmpty)
    }
}

// MARK: - Date.weekdayInt

/// `weekdayInt` returns the Gregorian weekday component (1 = Sunday … 7 = Saturday)
/// for a given date. Used when filtering or grouping data by day of week.
@Suite("Date.weekdayInt")
struct DateWeekdayIntTests {

    /// Verify the extension matches `Calendar.current.component(.weekday, …)`.
    @Test func weekdayInt_returnsCorrectComponent() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: 2026, month: 3, day: 28)
        let date = calendar.date(from: components)!
        #expect(date.weekdayInt == Calendar.current.component(.weekday, from: date))
    }
}

// MARK: - Double.toInt

/// `toInt()` truncates the decimal part and converts a Double to Int. Used in
/// the view model when converting heart-rate BPM and step counts for display.
@Suite("Double.toInt")
struct DoubleToIntTests {

    /// 3.7 truncates to 3 (rounds toward zero).
    @Test func toInt_truncates() {
        #expect(3.7.toInt() == 3)
    }

    /// 0.0 converts to 0.
    @Test func toInt_zero() {
        #expect(0.0.toInt() == 0)
    }

    /// Negative values also truncate toward zero: -2.9 → -2.
    @Test func toInt_negative() {
        #expect((-2.9).toInt() == -2)
    }
}

// MARK: - Array safe subscript

/// `Array[safe:]` returns an optional slice. If the requested range falls within
/// bounds, it returns the slice; otherwise it returns nil. This is used in the
/// chart downsampling logic to safely bucket heart-rate samples.
@Suite("Array safe subscript")
struct ArraySafeSubscriptTests {

    /// A range fully within bounds returns the expected slice.
    @Test func safeRange_validRange_returnsSlice() {
        let arr = [1, 2, 3, 4, 5]
        let slice = arr[safe: 1..<3]
        #expect(slice != nil)
        #expect(Array(slice!) == [2, 3])
    }

    /// A range that extends past the end of the array returns nil instead of crashing.
    @Test func safeRange_outOfBounds_returnsNil() {
        let arr = [1, 2, 3]
        #expect(arr[safe: 2..<5] == nil)
    }

    /// An empty range (start == end) within bounds returns an empty, non-nil slice.
    @Test func safeRange_emptyRange_returnsEmptySlice() {
        let arr = [1, 2, 3]
        let slice = arr[safe: 1..<1]
        #expect(slice != nil)
        #expect(Array(slice!).isEmpty)
    }
}

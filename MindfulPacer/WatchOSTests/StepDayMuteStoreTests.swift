//
//  StepDayMuteStoreTests.swift
//  WatchOSTests
//
//  Tests for `StepDayMuteStore`, a lightweight store that suppresses repeated
//  daily step-count notifications. When the user responds to a "1 Day" step
//  alert, the app calls `muteForToday()` so no further daily step alerts fire
//  until the next calendar day. The store persists a timestamp in UserDefaults
//  and checks whether that timestamp falls on the current day.
//

import Testing
import Foundation
@testable import WatchOS

/// Tests run serially because they share a single UserDefaults key.
@Suite(.serialized)
struct StepDayMuteStoreTests {

    /// Dedicated UserDefaults suite so tests don't touch the real app group store.
    private static let suiteName = "com.mindfulpacer.tests.StepDayMuteStore"
    /// Must match the private key inside `StepDayMuteStore`.
    private static let key = "com.mindfulpacer.mute.steps.oneday.lastResponse"
    private let store = UserDefaults(suiteName: StepDayMuteStoreTests.suiteName)!

    /// Clears the stored timestamp before every test to guarantee a clean slate.
    init() {
        store.removeObject(forKey: StepDayMuteStoreTests.key)
    }

    // MARK: - isMutedToday

    /// When no mute has ever been recorded, the store should report "not muted".
    @Test func isMutedToday_returnsFalseWhenNothingStored() {
        #expect(!StepDayMuteStore.isMutedToday(store: store))
    }

    /// After calling `muteForToday`, querying the same moment should return true.
    @Test func isMutedToday_returnsTrueAfterMutingForToday() {
        let now = Date()
        StepDayMuteStore.muteForToday(now: now, store: store)
        #expect(StepDayMuteStore.isMutedToday(now: now, store: store))
    }

    /// A mute recorded yesterday must not carry over into today.
    @Test func isMutedToday_returnsFalseForDifferentDay() {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        StepDayMuteStore.muteForToday(now: yesterday, store: store)
        #expect(!StepDayMuteStore.isMutedToday(now: today, store: store))
    }

    /// A mute recorded in the morning should still be active in the evening of
    /// the same calendar day (using UTC to avoid timezone edge-case flakiness).
    @Test func isMutedToday_returnsTrueForSameDayDifferentTime() {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        let evening = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!

        StepDayMuteStore.muteForToday(now: morning, store: store)
        #expect(StepDayMuteStore.isMutedToday(now: evening, calendar: calendar, store: store))
    }

    // MARK: - muteForToday

    /// Verifies the raw value written to UserDefaults is the Unix timestamp of
    /// the date passed to `muteForToday`.
    @Test func muteForToday_storesTimestamp() {
        let now = Date()
        StepDayMuteStore.muteForToday(now: now, store: store)

        let stored = store.object(forKey: StepDayMuteStoreTests.key) as? TimeInterval
        #expect(stored == now.timeIntervalSince1970)
    }

    /// Calling `muteForToday` a second time overwrites the previous timestamp,
    /// so the mute now applies to the new day and no longer to the old one.
    @Test func muteForToday_overwritesPreviousValue() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let today = Date()

        StepDayMuteStore.muteForToday(now: yesterday, store: store)
        StepDayMuteStore.muteForToday(now: today, store: store)

        #expect(StepDayMuteStore.isMutedToday(now: today, store: store))
        #expect(!StepDayMuteStore.isMutedToday(now: yesterday, store: store))
    }
}

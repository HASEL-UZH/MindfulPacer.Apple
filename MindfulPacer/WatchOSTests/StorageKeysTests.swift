//
//  StorageKeysTests.swift
//  WatchOSTests
//
//  Tests for `StorageKeys`, a namespace of UserDefaults keys used across the
//  watchOS app. The most important function is `bufferKey(for:type:)`, which
//  builds a unique key per (interval, measurement type) pair so each reminder's
//  custom buffer cooldown is stored independently.
//

import Testing
import Foundation
@testable import WatchOS

@Suite("StorageKeys")
struct StorageKeysTests {

    /// The buffer key for heart-rate / 1-hour encodes both the measurement type
    /// raw value ("Heart Rate") and the interval raw value ("1 Hour").
    @Test func bufferKey_heartRate_oneHour() {
        let key = StorageKeys.bufferKey(for: .oneHour, type: .heartRate)
        #expect(key == "buffer_Heart Rate_1 Hour")
    }

    /// The buffer key for steps / 30-minutes uses the respective raw values.
    @Test func bufferKey_steps_thirtyMinutes() {
        let key = StorageKeys.bufferKey(for: .thirtyMinutes, type: .steps)
        #expect(key == "buffer_Steps_30 Minutes")
    }

    /// Different (interval, type) combinations must produce distinct keys to
    /// avoid one reminder's buffer overriding another's.
    @Test func bufferKey_uniqueForDifferentCombinations() {
        let key1 = StorageKeys.bufferKey(for: .oneHour, type: .heartRate)
        let key2 = StorageKeys.bufferKey(for: .oneHour, type: .steps)
        let key3 = StorageKeys.bufferKey(for: .thirtyMinutes, type: .heartRate)
        #expect(key1 != key2)
        #expect(key1 != key3)
        #expect(key2 != key3)
    }

    /// All static key constants used for alert counts, notification ledger, and
    /// trigger data cache must be non-empty strings.
    @Test func staticKeys_areNonEmpty() {
        #expect(!StorageKeys.strongAlertCount.isEmpty)
        #expect(!StorageKeys.mediumAlertCount.isEmpty)
        #expect(!StorageKeys.lightAlertCount.isEmpty)
        #expect(!StorageKeys.lastAlertDate.isEmpty)
        #expect(!StorageKeys.pendingNotificationsKey.isEmpty)
        #expect(!StorageKeys.alertCacheKey.isEmpty)
    }
}

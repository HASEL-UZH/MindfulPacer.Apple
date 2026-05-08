//
//  ModeOfUseAndDeviceModeTests.swift
//  iOSTests
//
//  Tests for `ModeOfUse` and `DeviceMode`, two enums that configure how the
//  app operates:
//  - `ModeOfUse`: "Essentials" (simplified UI) vs "Expanded" (all features).
//    Determines whether the user sees the full symptom tracking interface.
//  - `DeviceMode`: "iPhone + Apple Watch" vs "iPhone Only". Determines whether
//    the app expects a paired watch for health data collection or relies on
//    manual input only.
//
//  Both are persisted in UserDefaults via AppStorage keys.
//

import Testing
import Foundation
@testable import iOS

// MARK: - ModeOfUse

/// Validates `ModeOfUse` enum properties used in the onboarding flow and
/// settings screen where the user selects their preferred app complexity level.
struct ModeOfUseTests {

    /// The `name` computed property should return the capitalized raw value.
    @Test func name_isCapitalizedRawValue() {
        #expect(ModeOfUse.expanded.name == "Expanded")
        #expect(ModeOfUse.essentials.name == "Essentials")
    }

    /// Each mode should have a non-empty localized display string.
    @Test func localized_allCases_nonEmpty() {
        for mode in ModeOfUse.allCases {
            #expect(!mode.localized.isEmpty)
        }
    }

    /// Each mode should have a non-empty description explaining what it does.
    @Test func description_allCases_nonEmpty() {
        for mode in ModeOfUse.allCases {
            #expect(!mode.description.isEmpty)
        }
    }

    /// Each mode should have an icon asset name for the mode selection UI.
    @Test func icon_allCases_nonEmpty() {
        for mode in ModeOfUse.allCases {
            #expect(!mode.icon.isEmpty)
        }
    }

    /// The AppStorage key should be stable across versions.
    @Test func appStorageKey_isStable() {
        #expect(ModeOfUse.appStorageKey == "modeOfUse")
    }

    /// There should be exactly two modes.
    @Test func allCases_count() {
        #expect(ModeOfUse.allCases.count == 2)
    }
}

// MARK: - DeviceMode

/// Validates `DeviceMode` enum properties used in the onboarding flow and
/// settings screen where the user selects their device configuration.
struct DeviceModeTests {

    /// Each device mode should have a non-empty localized display string.
    @Test func localized_allCases_nonEmpty() {
        for mode in DeviceMode.allCases {
            #expect(!mode.localized.isEmpty)
        }
    }

    /// Each mode should have an SF Symbol icon name.
    @Test func icon_allCases_nonEmpty() {
        for mode in DeviceMode.allCases {
            #expect(!mode.icon.isEmpty)
        }
    }

    /// Each mode should have a description explaining the implications.
    @Test func description_allCases_nonEmpty() {
        for mode in DeviceMode.allCases {
            #expect(!mode.description.isEmpty)
        }
    }

    /// The AppStorage key should be stable.
    @Test func appStorageKey_isStable() {
        #expect(DeviceMode.appStorageKey == "deviceMode")
    }

    /// There should be exactly two device modes.
    @Test func allCases_count() {
        #expect(DeviceMode.allCases.count == 2)
    }
}

// MARK: - DeviceMode.current(from:)

/// Validates `DeviceMode.current(from:)`, which reads the user's device mode
/// preference from UserDefaults with a fallback to `.iPhoneAndWatch`.
/// This is the factory method used to initialize the device mode at app launch.
@Suite(.serialized)
struct DeviceModeCurrentTests {

    /// A dedicated UserDefaults suite to avoid interfering with the real app.
    private let testDefaults = UserDefaults(suiteName: "com.mindfulpacer.tests.DeviceMode")!

    init() {
        testDefaults.removeObject(forKey: DeviceMode.appStorageKey)
    }

    /// When no value is stored, the default should be `.iPhoneAndWatch`
    /// (the most feature-rich configuration).
    @Test func current_noStoredValue_defaultsToIPhoneAndWatch() {
        testDefaults.removeObject(forKey: DeviceMode.appStorageKey)
        let mode = DeviceMode.current(from: testDefaults)
        #expect(mode == .iPhoneAndWatch)
    }

    /// When "iPhoneOnly" is stored, it should return `.iPhoneOnly`.
    @Test func current_storedIPhoneOnly_returnsIPhoneOnly() {
        testDefaults.set(DeviceMode.iPhoneOnly.rawValue, forKey: DeviceMode.appStorageKey)
        let mode = DeviceMode.current(from: testDefaults)
        #expect(mode == .iPhoneOnly)
    }

    /// When "iPhoneAndWatch" is stored, it should return `.iPhoneAndWatch`.
    @Test func current_storedIPhoneAndWatch_returnsIPhoneAndWatch() {
        testDefaults.set(DeviceMode.iPhoneAndWatch.rawValue, forKey: DeviceMode.appStorageKey)
        let mode = DeviceMode.current(from: testDefaults)
        #expect(mode == .iPhoneAndWatch)
    }

    /// When an invalid/corrupted string is stored, it should fall back to
    /// `.iPhoneAndWatch` rather than crashing.
    @Test func current_invalidStoredValue_defaultsToIPhoneAndWatch() {
        testDefaults.set("garbage", forKey: DeviceMode.appStorageKey)
        let mode = DeviceMode.current(from: testDefaults)
        #expect(mode == .iPhoneAndWatch)
    }
}

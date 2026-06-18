//
//  StatusMessageTests.swift
//  WatchOSTests
//
//  Tests for `StatusMessage`, an enum that represents the current monitoring
//  state shown in the watchOS home screen. Each case maps to:
//    - a `symbolName` (SF Symbol used in the status icon),
//    - a `color` (tint color for the icon), and
//    - a `description` (explanatory text shown to the user).
//

import Testing
import SwiftUI
@testable import WatchOS

@Suite("StatusMessage")
struct StatusMessageTests {

    // MARK: - symbolName
    //
    // Each status maps to an SF Symbol that gives the user an at-a-glance
    // visual indicator of the monitoring state.

    /// Active monitoring shows a checkmark.
    @Test func symbolName_monitoring() {
        #expect(StatusMessage.monitoring.symbolName == "checkmark")
    }

    /// Inactive monitoring shows an X mark.
    @Test func symbolName_notMonitoring() {
        #expect(StatusMessage.notMonitoring.symbolName == "xmark")
    }

    /// No configured reminders shows a slashed bell.
    @Test func symbolName_noReminders() {
        #expect(StatusMessage.noReminders.symbolName == "bell.slash")
    }

    /// Denied HealthKit permissions shows a slashed lock.
    @Test func symbolName_permissionDenied() {
        #expect(StatusMessage.permissionDenied.symbolName == "lock.slash")
    }

    /// An unexpected error shows a warning triangle.
    @Test func symbolName_error() {
        #expect(StatusMessage.error.symbolName == "exclamationmark.triangle")
    }

    /// Syncing reminders from iCloud shows a circular arrow.
    @Test func symbolName_syncing() {
        #expect(StatusMessage.syncing.symbolName == "arrow.triangle.2.circlepath.circle")
    }

    /// Manually paused monitoring shows a pause icon.
    @Test func symbolName_paused() {
        #expect(StatusMessage.paused.symbolName == "pause")
    }

    // MARK: - color
    //
    // Colors provide quick visual feedback: green = good, red = problem,
    // gray = neutral, yellow/orange = attention needed, cyan = transient.

    @Test func color_monitoring() {
        #expect(StatusMessage.monitoring.color == .green)
    }

    @Test func color_notMonitoring() {
        #expect(StatusMessage.notMonitoring.color == .red)
    }

    @Test func color_noReminders() {
        #expect(StatusMessage.noReminders.color == .gray)
    }

    @Test func color_permissionDenied() {
        #expect(StatusMessage.permissionDenied.color == .red)
    }

    @Test func color_error() {
        #expect(StatusMessage.error.color == .orange)
    }

    @Test func color_syncing() {
        #expect(StatusMessage.syncing.color == .cyan)
    }

    @Test func color_paused() {
        #expect(StatusMessage.paused.color == .yellow)
    }

    // MARK: - rawValue & description

    /// Every status case must have a non-empty raw value (displayed as a title)
    /// and a non-empty description (shown when the user taps for more info).
    @Test func rawValue_allCasesAreNonEmpty() {
        let allCases: [StatusMessage] = [.monitoring, .notMonitoring, .noReminders, .permissionDenied, .error, .syncing, .paused]
        for status in allCases {
            #expect(!status.rawValue.isEmpty)
            #expect(!status.description.isEmpty)
        }
    }
}

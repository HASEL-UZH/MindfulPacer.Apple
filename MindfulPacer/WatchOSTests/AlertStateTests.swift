//
//  AlertStateTests.swift
//  WatchOSTests
//
//  Tests for alert-related types:
//
//  - `AlertState` – an enum that tracks whether an in-app alert overlay is
//    currently visible (`.showing`) or dismissed (`.none`). Custom `Equatable`
//    conformance compares by rule ID and alert ID.
//
//  - `AlertRule` – a value type that describes a single monitoring rule derived
//    from a `Reminder`. It carries the measurement type, threshold, interval,
//    and mutable runtime state (trigger dates, notification cooldown).
//
//  - `RuleType` – distinguishes heart-rate rules from step-count rules, each
//    carrying their own threshold value.
//
//  - `PendingNotification` – a Codable record of a sent notification, used to
//    track which alerts were delivered and when.
//

import Testing
import Foundation
@testable import WatchOS

@Suite("AlertState")
struct AlertStateTests {

    /// Helper that creates a minimal heart-rate AlertRule for testing.
    private func makeRule(id: UUID = UUID()) -> AlertRule {
        AlertRule(
            id: id,
            measurementType: .heartRate,
            reminderType: .light,
            ruleType: .heartRate(threshold: 100),
            duration: 60,
            alertMessage: "Test",
            interval: .oneMinute
        )
    }

    /// Two `.none` values are equal (no alert showing in either case).
    @Test func equality_noneEqualsNone() {
        #expect(AlertState.none == AlertState.none)
    }

    /// `.showing` is equal when both the rule and alert ID match.
    @Test func equality_showingWithSameValues() {
        let id = UUID()
        let rule = makeRule()
        #expect(AlertState.showing(rule: rule, alertID: id) == AlertState.showing(rule: rule, alertID: id))
    }

    /// Different alert IDs make two `.showing` states unequal, even if the
    /// rule is the same. Each alert firing gets a unique alert ID.
    @Test func equality_showingWithDifferentAlertIDs() {
        let rule = makeRule()
        #expect(AlertState.showing(rule: rule, alertID: UUID()) != AlertState.showing(rule: rule, alertID: UUID()))
    }

    /// Different rule IDs make two `.showing` states unequal.
    @Test func equality_showingWithDifferentRuleIDs() {
        let alertID = UUID()
        let rule1 = makeRule(id: UUID())
        let rule2 = makeRule(id: UUID())
        #expect(AlertState.showing(rule: rule1, alertID: alertID) != AlertState.showing(rule: rule2, alertID: alertID))
    }

    /// `.none` is never equal to any `.showing` state.
    @Test func equality_noneNotEqualToShowing() {
        let rule = makeRule()
        #expect(AlertState.none != AlertState.showing(rule: rule, alertID: UUID()))
    }
}

// MARK: - AlertRule

/// `AlertRule` holds both the configuration of a monitoring rule (derived from
/// the user's `Reminder`) and its mutable runtime state used during evaluation.
@Suite("AlertRule")
struct AlertRuleTests {

    /// Verify all configuration properties are stored correctly after init.
    @Test func alertRule_identifiable() {
        let id = UUID()
        let rule = AlertRule(
            id: id,
            measurementType: .steps,
            reminderType: .strong,
            ruleType: .steps(threshold: 500),
            duration: 3600,
            alertMessage: "Steps alert",
            interval: .oneHour
        )
        #expect(rule.id == id)
        #expect(rule.measurementType == .steps)
        #expect(rule.reminderType == .strong)
        #expect(rule.duration == 3600)
        #expect(rule.alertMessage == "Steps alert")
        #expect(rule.interval == .oneHour)
    }

    /// Runtime state properties (`triggerDate`, `dipDate`, `lastNotificationDate`,
    /// `notificationSent`, `alertID`) all default to nil/false on creation.
    @Test func alertRule_defaultRuntimeState() {
        let rule = AlertRule(
            id: UUID(),
            measurementType: .heartRate,
            reminderType: .medium,
            ruleType: .heartRate(threshold: 120),
            duration: 300,
            alertMessage: "HR alert",
            interval: .fiveMinutes
        )
        #expect(rule.triggerDate == nil)
        #expect(rule.dipDate == nil)
        #expect(rule.lastNotificationDate == nil)
        #expect(rule.notificationSent == false)
        #expect(rule.alertID == nil)
    }

    /// `RuleType` equality: same type and threshold → equal; different threshold
    /// or different type → not equal. This matters when rebuilding rules from
    /// updated reminders to detect if a rule actually changed.
    @Test func ruleType_equality() {
        #expect(RuleType.heartRate(threshold: 100) == RuleType.heartRate(threshold: 100))
        #expect(RuleType.heartRate(threshold: 100) != RuleType.heartRate(threshold: 120))
        #expect(RuleType.steps(threshold: 500) == RuleType.steps(threshold: 500))
        #expect(RuleType.steps(threshold: 500) != RuleType.steps(threshold: 600))
        #expect(RuleType.heartRate(threshold: 100) != RuleType.steps(threshold: 100))
    }
}

// MARK: - PendingNotification

/// `PendingNotification` records that a notification was sent. It is Codable so
/// it can be persisted in UserDefaults as a ledger of recent alerts.
@Suite("PendingNotification")
struct PendingNotificationTests {

    /// The `id` computed property must return the `alertID`, since each
    /// notification is uniquely identified by its alert ID.
    @Test func id_matchesAlertID() {
        let alertID = UUID()
        let pending = PendingNotification(alertID: alertID, reminderID: UUID(), sentDate: Date())
        #expect(pending.id == alertID)
    }

    /// Encoding to JSON and decoding back must preserve the alert and reminder IDs.
    @Test func codable_roundTrip() throws {
        let original = PendingNotification(alertID: UUID(), reminderID: UUID(), sentDate: Date())
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PendingNotification.self, from: data)
        #expect(decoded.alertID == original.alertID)
        #expect(decoded.reminderID == original.reminderID)
    }
}

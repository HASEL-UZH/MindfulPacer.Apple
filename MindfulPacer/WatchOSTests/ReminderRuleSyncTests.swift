//
//  ReminderRuleSyncTests.swift
//  WatchOSTests
//
//  Tests for `AlertRule.currentRules(in:)`, which turns the reminders in the
//  store into the rules the Watch monitors. The Watch reads the store on every
//  refresh, so a reminder that is created, edited or deleted on the iPhone must
//  be reflected the next time the rules are read, without relaunching the app.
//

import Testing
import Foundation
import SwiftData
@testable import WatchOS

@MainActor
@Suite("Reminder rule sync")
struct ReminderRuleSyncTests {

    /// An isolated in-memory store per test.
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(CurrentScheme.models)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// A rule copies the reminder's configuration.
    @Test func ruleMirrorsReminder() {
        let reminder = Reminder(measurementType: .steps, reminderType: .strong, threshold: 5000, interval: .oneDay)
        let rule = AlertRule(reminder: reminder)

        #expect(rule.id == reminder.id)
        #expect(rule.measurementType == .steps)
        #expect(rule.reminderType == .strong)
        #expect(rule.ruleType == .steps(threshold: 5000))
        #expect(rule.interval == .oneDay)
        #expect(rule.duration == Reminder.Interval.oneDay.timeInterval)
        #expect(rule.alertID == nil)
    }

    /// A deleted reminder is gone the next time the rules are read.
    @Test func deletedReminderDisappears() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let kept = Reminder(measurementType: .heartRate, reminderType: .medium, threshold: 110, interval: .fiveMinutes)
        let deleted = Reminder(measurementType: .heartRate, reminderType: .light, threshold: 80, interval: .fiveMinutes)
        context.insert(kept)
        context.insert(deleted)
        try context.save()
        #expect(try AlertRule.currentRules(in: context).count == 2)

        context.delete(deleted)
        try context.save()

        let rules = try AlertRule.currentRules(in: context)
        #expect(rules.map(\.id) == [kept.id])
    }

    /// An edited reminder is read back with its new values.
    @Test func editedReminderIsReadBack() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let reminder = Reminder(measurementType: .heartRate, reminderType: .light, threshold: 80, interval: .fiveMinutes)
        context.insert(reminder)
        try context.save()

        reminder.threshold = 95
        reminder.reminderType = .strong
        try context.save()

        let rule = try #require(try AlertRule.currentRules(in: context).first)
        #expect(rule.ruleType == .heartRate(threshold: 95))
        #expect(rule.reminderType == .strong)
    }

    /// A newly created reminder appears without any other change.
    @Test func newReminderAppears() throws {
        let container = try makeContainer()
        let context = container.mainContext
        #expect(try AlertRule.currentRules(in: context).isEmpty)

        context.insert(Reminder(measurementType: .steps, reminderType: .medium, threshold: 10000, interval: .oneDay))
        try context.save()

        #expect(try AlertRule.currentRules(in: context).count == 1)
    }

    /// Heart rate comes first, and each measurement is ordered by descending threshold.
    @Test func rulesAreOrderedForDisplay() throws {
        let container = try makeContainer()
        let context = container.mainContext
        context.insert(Reminder(measurementType: .steps, reminderType: .light, threshold: 5000, interval: .oneDay))
        context.insert(Reminder(measurementType: .heartRate, reminderType: .light, threshold: 80, interval: .fiveMinutes))
        context.insert(Reminder(measurementType: .steps, reminderType: .strong, threshold: 10000, interval: .oneDay))
        context.insert(Reminder(measurementType: .heartRate, reminderType: .strong, threshold: 120, interval: .fiveMinutes))
        try context.save()

        let rules = try AlertRule.currentRules(in: context)
        #expect(rules.map(\.measurementType) == [.heartRate, .heartRate, .steps, .steps])
        #expect(rules.map(\.ruleType) == [
            .heartRate(threshold: 120), .heartRate(threshold: 80),
            .steps(threshold: 10000), .steps(threshold: 5000)
        ])
    }
}

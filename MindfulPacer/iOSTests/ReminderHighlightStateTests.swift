import Foundation
import Testing
@testable import iOS

struct ReminderHighlightStateTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    private func rule(_ measurement: Reminder.MeasurementType, _ severity: Reminder.ReminderType,
                      threshold: Double = 100, id: UUID = UUID(),
                      interval: Reminder.Interval? = nil) -> ReminderHighlightState.Rule {
        .init(id: id, measurement: measurement, severity: severity, threshold: threshold,
              interval: interval ?? (measurement == .steps ? .thirtyMinutes : .oneMinute))
    }

    private var utc: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test func stepsAreHighlightedWhileTheCountIsAboveTheThreshold() {
        var state = ReminderHighlightState()
        let reminder = rule(.steps, .light, threshold: 500)
        state.updateSteps(500, for: reminder, at: start)
        #expect(state.severity(for: .steps, at: start) == nil, "Reaching the threshold is not passing it.")
        state.updateSteps(501, for: reminder, at: start)
        #expect(state.severity(for: .steps, at: start) == .light, "No notification is needed.")
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(600)) == .light)
        state.updateSteps(480, for: reminder, at: start.addingTimeInterval(900))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(900)) == nil)
    }

    @Test func oneDayStepsStayHighlightedUntilMidnight() {
        var state = ReminderHighlightState()
        // 1 January 2026, 09:00 UTC
        let morning = Date(timeIntervalSince1970: 1_767_258_000)
        let midnight = Date(timeIntervalSince1970: 1_767_312_000)
        let reminder = rule(.steps, .strong, threshold: 5_000, interval: .oneDay)
        state.updateSteps(10_709, for: reminder, at: morning, calendar: utc)
        #expect(state.severity(for: .steps, at: morning.addingTimeInterval(60)) == .strong)
        #expect(state.severity(for: .steps, at: midnight.addingTimeInterval(-1)) == .strong)
        #expect(state.nextExpiration == midnight)
        #expect(state.severity(for: .steps, at: midnight) == nil, "A new day starts at zero steps.")
    }

    @Test func stepsHighlightEndsOneIntervalAfterTheLastCount() {
        var state = ReminderHighlightState()
        state.recordTrigger(for: rule(.steps, .light, threshold: 500), at: start)
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(1_799)) == .light)
        #expect(state.nextExpiration == start.addingTimeInterval(1_800))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(1_800)) == nil)
        state.expireSteps(at: start.addingTimeInterval(1_900))
        #expect(state.nextExpiration == nil)
    }

    @Test func stepCountsDoNotTouchHeartRateHighlights() {
        var state = ReminderHighlightState()
        let heart = rule(.heartRate, .strong)
        state.updateSteps(1_000, for: heart, at: start)
        #expect(state.severity(for: .heartRate, at: start) == nil)
        state.recordTrigger(for: heart, at: start)
        state.updateSteps(0, for: heart, at: start)
        #expect(state.severity(for: .heartRate, at: start) == .strong)
    }

    @Test func heartRateRequiresTriggerAndClearsImmediatelyAtThreshold() {
        var state = ReminderHighlightState()
        state.updateHeartRate(120)
        #expect(state.severity(for: .heartRate, at: start) == nil)
        state.recordTrigger(for: rule(.heartRate, .strong), at: start)
        state.updateHeartRate(101)
        state.expireSteps(at: start.addingTimeInterval(3_600))
        #expect(state.severity(for: .heartRate, at: start.addingTimeInterval(3_600)) == .strong)
        state.updateHeartRate(100)
        #expect(state.severity(for: .heartRate, at: start) == nil)
        state.updateHeartRate(120)
        #expect(state.severity(for: .heartRate, at: start) == nil, "Must trigger again after a dip.")
    }

    @Test func strongestActiveHeartRateReminderWinsUntilItsOwnThresholdClears() {
        var state = ReminderHighlightState()
        state.recordTrigger(for: rule(.heartRate, .strong, threshold: 120), at: start)
        state.recordTrigger(for: rule(.heartRate, .light, threshold: 90), at: start)
        state.recordTrigger(for: rule(.heartRate, .medium, threshold: 100), at: start)
        #expect(state.severity(for: .heartRate, at: start) == .strong)
        state.updateHeartRate(115)
        #expect(state.severity(for: .heartRate, at: start) == .medium)
        state.updateHeartRate(100)
        #expect(state.severity(for: .heartRate, at: start) == .light)
        state.updateHeartRate(89)
        #expect(state.severity(for: .heartRate, at: start) == nil)
    }

    @Test func strongestPassedStepsReminderWinsUntilItsOwnCountDrops() {
        var state = ReminderHighlightState()
        let light = rule(.steps, .light, threshold: 5_000)
        let strong = rule(.steps, .strong, threshold: 10_000)
        state.updateSteps(7_000, for: light, at: start)
        state.updateSteps(7_000, for: strong, at: start)
        #expect(state.severity(for: .steps, at: start) == .light)
        state.updateSteps(10_709, for: light, at: start.addingTimeInterval(300))
        state.updateSteps(10_709, for: strong, at: start.addingTimeInterval(300))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(300)) == .strong)
        state.updateSteps(9_000, for: strong, at: start.addingTimeInterval(600))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(600)) == .light)
    }

    @Test func metricsAreIndependentAndRuleChangesDiscardStaleHighlights() {
        var state = ReminderHighlightState()
        let heart = rule(.heartRate, .strong)
        let steps = rule(.steps, .light)
        state.recordTrigger(for: heart, at: start)
        state.recordTrigger(for: steps, at: start)
        state.updateHeartRate(80)
        #expect(state.severity(for: .steps, at: start) == .light)
        state.recordTrigger(for: heart, at: start)
        state.retainRules([rule(.heartRate, .strong, threshold: 110, id: heart.id), steps])
        #expect(state.severity(for: .heartRate, at: start) == nil)
        #expect(state.severity(for: .steps, at: start) == .light)
        state.retainRules([])
        #expect(state.severity(for: .steps, at: start) == nil)
    }

    @Test func invalidHeartRateClearsHighlight() {
        var state = ReminderHighlightState()
        state.recordTrigger(for: rule(.heartRate, .strong), at: start)
        state.updateHeartRate(.nan)
        #expect(state.severity(for: .heartRate, at: start) == nil)
    }
}

import Foundation
import Testing
@testable import iOS

struct ReminderHighlightStateTests {
    private let start = Date(timeIntervalSince1970: 1_000)

    private func rule(_ measurement: Reminder.MeasurementType, _ severity: Reminder.ReminderType,
                      threshold: Double = 100, id: UUID = UUID()) -> ReminderHighlightState.Rule {
        .init(id: id, measurement: measurement, severity: severity, threshold: threshold,
              interval: measurement == .steps ? .thirtyMinutes : .oneMinute)
    }

    @Test func stepsExpireExactlyOneMinuteAfterTriggerWithoutMoreSamples() {
        var state = ReminderHighlightState()
        state.recordTrigger(for: rule(.steps, .light, threshold: 500), at: start)
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(59)) == .light)
        #expect(state.nextExpiration == start.addingTimeInterval(60))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(60)) == nil)
        state.expireSteps(at: start.addingTimeInterval(90))
        #expect(state.nextExpiration == nil)
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

    @Test func overlappingStepsHaveIndependentExpiryAndCanRetrigger() {
        var state = ReminderHighlightState()
        let light = rule(.steps, .light)
        state.recordTrigger(for: rule(.steps, .strong), at: start)
        state.recordTrigger(for: light, at: start.addingTimeInterval(30))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(45)) == .strong)
        state.expireSteps(at: start.addingTimeInterval(60))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(60)) == .light)
        state.recordTrigger(for: light, at: start.addingTimeInterval(80))
        state.expireSteps(at: start.addingTimeInterval(90))
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(139)) == .light)
        #expect(state.severity(for: .steps, at: start.addingTimeInterval(140)) == nil)
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

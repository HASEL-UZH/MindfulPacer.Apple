import Foundation

/// Presentation state starts only when the monitoring engine actually triggers a reminder.
/// It is independent of notification dismissal and the engine's cooldown/dip grace period.
struct ReminderHighlightState: Equatable {
    struct Rule: Equatable {
        let id: UUID
        let measurement: Reminder.MeasurementType
        let severity: Reminder.ReminderType
        let threshold: Double
        let interval: Reminder.Interval
    }

    private struct Highlight: Equatable {
        let rule: Rule
        let expiresAt: Date?
    }

    private var highlights: [UUID: Highlight] = [:]

    mutating func recordTrigger(for rule: Rule, at date: Date) {
        highlights[rule.id] = Highlight(
            rule: rule,
            expiresAt: rule.measurement == .steps ? date.addingTimeInterval(60) : nil
        )
        expireSteps(at: date)
    }

    mutating func updateHeartRate(_ value: Double) {
        highlights = highlights.filter { _, highlight in
            highlight.rule.measurement != .heartRate || (value.isFinite && value > highlight.rule.threshold)
        }
    }

    mutating func expireSteps(at date: Date) {
        highlights = highlights.filter { $0.value.expiresAt.map { $0 > date } ?? true }
    }

    mutating func retainRules(_ rules: [Rule]) {
        highlights = highlights.filter { rules.contains($0.value.rule) }
    }

    var nextExpiration: Date? { highlights.values.compactMap(\.expiresAt).min() }

    func severity(for measurement: Reminder.MeasurementType, at date: Date) -> Reminder.ReminderType? {
        let active = highlights.values.filter {
            $0.rule.measurement == measurement && ($0.expiresAt.map { $0 > date } ?? true)
        }.map(\.rule.severity)
        return [.strong, .medium, .light].first { active.contains($0) }
    }
}

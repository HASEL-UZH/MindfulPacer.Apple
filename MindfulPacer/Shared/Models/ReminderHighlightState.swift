import Foundation

/// Which reminders the Watch shows as exceeded.
///
/// Heart rate: the highlight starts when the monitoring engine triggers the reminder and ends as soon as
/// the heart rate is back at or below the threshold. It is independent of notification dismissal and the
/// engine's cooldown/dip grace period.
///
/// Steps: the highlight follows the steps counted in the reminder's interval. A passed threshold stays
/// highlighted for as long as the count is above it, whether or not a notification was sent.
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
        /// When a steps highlight ends unless a newer count confirms it.
        let expiresAt: Date?
    }

    private var highlights: [UUID: Highlight] = [:]

    mutating func recordTrigger(for rule: Rule, at date: Date, calendar: Calendar = .current) {
        highlights[rule.id] = Highlight(
            rule: rule,
            expiresAt: Self.stepsExpiration(for: rule, countedAt: date, calendar: calendar)
        )
        expireSteps(at: date)
    }

    mutating func updateHeartRate(_ value: Double) {
        highlights = highlights.filter { _, highlight in
            highlight.rule.measurement != .heartRate || (value.isFinite && value > highlight.rule.threshold)
        }
    }

    /// Highlights a steps reminder while the steps counted in its interval exceed the threshold.
    mutating func updateSteps(_ total: Double, for rule: Rule, at date: Date, calendar: Calendar = .current) {
        guard rule.measurement == .steps else { return }
        if total.isFinite, total > rule.threshold {
            highlights[rule.id] = Highlight(
                rule: rule,
                expiresAt: Self.stepsExpiration(for: rule, countedAt: date, calendar: calendar)
            )
        } else {
            highlights[rule.id] = nil
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

    /// The latest moment a count can still justify the highlight: a one-day reminder counts from midnight,
    /// so its steps stay in the interval until the day ends. Any other reminder counts the last interval,
    /// so the counted steps have all left it one interval later.
    private static func stepsExpiration(for rule: Rule, countedAt date: Date, calendar: Calendar) -> Date? {
        guard rule.measurement == .steps else { return nil }
        if rule.interval == .oneDay {
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))
        }
        return date.addingTimeInterval(rule.interval.timeInterval)
    }
}

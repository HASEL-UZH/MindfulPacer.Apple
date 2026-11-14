import SwiftUI

/// A weekly journal overview, with no targets or completion scores.
struct HomeReflectionHistoryView: View {
    let reflections: [Reflection]

    private var days: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let now = Date.now
        let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            return (date, reflections.filter { calendar.isDate($0.date, inSameDayAs: date) && $0.date <= now }.count)
        }
    }

    var body: some View {
        let week = days
        let maximum = max(1, week.map(\.count).max() ?? 0)
        let total = week.reduce(0) { $0 + $1.count }
        LabeledCard(contentSpacing: 12) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(week, id: \.date) { day in
                    VStack(spacing: 4) {
                        if day.count > 0 {
                            Text(day.count, format: .number)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.secondary)
                        }
                        UnevenRoundedRectangle(topLeadingRadius: 6, topTrailingRadius: 6)
                            .fill(day.count == 0 ? Color.brandPrimary.opacity(0.12).gradient : Color.brandPrimary.gradient)
                            .frame(height: day.count == 0 ? 4 : max(10, 44 * CGFloat(day.count) / CGFloat(maximum)))
                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(.caption.weight(Calendar.current.isDateInToday(day.date) ? .bold : .regular))
                            .foregroundStyle(Calendar.current.isDateInToday(day.date) ? Color.brandPrimary : Color.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide).month().day()))
                    .accessibilityValue(Text("\(day.count) reflections"))
                }
            }
        } label: {
            Label("This Week", systemImage: "calendar")
                .foregroundStyle(Color.accentColor)
        } accessory: {
            Text(total, format: .number)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(Color.primary)
                .accessibilityLabel(Text("\(total) reflections"))
        }
        .accessibilityIdentifier("home.reflections.overview")
    }
}

struct HomeReminderOverviewView: View {
    let reminders: [Reminder]

    var body: some View {
        LabeledCard(contentSpacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 24) { measurementCounts }
                VStack(alignment: .leading, spacing: 8) { measurementCounts }
            }
        } label: {
            Label("Active Reminders", systemImage: "checkmark.circle.fill")
                .foregroundStyle(Color.accentColor)
        } accessory: {
            Text(reminders.count, format: .number)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(Color.primary)
                .accessibilityLabel(Text("\(reminders.count) active"))
        }
        .accessibilityIdentifier("home.reminders.overview")
    }

    private var measurementCounts: some View {
        Group {
            Label("\(reminders.filter { $0.measurementType == .heartRate }.count) heart rate", systemImage: "heart.fill")
                .foregroundStyle(.pink)
            Label("\(reminders.filter { $0.measurementType == .steps }.count) steps", systemImage: "figure.walk")
                .foregroundStyle(.cyan)
        }
        .font(.subheadline.weight(.medium))
    }
}

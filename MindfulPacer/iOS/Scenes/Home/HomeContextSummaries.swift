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
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 2) {
                Text("This Week").font(.subheadline).foregroundStyle(Color.secondary)
                Text(week.reduce(0) { $0 + $1.count }, format: .number)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Reflections").font(.headline).foregroundStyle(.brandPrimary)
            }
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(week, id: \.date) { day in
                    VStack(spacing: 8) {
                        Text(day.count, format: .number)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Color.secondary)
                        UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)
                            .fill(day.count == 0 ? Color.brandPrimary.opacity(0.12).gradient : Color.brandPrimary.gradient)
                            .frame(height: day.count == 0 ? 4 : max(12, 110 * CGFloat(day.count) / CGFloat(maximum)))
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
            .frame(height: week.allSatisfy { $0.count == 0 } ? 80 : 150, alignment: .bottom)
        }
        .padding(16)
        .accessibilityIdentifier("home.reflections.overview")
    }
}

struct HomeReminderOverviewView: View {
    let reminders: [Reminder]

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.06))
                Circle().strokeBorder(Color.accentColor.opacity(0.12), lineWidth: 1).padding(12)
                Image(systemName: reminders.isEmpty ? "bell" : "bell.badge.fill")
                    .font(.system(size: 72, weight: .light))
                    .foregroundStyle(Color.accentColor.gradient)
            }
            .frame(width: 180, height: 180)
            .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(reminders.count, format: .number)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("Active Reminders").font(.headline).foregroundStyle(Color.secondary)
            }
            if !reminders.isEmpty {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) { measurementCounts }
                    VStack(alignment: .leading, spacing: 12) { measurementCounts }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
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

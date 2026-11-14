import Testing
import Foundation
@testable import iOS

struct StatChartScaleTests {
    @Test func sharedHeartRateScaleKeepsMinimumIndependentOfReminderLines() {
        let domain = HeartRateChartScale.domain(values: [78, 85, 110], thresholds: [40, 130])
        #expect(domain.lowerBound == 68)
        #expect(domain.upperBound > 130)
        #expect(HeartRateChartScale.domain(values: [72, 72]).lowerBound == 62)
        #expect(HeartRateChartScale.domain(values: [.nan, .infinity, 0]) == 50...104.8)
    }

    @Test @MainActor func missedReflectionHeartRateUsesSampleMinimum() throws {
        let reflection = Reflection(
            wellBeing: nil, fatigue: nil, shortnessOfBreath: nil, sleepDisorder: nil,
            cognitiveImpairment: nil, physicalPain: nil, depressionOrAnxiety: nil,
            measurementType: .heartRate, reminderType: .strong, threshold: 100, interval: .oneMinute,
            triggerSamples: [112, 125, 118].enumerated().map {
                .init(type: .heartRate, value: Double($0.element),
                      date: Date(timeIntervalSince1970: Double($0.offset * 30)))
            }
        )
        let data = try #require(MissedReflectionTrendCard.Data(reflection: reflection))
        #expect(data.yDomain.lowerBound == 102)
        #expect(data.valueRules.isEmpty, "Don't draw an out-of-range threshold at a false value.")
    }

    @Test func heartRateStartsTenBelowVisibleMinimum() {
        let configuration = StatChartConfiguration(
            markStyle: .area(), unitLabel: "bpm", minimumValuePadding: 10
        )
        let domain = configuration.yScaleDomain(for: [68, 72, 110])
        #expect(domain.lowerBound == 58)
        #expect(domain.upperBound > 110)
    }

    @Test func constantHeartRateStillHasUsableScale() {
        let configuration = StatChartConfiguration(
            markStyle: .area(), unitLabel: "bpm", minimumValuePadding: 10
        )
        let domain = configuration.yScaleDomain(for: [72, 72])
        #expect(domain.lowerBound == 62)
        #expect(domain.upperBound > 72)
    }

    @Test func stepsBarsKeepZeroBaseline() {
        let configuration = StatChartConfiguration(markStyle: .bar(), unitLabel: "steps")
        #expect(configuration.yScaleDomain(for: [500, 1200]).lowerBound == 0)
    }

    @Test func missingAndInvalidDataHaveFiniteFallback() {
        let configuration = StatChartConfiguration(unitLabel: "bpm")
        #expect(configuration.yScaleDomain(for: []) == 0...1)
        #expect(configuration.yScaleDomain(for: [.nan, .infinity]) == 0...1)
    }
    @Test func axisTicksRemainBoundedAndCoverVisibleWindows() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Zurich"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 9, day: 24, hour: 14, minute: 7)))
        for (period, duration): (StatChartPeriod, TimeInterval) in [
            (.oneHour, 3_600), (.twoHours, 7_200), (.day, 86_400), (.week, 7 * 86_400),
            (.month, 31 * 86_400), (.sixMonths, 183 * 86_400), (.year, 366 * 86_400)
        ] {
            let ticks = StatChartAxisDates.visibleTicks(start: start, duration: duration, period: period, calendar: calendar)
            #expect(ticks.count <= 10)
            #expect(try #require(ticks.first) <= start)
            #expect(try #require(ticks.last) >= start.addingTimeInterval(duration))
            #expect(zip(ticks, ticks.dropFirst()).allSatisfy { $0 < $1 })
        }
    }

    @Test func dayTicksFollowCalendarAcrossDaylightSavingChange() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Zurich"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24)))
        let ticks = StatChartAxisDates.visibleTicks(start: start, duration: 7 * 86_400, period: .week, calendar: calendar)
        #expect(ticks.allSatisfy { calendar.component(.hour, from: $0) == 0 })
        #expect(zip(ticks, ticks.dropFirst()).contains { $1.timeIntervalSince($0) == 25 * 3_600 })
    }

}

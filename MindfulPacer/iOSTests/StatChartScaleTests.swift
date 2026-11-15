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

    @Test func heartRateScaleCanIncludeThresholdsBelowTheData() {
        #expect(HeartRateChartScale.domain(values: [135, 160], thresholds: [120]).lowerBound == 125)
        let domain = HeartRateChartScale.domain(values: [135, 160], thresholds: [120], includesLowThresholds: true)
        #expect(domain.lowerBound == 110)
        #expect(domain.upperBound > 160)
        #expect(HeartRateChartScale.domain(values: [78, 85, 110], thresholds: [130], includesLowThresholds: true)
            == HeartRateChartScale.domain(values: [78, 85, 110], thresholds: [130]))
        #expect(HeartRateChartScale.domain(values: [], thresholds: [40], includesLowThresholds: true).contains(40))
    }

    @Test @MainActor func missedReflectionHeartRateKeepsThresholdBelowSamplesVisible() throws {
        let reflection = Reflection(
            date: Date(timeIntervalSince1970: 240),
            wellBeing: nil, fatigue: nil, shortnessOfBreath: nil, sleepDisorder: nil,
            cognitiveImpairment: nil, physicalPain: nil, depressionOrAnxiety: nil,
            measurementType: .heartRate, reminderType: .strong, threshold: 120, interval: .fiveMinutes,
            triggerSamples: [154, 160, 148, 135, 141].enumerated().map {
                .init(type: .heartRate, value: Double($0.element),
                      date: Date(timeIntervalSince1970: Double($0.offset * 60)))
            }
        )
        let data = try #require(MissedReflectionTrendCard.Data(reflection: reflection))
        #expect(data.yDomain.lowerBound == 110)
        #expect(data.yDomain.upperBound > 160)
        #expect(data.valueRules.map(\.value) == [120], "The threshold line is drawn at its true value.")
        #expect(data.shadedRegions.map(\.yRange.lowerBound) == [120])
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

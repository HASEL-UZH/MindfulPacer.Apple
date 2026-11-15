import SwiftUI
import Charts

struct HeartRateChartView: View {
    let viewModel: HomeViewModel

    var body: some View {
        WatchPage {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.hasHeartRateData {
                    WatchChartSummary(label: "AVERAGE · LAST HOUR", value: viewModel.avgHeartRate,
                                      unit: "BPM", color: .pink)
                    Chart {
                        ForEach(viewModel.downsampledHeartRateSamples, id: \.date) { sample in
                            LineMark(x: .value("Time", sample.date), y: .value("BPM", sample.value))
                                .foregroundStyle(.pink)
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            if viewModel.heartRateSamples.count == 1 {
                                PointMark(x: .value("Time", sample.date), y: .value("BPM", sample.value))
                                    .foregroundStyle(.pink)
                                    .symbolSize(24)
                            }
                        }
                        ForEach(viewModel.heartRateThresholdRules) { rule in
                            if case .heartRate(let threshold) = rule.ruleType,
                               viewModel.heartRateChartYDomain.contains(threshold) {
                                RuleMark(y: .value("Threshold", threshold))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                                    .foregroundStyle(rule.reminderType.color.opacity(0.8))
                                    .accessibilityLabel(rule.reminderType.localized)
                                    .accessibilityValue("\(Int(threshold)) BPM")
                            }
                        }
                    }
                    .chartYScale(domain: viewModel.heartRateChartYDomain)
                    .chartXScale(domain: viewModel.heartRateChartDateRange)
                    .watchChartAxes(in: viewModel.heartRateChartDateRange)
                    .accessibilityLabel("Heart rate during the last hour")
                    HStack(alignment: .firstTextBaseline) {
                        Text("Range").foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        Text("\(viewModel.minHeartRate)–\(viewModel.maxHeartRate) BPM")
                            .monospacedDigit()
                    }
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                } else {
                    let state = viewModel.emptyState(for: .heartRate)
                    WatchEmptyState(title: state.title, symbol: state.symbol, message: state.subtitle)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("watch.heartRateChart")
    }
}

struct WatchChartSummary: View {
    let label: LocalizedStringKey
    let value: Int
    let unit: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                // One line, so a longer translation cannot make the page taller than the screen.
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value, format: .number)
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(unit).font(.caption2).foregroundStyle(color)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct WatchChartAxes: ViewModifier {
    let dateRange: ClosedRange<Date>
    @Environment(\.watchPageScrolls) private var pageScrolls

    func body(content: Content) -> some View {
        content
            .chartXAxis {
                AxisMarks(values: [dateRange.lowerBound, dateRange.upperBound]) { value in
                    if let date = value.as(Date.self) {
                        AxisValueLabel(anchor: date == dateRange.lowerBound ? .topLeading : .topTrailing) {
                            Text(date, format: .dateTime.hour().minute())
                                .font(.system(size: 9))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) {
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                    AxisValueLabel().font(.system(size: 9))
                }
            }
            // The chart takes the height the page has left, so the page always fits the screen.
            // On a page that scrolls it keeps a fixed height.
            .frame(minHeight: 44, idealHeight: pageScrolls ? 72 : 44, maxHeight: pageScrolls ? 72 : .infinity)
    }
}

extension View {
    func watchChartAxes(in dateRange: ClosedRange<Date>) -> some View {
        modifier(WatchChartAxes(dateRange: dateRange))
    }
}

#Preview {
    NavigationStack {
        HeartRateChartView(viewModel: .mock).navigationTitle("Heart Rate")
    }
}

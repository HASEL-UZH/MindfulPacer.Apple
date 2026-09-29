import SwiftUI
import Charts

struct StepsChartView: View {
    let viewModel: HomeViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.hasStepsData {
                    WatchChartSummary(label: "TOTAL · LAST HOUR", value: Int(viewModel.hourlyStepData.last?.steps ?? 0),
                                      unit: "steps", color: .cyan)
                    Chart {
                        ForEach(viewModel.hourlyStepData, id: \.date) { sample in
                            LineMark(x: .value("Time", sample.date), y: .value("Steps", sample.steps))
                                .foregroundStyle(.cyan)
                                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                            if viewModel.hourlyStepData.count == 1 {
                                PointMark(x: .value("Time", sample.date), y: .value("Steps", sample.steps))
                                    .foregroundStyle(.cyan)
                                    .symbolSize(24)
                            }
                        }
                    }
                    .chartYScale(domain: viewModel.stepsChartYDomain)
                    .chartXScale(domain: viewModel.stepsChartDateRange)
                    .watchChartAxes(in: viewModel.stepsChartDateRange)
                    .accessibilityLabel("Cumulative steps during the last hour")
                    HStack(alignment: .firstTextBaseline) {
                        Text("Today").foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        Text("\(viewModel.todaysSteps.formatted()) steps").monospacedDigit()
                    }
                    .font(.caption2)
                } else {
                    let state = viewModel.emptyState(for: .steps)
                    WatchEmptyState(title: state.title, symbol: state.symbol, message: state.subtitle)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 4)
        }
        .accessibilityIdentifier("watch.stepsChart")
    }
}

#Preview {
    NavigationStack {
        StepsChartView(viewModel: .mock).navigationTitle("Steps")
    }
}

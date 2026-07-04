//
//  MissedReflectionsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import Charts
import SwiftUI

// MARK: - MissedReflectionsListView

extension HomeView {
    struct MissedReflectionsListView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: HomeViewModel
        
        // MARK: Body
        
        var body: some View {
            if viewModel.missedReflections.isEmpty {
                emptyState
            } else {
                missedReflectionsList
            }
        }
        
        // MARK: Action Buttons
        @ViewBuilder
        private func actionButtons(for reflection: Reflection) -> some View {
            HStack(spacing: 16) {
                Spacer()
                
                Button {
                    withAnimation {
                        viewModel.rejectMissedReflection(reflection: reflection)
                    }
                } label: {
                    Label("Reject", systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        viewModel.acceptMissedReflection(reflection: reflection)
                    }
                } label: {
                    Label("Accept", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.capsule)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        
        // MARK: Missed Reflections List
        
        private var missedReflectionsList: some View {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.displayedMissedReflections, id: \.id) { reflection in
                        MissedReflectionHealthCard(reflection: reflection) {
                            actionButtons(for: reflection)
                        }
                        .padding(.horizontal)
                    }

                    if viewModel.isFetchingMissedReflections {
                        ProgressView()
                            .padding(.vertical, 12)
                    }

                    if !viewModel.displayedMissedReflections.isEmpty {
                        Text("\(viewModel.displayedMissedReflections.count) of \(viewModel.missedReflections.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 8)
                    }
                }
                
                if viewModel.canLoadMoreMissed && !viewModel.isFetchingMissedReflections {
                    HStack {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                viewModel.loadMoreMissed()
                            }
                        } label: {
                            Label("Load More", systemImage: "arrow.down.circle.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("BrandPrimary"))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Missed Reflections")
        }

        // MARK: Empty State
        
        private var emptyState: some View {
            ContentUnavailableView {
                Label("No Missed Reflections", systemImage: "square.stack.fill")
            } description: {
                Text("You do not have any missed reflections.")
            }
            .navigationTitle("Missed Reflections")
        }
    }
}

// MARK: - MissedReflectionHealthCard

private struct MissedReflectionHealthCard<Actions: View>: View {
    let reflection: Reflection
    @ViewBuilder let actions: () -> Actions

    private var chartData: MissedReflectionHealthChartData {
        MissedReflectionHealthChartData(reflection: reflection)
    }

    var body: some View {
        LabeledCard(
            contentSpacing: 18,
            contentPadding: 18,
            cornerRadius: 24
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text(reflection.reminderTriggerSummary)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Divider()

                metricSummary

                if chartData.samples.isEmpty {
                    Text("No trigger data was saved for this reflection.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 150, alignment: .center)
                } else {
                    MissedReflectionHealthChart(data: chartData)
                        .frame(height: 190)
                }

                Text(String(localized: "Triggered on \(reflection.date.formatted(.dateTime.month().day().hour().minute()))"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Divider()

                actions()
            }
        } label: {
            Label {
                Text(chartData.measurementTitle)
            } icon: {
                Image(systemName: chartData.measurementIcon)
            }
            .foregroundStyle(chartData.tint)
        } accessory: {
            if let reminderType = reflection.reminderType {
                Image(systemName: "alarm")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(reminderType.color)
                    .frame(width: 30, height: 30)
                    .background(reminderType.color.opacity(0.12), in: Circle())
            }
        }
    }

    private var metricSummary: some View {
        HStack(alignment: .top, spacing: 16) {
            metricColumn(
                title: "At trigger",
                value: chartData.triggerValueText,
                unit: chartData.unit,
                color: chartData.tint
            )

            metricColumn(
                title: "Threshold",
                value: chartData.thresholdText,
                unit: chartData.unit,
                color: .secondary
            )
        }
    }

    private func metricColumn(
        title: String,
        value: String,
        unit: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            } icon: {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
            .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(unit)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MissedReflectionHealthChart

private struct MissedReflectionHealthChart: View {
    let data: MissedReflectionHealthChartData

    var body: some View {
        VStack(spacing: 2) {
            Chart {
                if let triggerWindowRange = data.visibleTriggerWindowRange {
                    RectangleMark(
                        xStart: .value("Trigger Window Start", triggerWindowRange.lowerBound),
                        xEnd: .value("Trigger Window End", triggerWindowRange.upperBound),
                        yStart: .value("Threshold", data.clampedThreshold),
                        yEnd: .value("Peak", data.valueRange.upperBound)
                    )
                    .foregroundStyle(data.tint.opacity(0.08))
                }

                RuleMark(y: .value("Threshold", data.clampedThreshold))
                    .foregroundStyle(Color(.systemGray3))
                    .lineStyle(.init(lineWidth: 1.5, dash: [4, 4]))

                ForEach(data.thresholdExceededSamples) { sample in
                    AreaMark(
                        x: .value("Time", sample.date),
                        yStart: .value("Threshold", data.clampedThreshold),
                        yEnd: .value("Above Threshold", data.clampedValue(sample.value))
                    )
                    .foregroundStyle(data.tint.opacity(0.18))
                    .interpolationMethod(.monotone)
                }

                ForEach(data.samples) { sample in
                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value(data.measurementTitle, data.clampedValue(sample.value))
                    )
                    .foregroundStyle(data.tint)
                    .lineStyle(.init(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.monotone)
                }

                if let triggerSample = data.triggerSample {
                    RuleMark(x: .value("Triggered", data.clampedTriggerDate))
                        .foregroundStyle(Color(.systemGray3))
                        .lineStyle(.init(lineWidth: 2))

                    PointMark(
                        x: .value("Triggered", data.clampedTriggerDate),
                        y: .value(data.measurementTitle, data.clampedValue(triggerSample.value))
                    )
                    .foregroundStyle(data.tint)
                    .symbolSize(56)
                }
            }
            .chartXScale(domain: data.xRange)
            .chartYScale(domain: data.valueRange)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
            .chartPlotStyle { plotArea in
                plotArea
                    .background(.clear)
                    .clipped()
            }

            timeLabels
        }
        .accessibilityLabel("\(data.measurementTitle) missed reflection trigger chart")
        .accessibilityValue("\(data.triggerValueText) \(data.unit), threshold \(data.thresholdText) \(data.unit)")
    }

    private var timeLabels: some View {
        HStack(spacing: 8) {
            Text(data.startTimeText)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(data.triggerTimeText)
                .frame(maxWidth: .infinity, alignment: .center)

            Text(data.endTimeText)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 2)
    }
}

// MARK: - MissedReflectionHealthChartData

private struct MissedReflectionHealthChartData {
    let reflection: Reflection
    let rawSamples: [MeasurementSample]
    let samples: [MissedReflectionHealthSample]
    let triggerWindowStart: Date?

    private var measurementType: Reminder.MeasurementType? {
        reflection.measurementType ?? rawSamples.first?.type
    }

    private var isSteps: Bool {
        measurementType == .steps
    }

    var measurementTitle: String {
        measurementType?.localized ?? String(localized: "Measurement")
    }

    var measurementIcon: String {
        measurementType?.icon ?? "waveform.path.ecg"
    }

    var unit: String {
        switch measurementType {
        case .heartRate:
            String(localized: "bpm")
        case .steps:
            String(localized: "steps")
        case nil:
            ""
        }
    }

    var tint: Color {
        measurementType?.color ?? Color("BrandPrimary")
    }

    var threshold: Double {
        Double(reflection.threshold ?? 0)
    }

    var triggerDate: Date {
        reflection.date
    }

    var clampedTriggerDate: Date {
        clampedDate(triggerDate)
    }

    var triggerSample: MissedReflectionHealthSample? {
        samples.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(triggerDate)) < abs(rhs.date.timeIntervalSince(triggerDate))
        }
    }

    var triggerValueText: String {
        guard let triggerSample else { return "--" }
        return formattedValue(triggerSample.value)
    }

    var thresholdText: String {
        guard reflection.threshold != nil else { return "--" }
        return formattedValue(threshold)
    }

    var thresholdExceededSamples: [MissedReflectionHealthSample] {
        samples.filter { sample in
            let isInWindow = triggerWindowStart.map { sample.date >= $0 } ?? true
            return isInWindow &&
            sample.date <= triggerDate &&
            sample.value >= threshold
        }
    }

    var visibleTriggerWindowRange: ClosedRange<Date>? {
        guard let triggerWindowStart else { return nil }

        let lowerBound = clampedDate(triggerWindowStart)
        let upperBound = clampedTriggerDate
        guard lowerBound < upperBound else { return nil }

        return lowerBound...upperBound
    }

    var xRange: ClosedRange<Date> {
        let visibleRange = unpaddedXRange
        let visibleSpan = max(visibleRange.upperBound.timeIntervalSince(visibleRange.lowerBound), 60)
        let intervalSpan = reflection.interval?.timeInterval ?? visibleSpan
        let minimumPadding: TimeInterval = axisTimeStyleShowsSeconds ? 20 : 60
        let maximumPadding = max(minimumPadding, intervalSpan * 0.25)
        let leadingPadding = min(max(minimumPadding, visibleSpan * 0.08), maximumPadding)
        let trailingPadding = min(max(minimumPadding * 2, visibleSpan * 0.24), maximumPadding)

        let lowerBound = visibleRange.lowerBound.addingTimeInterval(-leadingPadding)
        let upperBound = visibleRange.upperBound.addingTimeInterval(trailingPadding)
        return lowerBound...upperBound
    }

    private var unpaddedXRange: ClosedRange<Date> {
        guard let first = samples.first?.date, let last = samples.last?.date else {
            return triggerDate.addingTimeInterval(-60)...triggerDate.addingTimeInterval(60)
        }

        let lowerBound = min(first, triggerWindowStart ?? first, triggerDate)
        let upperBound = max(last, triggerDate)

        guard lowerBound < upperBound else {
            return lowerBound.addingTimeInterval(-60)...upperBound.addingTimeInterval(60)
        }

        if first == last {
            return first.addingTimeInterval(-60)...last.addingTimeInterval(60)
        }

        return lowerBound...upperBound
    }

    var valueRange: ClosedRange<Double> {
        let values = samples.map(\.value) + [threshold]
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let padding = max(8, (maxValue - minValue) * 0.18)
        return max(0, minValue - padding)...(maxValue + padding)
    }

    var clampedThreshold: Double {
        clampedValue(threshold)
    }

    var startTimeText: String {
        xRange.lowerBound.formatted(axisTimeStyle)
    }

    var triggerTimeText: String {
        triggerDate.formatted(axisTimeStyle)
    }

    var endTimeText: String {
        xRange.upperBound.formatted(axisTimeStyle)
    }

    init(reflection: Reflection) {
        self.reflection = reflection
        let sorted = reflection.triggerSamples.sorted { $0.date < $1.date }
        self.rawSamples = sorted
        self.samples = Self.chartSeries(from: sorted, reflection: reflection)
        self.triggerWindowStart = Self.triggerWindowStart(for: reflection)
    }

    private var axisTimeStyle: Date.FormatStyle {
        guard let interval = reflection.interval else { return .dateTime.hour().minute().second() }
        switch interval {
        case .immediately, .oneMinute, .twoMinutes:
            return .dateTime.hour().minute().second()
        case .fiveMinutes, .tenMinutes,
             .fifteenMinutes, .thirtyMinutes,
             .oneHour, .twoHours:
            return .dateTime.hour().minute()
        case .fourHours, .oneDay:
            return .dateTime.hour()
        }
    }

    private var axisTimeStyleShowsSeconds: Bool {
        guard let interval = reflection.interval else { return true }
        switch interval {
        case .immediately, .oneMinute, .twoMinutes:
            return true
        case .fiveMinutes, .tenMinutes,
             .fifteenMinutes, .thirtyMinutes,
             .oneHour, .twoHours,
             .fourHours, .oneDay:
            return false
        }
    }

    private func formattedValue(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(0)))
    }

    func clampedDate(_ date: Date) -> Date {
        min(max(date, xRange.lowerBound), xRange.upperBound)
    }

    func clampedValue(_ value: Double) -> Double {
        min(max(value, valueRange.lowerBound), valueRange.upperBound)
    }

    private static func chartSeries(
        from samples: [MeasurementSample],
        reflection: Reflection
    ) -> [MissedReflectionHealthSample] {
        guard !samples.isEmpty else { return [] }

        let series: [MeasurementSample]
        if samples.first?.type == .steps {
            if reflection.interval == .oneDay {
                series = runningTotalSeries(samples)
            } else {
                series = rollingSumSeries(samples, window: reflection.interval?.timeInterval ?? 0)
            }
        } else {
            series = samples
        }

        return downsample(series, to: 200).map { sample in
            MissedReflectionHealthSample(date: sample.date, value: sample.value)
        }
    }

    private static func triggerWindowStart(for reflection: Reflection) -> Date? {
        guard let seconds = reflection.interval?.timeInterval else { return nil }
        return reflection.date.addingTimeInterval(-seconds)
    }

    private static func rollingSumSeries(
        _ data: [MeasurementSample],
        window: TimeInterval
    ) -> [MeasurementSample] {
        guard window > 0 else { return data }
        var output: [MeasurementSample] = []
        var queue: [(Date, Double)] = []
        var sum: Double = 0
        output.reserveCapacity(data.count)

        for sample in data {
            sum += sample.value
            queue.append((sample.date, sample.value))
            let cutoff = sample.date.addingTimeInterval(-window)

            while let first = queue.first, first.0 < cutoff {
                sum -= first.1
                queue.removeFirst()
            }

            output.append(.init(type: sample.type, value: sum, date: sample.date))
        }

        return output
    }

    private static func runningTotalSeries(_ data: [MeasurementSample]) -> [MeasurementSample] {
        var total: Double = 0

        return data.map { sample in
            total += sample.value
            return .init(type: sample.type, value: total, date: sample.date)
        }
    }

    private static func downsample(
        _ data: [MeasurementSample],
        to maxPoints: Int
    ) -> [MeasurementSample] {
        guard data.count > maxPoints else { return data }
        var output: [MeasurementSample] = []
        output.reserveCapacity(maxPoints)
        let bucketSize = Double(data.count) / Double(maxPoints)

        for index in 0..<maxPoints {
            let start = Int(Double(index) * bucketSize)
            let end = min(Int(Double(index + 1) * bucketSize), data.count)

            if start < end,
               let sample = data[start..<end].max(by: { $0.value < $1.value }) {
                output.append(sample)
            }
        }

        return output
    }
}

private struct MissedReflectionHealthSample: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.MissedReflectionsListView(viewModel: viewModel)
}

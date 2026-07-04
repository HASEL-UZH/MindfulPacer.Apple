//
//  MissedReflectionTrendCard.swift
//  iOS
//
//  Created by Codex on 04.07.2026.
//

import Charts
import SwiftUI

// MARK: - MissedReflectionTrendCard

struct MissedReflectionTrendCard: View {
    enum PresentationStyle {
        case card
        case listSection
    }

    let data: Data
    private let presentationStyle: PresentationStyle
    private let accessory: AnyView
    private let footer: AnyView
    @State private var selectedSample: Sample?

    init<Accessory: View, Footer: View>(
        data: Data,
        presentationStyle: PresentationStyle = .card,
        @ViewBuilder accessory: () -> Accessory,
        @ViewBuilder footer: () -> Footer
    ) {
        self.data = data
        self.presentationStyle = presentationStyle
        self.accessory = AnyView(accessory())
        self.footer = AnyView(footer())
    }

    init<Footer: View>(
        data: Data,
        presentationStyle: PresentationStyle = .card,
        @ViewBuilder footer: () -> Footer
    ) {
        self.data = data
        self.presentationStyle = presentationStyle
        self.accessory = AnyView(EmptyView())
        self.footer = AnyView(footer())
    }

    init<Accessory: View>(
        data: Data,
        presentationStyle: PresentationStyle = .card,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.data = data
        self.presentationStyle = presentationStyle
        self.accessory = AnyView(accessory())
        self.footer = AnyView(EmptyView())
    }

    init(
        data: Data,
        presentationStyle: PresentationStyle = .card
    ) {
        self.data = data
        self.presentationStyle = presentationStyle
        self.accessory = AnyView(EmptyView())
        self.footer = AnyView(EmptyView())
    }

    var body: some View {
        switch presentationStyle {
        case .card:
            cardBody
        case .listSection:
            sectionBody
        }
    }

    private var cardBody: some View {
        LabeledCard(
            contentSpacing: data.layout.contentSpacing,
            contentPadding: data.layout.contentPadding,
            cornerRadius: data.layout.cornerRadius
        ) {
            VStack(alignment: .leading, spacing: data.layout.verticalSpacing) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(data.headline)
                        .font(data.layout.headlineFont)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle = data.subtitle {
                        Text(subtitle)
                            .font(data.layout.subtitleFont)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Divider()

                MissedReflectionTrendSummaryRow(
                    current: selectedCurrentSummary,
                    comparison: data.comparisonSummary,
                    layout: data.layout
                )

                MissedReflectionTrendChart(data: data, selectedSample: $selectedSample)
                    .frame(height: data.chartHeight)

                footer
            }
        } label: {
            Label {
                Text(data.title)
            } icon: {
                Image(systemName: data.systemImage)
            }
            .foregroundStyle(data.tint)
        } accessory: {
            accessory
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(data.accessibilityLabel)
    }

    private var sectionBody: some View {
        VStack(alignment: .leading, spacing: data.layout.contentSpacing) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Label {
                    Text(data.title)
                } icon: {
                    Image(systemName: data.systemImage)
                }
                .foregroundStyle(data.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
                .labelIconToTitleSpacing(4)
                .font(.subheadline.weight(.semibold))

                accessory
            }

            cardContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(data.accessibilityLabel)
    }

    @ViewBuilder
    private var cardContent: some View {
        VStack(alignment: .leading, spacing: data.layout.verticalSpacing) {
            VStack(alignment: .leading, spacing: 6) {
                Text(data.headline)
                    .font(data.layout.headlineFont)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = data.subtitle {
                    Text(subtitle)
                        .font(data.layout.subtitleFont)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            MissedReflectionTrendSummaryRow(
                current: selectedCurrentSummary,
                comparison: data.comparisonSummary,
                layout: data.layout
            )

            MissedReflectionTrendChart(data: data, selectedSample: $selectedSample)
                .frame(height: data.chartHeight)

            footer
        }
    }

    private var selectedCurrentSummary: Summary {
        guard let selectedSample else { return data.currentSummary }

        return .init(
            label: String(localized: "At \(selectedSample.date.formatted(.dateTime.hour().minute()))"),
            value: selectedSample.valueText,
            unit: data.currentSummary.unit,
            color: data.currentSummary.color
        )
    }
}

// MARK: - MissedReflectionTrendCard.Data

extension MissedReflectionTrendCard {
    struct Data {
        let title: String
        let systemImage: String
        let headline: String
        let subtitle: String?
        let currentSummary: Summary
        let comparisonSummary: Summary
        let currentSamples: [Sample]
        let comparisonSamples: [Sample]
        let valueRules: [ValueRule]
        let shadedRegions: [ShadedRegion]
        let areaFills: [AreaFill]
        let markerDate: Date
        let xDomain: ClosedRange<Date>
        let yDomain: ClosedRange<Double>
        let tint: Color
        let comparisonColor: Color
        let currentLineStyle: StrokeStyle
        let comparisonLineStyle: StrokeStyle
        let fadesComparisonAfterMarker: Bool
        let showsMarkerRule: Bool
        let showsMarkerSymbols: Bool
        let emptyChartText: String?
        let layout: Layout
        let chartHeight: CGFloat

        init(
            title: String,
            systemImage: String,
            headline: String,
            subtitle: String? = nil,
            currentSummary: Summary,
            comparisonSummary: Summary,
            currentSamples: [Sample],
            comparisonSamples: [Sample],
            valueRules: [ValueRule] = [],
            shadedRegions: [ShadedRegion] = [],
            areaFills: [AreaFill] = [],
            markerDate: Date,
            xDomain: ClosedRange<Date>? = nil,
            yDomain: ClosedRange<Double>? = nil,
            tint: Color,
            comparisonColor: Color = Color(.systemGray),
            currentLineStyle: StrokeStyle = .init(lineWidth: 4, lineCap: .round, lineJoin: .round),
            comparisonLineStyle: StrokeStyle = .init(lineWidth: 4, lineCap: .round, lineJoin: .round),
            fadesComparisonAfterMarker: Bool = true,
            showsMarkerRule: Bool = true,
            showsMarkerSymbols: Bool = true,
            emptyChartText: String? = nil,
            layout: Layout = .regular,
            chartHeight: CGFloat = 286
        ) {
            let sortedCurrentSamples = currentSamples.sorted { $0.date < $1.date }
            let sortedComparisonSamples = comparisonSamples.sorted { $0.date < $1.date }
            let sortedAreaFills = areaFills.sorted { $0.date < $1.date }

            self.title = title
            self.systemImage = systemImage
            self.headline = headline
            self.subtitle = subtitle
            self.currentSummary = currentSummary
            self.comparisonSummary = comparisonSummary
            self.currentSamples = sortedCurrentSamples
            self.comparisonSamples = sortedComparisonSamples
            self.valueRules = valueRules
            self.shadedRegions = shadedRegions
            self.areaFills = sortedAreaFills
            self.markerDate = markerDate
            self.xDomain = xDomain ?? Self.makeXDomain(
                currentSamples: sortedCurrentSamples,
                comparisonSamples: sortedComparisonSamples,
                markerDate: markerDate
            )
            self.yDomain = yDomain ?? Self.makeYDomain(
                currentSamples: sortedCurrentSamples,
                comparisonSamples: sortedComparisonSamples
            )
            self.tint = tint
            self.comparisonColor = comparisonColor
            self.currentLineStyle = currentLineStyle
            self.comparisonLineStyle = comparisonLineStyle
            self.fadesComparisonAfterMarker = fadesComparisonAfterMarker
            self.showsMarkerRule = showsMarkerRule
            self.showsMarkerSymbols = showsMarkerSymbols
            self.emptyChartText = emptyChartText
            self.layout = layout
            self.chartHeight = chartHeight
        }

        init?(
            reflection: Reflection,
            subtitle: String? = nil,
            layout: Layout = .compact,
            chartHeight: CGFloat = 176
        ) {
            let rawSamples = reflection.triggerSamples.sorted { $0.date < $1.date }
            guard let measurementType = reflection.measurementType ?? rawSamples.first?.type,
                  let reminderType = reflection.reminderType,
                  let threshold = reflection.threshold else { return nil }

            let samples = Self.chartSeries(from: rawSamples, reflection: reflection)
            let triggerDate = reflection.date
            let triggerWindowStart = reflection.interval.map { triggerDate.addingTimeInterval(-$0.timeInterval) }
            let xDomain = Self.makeReflectionXDomain(
                samples: samples,
                triggerDate: triggerDate,
                triggerWindowStart: triggerWindowStart,
                interval: reflection.interval
            )
            let yDomain = Self.makeReflectionYDomain(samples: samples, threshold: Double(threshold))
            let clampedTriggerDate = min(max(triggerDate, xDomain.lowerBound), xDomain.upperBound)
            let clampedThreshold = min(max(Double(threshold), yDomain.lowerBound), yDomain.upperBound)
            let triggerSample = samples.min { lhs, rhs in
                abs(lhs.date.timeIntervalSince(triggerDate)) < abs(rhs.date.timeIntervalSince(triggerDate))
            }
            let currentSamples = samples.map { sample in
                Sample(
                    date: sample.date,
                    value: min(max(sample.value, yDomain.lowerBound), yDomain.upperBound),
                    valueLabel: Self.formattedValue(sample.value)
                )
            }

            let triggerWindowRange: ClosedRange<Date>? = {
                guard let triggerWindowStart else { return nil }
                let lowerBound = min(max(triggerWindowStart, xDomain.lowerBound), xDomain.upperBound)
                guard lowerBound < clampedTriggerDate else { return nil }

                return lowerBound...clampedTriggerDate
            }()

            let shadedRegions = triggerWindowRange.map {
                [
                    ShadedRegion(
                        xRange: $0,
                        yRange: clampedThreshold...yDomain.upperBound,
                        color: reminderType.color.opacity(0.12)
                    )
                ]
            } ?? []

            self.init(
                title: measurementType.localized,
                systemImage: measurementType.icon,
                headline: reflection.reminderTriggerSummary,
                subtitle: subtitle,
                currentSummary: .init(
                    label: String(localized: "At trigger"),
                    value: triggerSample.map { Self.formattedValue($0.value) } ?? "--",
                    unit: measurementType.units,
                    color: measurementType.color
                ),
                comparisonSummary: .init(
                    label: String(localized: "Threshold"),
                    value: Self.formattedValue(Double(threshold)),
                    unit: measurementType.units,
                    color: reminderType.color
                ),
                currentSamples: currentSamples,
                comparisonSamples: [],
                valueRules: [
                    .init(
                        value: clampedThreshold,
                        label: String(localized: "Threshold"),
                        color: reminderType.color.opacity(0.72),
                        lineStyle: .init(lineWidth: 1.5, lineCap: .round, dash: [5, 5])
                    )
                ],
                shadedRegions: shadedRegions,
                areaFills: [],
                markerDate: clampedTriggerDate,
                xDomain: xDomain,
                yDomain: yDomain,
                tint: measurementType.color,
                comparisonColor: Color(.systemGray),
                currentLineStyle: .init(lineWidth: 3, lineCap: .round, lineJoin: .round),
                comparisonLineStyle: .init(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4]),
                fadesComparisonAfterMarker: false,
                showsMarkerRule: false,
                showsMarkerSymbols: false,
                emptyChartText: String(localized: "No trigger data was saved for this reflection."),
                layout: layout,
                chartHeight: chartHeight
            )
        }

        var comparisonPastSamples: [Sample] {
            guard fadesComparisonAfterMarker else { return comparisonSamples }
            return comparisonSamples.filter { $0.date <= markerDate }
        }

        var comparisonFutureSamples: [Sample] {
            guard fadesComparisonAfterMarker else { return [] }
            return comparisonSamples.filter { $0.date >= markerDate }
        }

        var hasChartContent: Bool {
            !currentSamples.isEmpty || !comparisonSamples.isEmpty || !valueRules.isEmpty || !shadedRegions.isEmpty || !areaFills.isEmpty
        }

        var currentMarkerSample: Sample? {
            nearestSample(in: currentSamples, to: markerDate)
        }

        var comparisonMarkerSample: Sample? {
            nearestSample(in: comparisonSamples, to: markerDate)
        }

        var accessibilityLabel: String {
            let subtitleText = subtitle.map { " \($0)." } ?? ""
            return "\(title). \(headline).\(subtitleText) \(currentSummary.label): \(currentSummary.value) \(currentSummary.unit). \(comparisonSummary.label): \(comparisonSummary.value) \(comparisonSummary.unit)."
        }

        private func nearestSample(in samples: [Sample], to date: Date) -> Sample? {
            samples.min { lhs, rhs in
                abs(lhs.date.timeIntervalSince(date)) < abs(rhs.date.timeIntervalSince(date))
            }
        }

        func nearestCurrentSample(to date: Date) -> Sample? {
            nearestSample(in: currentSamples, to: date)
        }

        private static func makeXDomain(
            currentSamples: [Sample],
            comparisonSamples: [Sample],
            markerDate: Date
        ) -> ClosedRange<Date> {
            let dates = (currentSamples + comparisonSamples).map(\.date) + [markerDate]
            guard let startDate = dates.min(), let endDate = dates.max(), startDate < endDate else {
                return markerDate.addingTimeInterval(-3_600)...markerDate.addingTimeInterval(3_600)
            }

            return startDate...endDate
        }

        private static func makeYDomain(
            currentSamples: [Sample],
            comparisonSamples: [Sample]
        ) -> ClosedRange<Double> {
            let values = (currentSamples + comparisonSamples).map(\.value)
            guard let maximum = values.max() else { return 0...1 }

            let paddedMaximum = max(1, maximum * 1.08)
            return 0...paddedMaximum
        }

        private static func makeReflectionXDomain(
            samples: [MeasurementSample],
            triggerDate: Date,
            triggerWindowStart: Date?,
            interval: Reminder.Interval?
        ) -> ClosedRange<Date> {
            let unpaddedRange: ClosedRange<Date>
            if let first = samples.first?.date, let last = samples.last?.date {
                let lowerBound = min(first, triggerWindowStart ?? first, triggerDate)
                let upperBound = max(last, triggerDate)

                if lowerBound < upperBound {
                    unpaddedRange = lowerBound...upperBound
                } else {
                    unpaddedRange = lowerBound.addingTimeInterval(-60)...upperBound.addingTimeInterval(60)
                }
            } else {
                unpaddedRange = triggerDate.addingTimeInterval(-60)...triggerDate.addingTimeInterval(60)
            }

            let visibleSpan = max(unpaddedRange.upperBound.timeIntervalSince(unpaddedRange.lowerBound), 60)
            let intervalSpan = interval?.timeInterval ?? visibleSpan
            let minimumPadding: TimeInterval = Self.axisTimeStyleShowsSeconds(for: interval) ? 20 : 60
            let maximumPadding = max(minimumPadding, intervalSpan * 0.25)
            let leadingPadding = min(max(minimumPadding, visibleSpan * 0.08), maximumPadding)
            let trailingPadding = min(max(minimumPadding * 2, visibleSpan * 0.24), maximumPadding)

            return unpaddedRange.lowerBound.addingTimeInterval(-leadingPadding)...unpaddedRange.upperBound.addingTimeInterval(trailingPadding)
        }

        private static func makeReflectionYDomain(
            samples: [MeasurementSample],
            threshold: Double
        ) -> ClosedRange<Double> {
            let values = samples.map(\.value) + [threshold]
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let span = max(1, maxValue - minValue)
            let padding = max(4, span * 0.18)
            let lowerBound = max(0, minValue - padding)
            let upperBound = max(lowerBound + 1, maxValue + padding)

            return lowerBound...upperBound
        }

        private static func chartSeries(
            from samples: [MeasurementSample],
            reflection: Reflection
        ) -> [MeasurementSample] {
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

            return downsample(series, to: 200)
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

        private static func axisTimeStyleShowsSeconds(for interval: Reminder.Interval?) -> Bool {
            guard let interval else { return true }

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

        private static func formattedValue(_ value: Double) -> String {
            value.formatted(.number.precision(.fractionLength(0)))
        }
    }

    struct Summary {
        let label: String
        let value: String
        let unit: String
        let color: Color

        init(
            label: String,
            value: String,
            unit: String,
            color: Color
        ) {
            self.label = label
            self.value = value
            self.unit = unit
            self.color = color
        }
    }

    enum Layout {
        case regular
        case compact

        var contentSpacing: CGFloat {
            switch self {
            case .regular: 18
            case .compact: 14
            }
        }

        var contentPadding: CGFloat {
            switch self {
            case .regular: 18
            case .compact: 16
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .regular: 28
            case .compact: 24
            }
        }

        var verticalSpacing: CGFloat {
            switch self {
            case .regular: 18
            case .compact: 14
            }
        }

        var summarySpacing: CGFloat {
            switch self {
            case .regular: 18
            case .compact: 12
            }
        }

        var headlineFont: Font {
            switch self {
            case .regular: .title2.weight(.semibold)
            case .compact: .headline.weight(.semibold)
            }
        }

        var subtitleFont: Font {
            switch self {
            case .regular: .subheadline
            case .compact: .footnote
            }
        }

        var summaryLabelFont: Font {
            switch self {
            case .regular: .title3.weight(.semibold)
            case .compact: .subheadline.weight(.semibold)
            }
        }

        var summaryValueFontSize: CGFloat {
            switch self {
            case .regular: 44
            case .compact: 28
            }
        }

        var summaryUnitFont: Font {
            switch self {
            case .regular: .headline.weight(.semibold)
            case .compact: .caption.weight(.semibold)
            }
        }

        var summaryDotSize: CGFloat {
            switch self {
            case .regular: 14
            case .compact: 9
            }
        }

        var timelineHeight: CGFloat {
            switch self {
            case .regular: 38
            case .compact: 30
            }
        }

        var minimumPlotHeight: CGFloat {
            switch self {
            case .regular: 160
            case .compact: 96
            }
        }

        var markerSymbolSize: CGFloat {
            switch self {
            case .regular: 112
            case .compact: 54
            }
        }

        var markerRuleWidth: CGFloat {
            switch self {
            case .regular: 3
            case .compact: 2
            }
        }

        var timelineLabelFont: Font {
            switch self {
            case .regular: .caption.weight(.semibold)
            case .compact: .caption2.weight(.semibold)
            }
        }

        var timelineDotY: CGFloat {
            switch self {
            case .regular: 8
            case .compact: 6
            }
        }

        var timelineLabelY: CGFloat {
            switch self {
            case .regular: 29
            case .compact: 22
            }
        }

        var timelineTickHeight: CGFloat {
            switch self {
            case .regular: 14
            case .compact: 10
            }
        }

        var usesNativeXAxis: Bool {
            switch self {
            case .regular: false
            case .compact: false
            }
        }

        var showsTimelineEndLabel: Bool {
            switch self {
            case .regular: true
            case .compact: false
            }
        }
    }

    struct Sample: Identifiable, Hashable {
        let id: UUID
        let date: Date
        let value: Double
        let valueLabel: String?

        init(
            id: UUID = UUID(),
            date: Date,
            value: Double,
            valueLabel: String? = nil
        ) {
            self.id = id
            self.date = date
            self.value = value
            self.valueLabel = valueLabel
        }

        var valueText: String {
            valueLabel ?? value.formatted(.number.precision(.fractionLength(0)))
        }
    }

    struct ShadedRegion: Identifiable {
        let id: UUID
        let xRange: ClosedRange<Date>
        let yRange: ClosedRange<Double>
        let color: Color

        init(
            id: UUID = UUID(),
            xRange: ClosedRange<Date>,
            yRange: ClosedRange<Double>,
            color: Color
        ) {
            self.id = id
            self.xRange = xRange
            self.yRange = yRange
            self.color = color
        }
    }

    struct ValueRule: Identifiable {
        let id: UUID
        let value: Double
        let label: String
        let color: Color
        let lineStyle: StrokeStyle

        init(
            id: UUID = UUID(),
            value: Double,
            label: String,
            color: Color,
            lineStyle: StrokeStyle = .init(lineWidth: 1.5, lineCap: .round, dash: [5, 5])
        ) {
            self.id = id
            self.value = value
            self.label = label
            self.color = color
            self.lineStyle = lineStyle
        }
    }

    struct AreaFill: Identifiable {
        let id: UUID
        let date: Date
        let lowerValue: Double
        let upperValue: Double
        let color: Color

        init(
            id: UUID = UUID(),
            date: Date,
            lowerValue: Double,
            upperValue: Double,
            color: Color
        ) {
            self.id = id
            self.date = date
            self.lowerValue = lowerValue
            self.upperValue = upperValue
            self.color = color
        }
    }
}

// MARK: - MissedReflectionTrendSummaryRow

private struct MissedReflectionTrendSummaryRow: View {
    let current: MissedReflectionTrendCard.Summary
    let comparison: MissedReflectionTrendCard.Summary
    let layout: MissedReflectionTrendCard.Layout

    var body: some View {
        HStack(alignment: .top, spacing: layout.summarySpacing) {
            MissedReflectionTrendSummaryBlock(summary: current, layout: layout)
                .frame(maxWidth: .infinity, alignment: .leading)

            MissedReflectionTrendSummaryBlock(summary: comparison, layout: layout)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - MissedReflectionTrendSummaryBlock

private struct MissedReflectionTrendSummaryBlock: View {
    let summary: MissedReflectionTrendCard.Summary
    let layout: MissedReflectionTrendCard.Layout

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label {
                Text(summary.label)
                    .font(layout.summaryLabelFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } icon: {
                Circle()
                    .fill(summary.color)
                    .frame(width: layout.summaryDotSize, height: layout.summaryDotSize)
            }
            .foregroundStyle(summary.color)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(summary.value)
                    .font(.system(size: layout.summaryValueFontSize, weight: .semibold, design: .rounded))
                    .foregroundStyle(summary.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)

                Text(summary.unit)
                    .font(layout.summaryUnitFont)
                    .foregroundStyle(summary.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - MissedReflectionTrendChart

private struct MissedReflectionTrendChart: View {
    let data: MissedReflectionTrendCard.Data
    @Binding var selectedSample: MissedReflectionTrendCard.Sample?
    @State private var plotFrame: CGRect = .zero

    private var chartHeight: CGFloat {
        if data.layout.usesNativeXAxis {
            return data.chartHeight
        }

        return max(data.layout.minimumPlotHeight, data.chartHeight - data.layout.timelineHeight - 4)
    }

    var body: some View {
        VStack(spacing: 4) {
            if data.hasChartContent {
                Chart {
                    ForEach(data.shadedRegions) { region in
                        RectangleMark(
                            xStart: .value("Region Start", region.xRange.lowerBound),
                            xEnd: .value("Region End", region.xRange.upperBound),
                            yStart: .value("Region Low", region.yRange.lowerBound),
                            yEnd: .value("Region High", region.yRange.upperBound)
                        )
                        .foregroundStyle(region.color)
                    }

                    ForEach(data.valueRules) { rule in
                        RuleMark(y: .value(rule.label, rule.value))
                            .foregroundStyle(rule.color)
                            .lineStyle(rule.lineStyle)
                    }

                    ForEach(data.areaFills) { areaFill in
                        AreaMark(
                            x: .value("Time", areaFill.date),
                            yStart: .value("Low", areaFill.lowerValue),
                            yEnd: .value("High", areaFill.upperValue)
                        )
                        .foregroundStyle(areaFill.color)
                        .interpolationMethod(.monotone)
                    }

                    ForEach(data.comparisonPastSamples) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value(data.comparisonSummary.label, sample.value)
                        )
                        .foregroundStyle(data.comparisonColor.opacity(0.44))
                        .lineStyle(data.comparisonLineStyle)
                        .interpolationMethod(.monotone)
                    }

                    ForEach(data.comparisonFutureSamples) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value(data.comparisonSummary.label, sample.value)
                        )
                        .foregroundStyle(data.comparisonColor.opacity(0.12))
                        .lineStyle(data.comparisonLineStyle)
                        .interpolationMethod(.monotone)
                    }

                    ForEach(data.currentSamples) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value(data.currentSummary.label, sample.value)
                        )
                        .foregroundStyle(data.tint)
                        .lineStyle(data.currentLineStyle)
                        .interpolationMethod(.monotone)
                    }

                    if let selectedSample {
                        RuleMark(x: .value("Selected Time", selectedSample.date))
                            .foregroundStyle(data.tint.opacity(0.35))
                            .lineStyle(.init(lineWidth: data.layout.markerRuleWidth, lineCap: .round))

                        PointMark(
                            x: .value("Selected Time", selectedSample.date),
                            y: .value(data.currentSummary.label, selectedSample.value)
                        )
                        .foregroundStyle(data.tint)
                        .symbolSize(data.layout.markerSymbolSize)
                    }

                    if data.showsMarkerRule {
                        RuleMark(x: .value("Current Time", data.markerDate))
                            .foregroundStyle(Color(.systemGray4))
                            .lineStyle(.init(lineWidth: data.layout.markerRuleWidth, lineCap: .round))
                    }

                    if data.showsMarkerSymbols, let comparisonMarkerSample = data.comparisonMarkerSample {
                        PointMark(
                            x: .value("Current Time", data.markerDate),
                            y: .value(data.comparisonSummary.label, comparisonMarkerSample.value)
                        )
                        .foregroundStyle(data.comparisonColor.opacity(0.58))
                        .symbolSize(data.layout.markerSymbolSize)
                    }

                    if data.showsMarkerSymbols, let currentMarkerSample = data.currentMarkerSample {
                        PointMark(
                            x: .value("Current Time", data.markerDate),
                            y: .value(data.currentSummary.label, currentMarkerSample.value)
                        )
                        .foregroundStyle(data.tint)
                        .symbolSize(data.layout.markerSymbolSize)
                    }
                }
                .chartXScale(domain: data.xDomain)
                .chartYScale(domain: data.yDomain)
                .chartXAxis {
                    if data.layout.usesNativeXAxis {
                        AxisMarks(
                            preset: .aligned,
                            position: .bottom,
                            values: [
                            data.xDomain.lowerBound,
                            data.markerDate,
                            data.xDomain.upperBound
                        ]) { value in
                            AxisTick(length: 8)
                                .foregroundStyle(Color(.systemGray3))

                            AxisValueLabel(
                                collisionResolution: .disabled
                            ) {
                                if let date = value.as(Date.self) {
                                    Text(date.formatted(.dateTime.hour().minute()))
                                        .font(data.layout.timelineLabelFont)
                                        .foregroundStyle(Color(.systemGray))
                                        .monospacedDigit()
                                }
                            }
                        }
                    }
                }
                .chartYAxis(.hidden)
                .chartLegend(.hidden)
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.clear)
                        .clipped()
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        let frame = proxy.plotFrame.map { geometry[$0] } ?? .zero

                        Color.clear
                            .contentShape(Rectangle())
                            .preference(key: MissedReflectionTrendPlotFrameKey.self, value: frame)
                            .gesture(selectionGesture(proxy: proxy, plotFrame: frame))
                    }
                }
                .onPreferenceChange(MissedReflectionTrendPlotFrameKey.self) { frame in
                    plotFrame = frame
                }
                .frame(height: chartHeight)
            } else {
                Text(data.emptyChartText ?? "No chart data is available.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: chartHeight, alignment: .center)
            }

            if !data.layout.usesNativeXAxis {
                MissedReflectionTrendTimelineRuler(
                    xDomain: data.xDomain,
                    markerDate: data.markerDate,
                    layout: data.layout,
                    plotFrame: plotFrame
                )
                .frame(height: data.layout.timelineHeight)
            }
        }
    }

    private func selectionGesture(
        proxy: ChartProxy,
        plotFrame: CGRect
    ) -> some Gesture {
        LongPressGesture(minimumDuration: 0.22)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                guard case .second(true, let dragValue?) = value else { return }

                updateSelection(
                    at: dragValue.location,
                    proxy: proxy,
                    plotFrame: plotFrame
                )
            }
            .onEnded { _ in
                selectedSample = nil
            }
    }

    private func updateSelection(
        at location: CGPoint,
        proxy: ChartProxy,
        plotFrame: CGRect
    ) {
        guard plotFrame.width > 0 else { return }

        let x = location.x - plotFrame.origin.x
        guard x >= 0, x <= plotFrame.width,
              let selectedDate = proxy.value(atX: x, as: Date.self),
              let nearestSample = data.nearestCurrentSample(to: selectedDate) else { return }

        selectedSample = nearestSample
    }
}

private struct MissedReflectionTrendPlotFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - MissedReflectionTrendTimelineRuler

private struct MissedReflectionTrendTimelineRuler: View {
    let xDomain: ClosedRange<Date>
    let markerDate: Date
    let layout: MissedReflectionTrendCard.Layout
    let plotFrame: CGRect

    private let dotCount = 25
    private let axisColor = Color(.systemGray3)
    private let labelColor = Color(.systemGray)
    private let horizontalInset: CGFloat = 8
    private let labelWidth: CGFloat = 88

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let axisStartX = measuredAxisStartX(containerWidth: width)
            let axisEndX = measuredAxisEndX(containerWidth: width)
            let axisWidth = max(1, axisEndX - axisStartX)
            let markerX = axisStartX + axisWidth * markerFraction
            let labelHalfWidth = labelWidth / 2
            let startLabelX = min(max(axisStartX + labelHalfWidth, labelHalfWidth), width - labelHalfWidth)
            let clampedMarkerX = min(max(markerX, labelHalfWidth), max(labelHalfWidth, width - labelHalfWidth))
            let endLabelX = min(max(axisEndX - labelHalfWidth, labelHalfWidth), width - labelHalfWidth)
            let minimumLabelSpacing = labelWidth * 0.9
            let showsStartLabel = abs(clampedMarkerX - startLabelX) >= minimumLabelSpacing
            let showsEndLabel = layout.showsTimelineEndLabel
                && abs(endLabelX - clampedMarkerX) >= minimumLabelSpacing
                && abs(endLabelX - startLabelX) >= minimumLabelSpacing

            ZStack(alignment: .topLeading) {
                ForEach(0..<dotCount, id: \.self) { index in
                    let x = axisStartX + axisWidth * CGFloat(index) / CGFloat(dotCount - 1)

                    Circle()
                        .fill(axisColor)
                        .frame(width: 3, height: 3)
                        .position(x: x, y: layout.timelineDotY)
                }

                tick
                    .position(x: axisStartX, y: layout.timelineDotY)

                tick
                    .position(x: markerX, y: layout.timelineDotY)

                tick
                    .position(x: axisEndX, y: layout.timelineDotY)

                if showsStartLabel {
                    timelineLabel(xDomain.lowerBound)
                        .frame(width: labelWidth, alignment: .leading)
                        .position(x: startLabelX, y: layout.timelineLabelY)
                }

                timelineLabel(markerDate)
                    .frame(width: labelWidth)
                    .position(x: clampedMarkerX, y: layout.timelineLabelY)

                if showsEndLabel {
                    timelineLabel(xDomain.upperBound)
                        .frame(width: labelWidth, alignment: .trailing)
                        .position(x: endLabelX, y: layout.timelineLabelY)
                }
            }
        }
    }

    private var tick: some View {
        Capsule()
            .fill(axisColor)
            .frame(width: 4, height: layout.timelineTickHeight)
    }

    private var markerFraction: CGFloat {
        let span = xDomain.upperBound.timeIntervalSince(xDomain.lowerBound)
        guard span > 0 else { return 0.5 }

        let offset = markerDate.timeIntervalSince(xDomain.lowerBound)
        return CGFloat(min(max(offset / span, 0), 1))
    }

    private func measuredAxisStartX(containerWidth width: CGFloat) -> CGFloat {
        guard plotFrame.width > 0 else { return horizontalInset }

        return min(max(plotFrame.minX, horizontalInset), max(horizontalInset, width - horizontalInset))
    }

    private func measuredAxisEndX(containerWidth width: CGFloat) -> CGFloat {
        guard plotFrame.width > 0 else { return max(horizontalInset, width - horizontalInset) }

        return min(max(plotFrame.maxX, horizontalInset), max(horizontalInset, width - horizontalInset))
    }

    private func timelineLabel(_ date: Date) -> some View {
        Text(date.formatted(.dateTime.hour().minute()))
            .font(layout.timelineLabelFont)
            .foregroundStyle(labelColor)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

// MARK: - Preview

#Preview("Missed Heart Rate") {
    let calendar = Calendar(identifier: .gregorian)
    let triggerDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 4, hour: 17, minute: 36))!
    let startDate = calendar.date(byAdding: .minute, value: -3, to: triggerDate)!
    let triggerWindowStart = calendar.date(byAdding: .minute, value: -1, to: triggerDate)!
    let endDate = calendar.date(byAdding: .second, value: 40, to: triggerDate)!
    let heartRateColor = Color(red: 1, green: 0.22, blue: 0.42)
    let thresholdColor = Color.red
    let threshold = 65.0

    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        ScrollView {
            MissedReflectionTrendCard(
                data: .init(
                    title: "Heart Rate",
                    systemImage: "heart.fill",
                    headline: "Above 65 bpm for 1 minute",
                    subtitle: "Triggered on Jul 4 at 17:36",
                    currentSummary: .init(
                        label: "At trigger",
                        value: "82",
                        unit: "bpm",
                        color: heartRateColor
                    ),
                    comparisonSummary: .init(
                        label: "Threshold",
                        value: "65",
                        unit: "bpm",
                        color: thresholdColor
                    ),
                    currentSamples: MissedReflectionTrendCardPreviewData.heartRateSamples(start: startDate),
                    comparisonSamples: [],
                    valueRules: [
                        .init(
                            value: threshold,
                            label: "Threshold",
                            color: thresholdColor.opacity(0.72),
                            lineStyle: .init(lineWidth: 1.5, lineCap: .round, dash: [5, 5])
                        )
                    ],
                    shadedRegions: [
                        .init(
                            xRange: triggerWindowStart...triggerDate,
                            yRange: threshold...96,
                            color: thresholdColor.opacity(0.12)
                        )
                    ],
                    markerDate: triggerDate,
                    xDomain: startDate...endDate,
                    yDomain: 45...96,
                    tint: heartRateColor,
                    comparisonColor: Color(.systemGray),
                    currentLineStyle: .init(lineWidth: 3, lineCap: .round, lineJoin: .round),
                    comparisonLineStyle: .init(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4]),
                    fadesComparisonAfterMarker: false,
                    showsMarkerRule: false,
                    showsMarkerSymbols: false,
                    emptyChartText: "No trigger data was saved for this reflection.",
                    layout: .compact,
                    chartHeight: 176
                ),
                footer: {
                    VStack(alignment: .leading, spacing: 16) {
                        Divider()
                        
                        HStack(spacing: 8) {
                            Button {
                                
                            } label: {
                                Label("Accept", systemImage: "checkmark.circle.fill")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                                    .frame(width: 100)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            .tint(.green)
                            
                            Button {
                                
                            } label: {
                                Label("Reject", systemImage: "xmark.circle.fill")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.red)
                                    .frame(width: 100)
                            }
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.capsule)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            )
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}

private enum MissedReflectionTrendCardPreviewData {
    static func heartRateSamples(start: Date) -> [MissedReflectionTrendCard.Sample] {
        let values: [(Double, Double)] = [
            (0, 58),
            (10, 61),
            (20, 69),
            (30, 75),
            (40, 79),
            (50, 76),
            (60, 68),
            (70, 62),
            (80, 60),
            (90, 64),
            (100, 70),
            (110, 72),
            (120, 68),
            (130, 63),
            (140, 59),
            (150, 58),
            (160, 61),
            (170, 74),
            (180, 82)
        ]

        return values.compactMap { seconds, value in
            guard let date = Calendar.current.date(byAdding: .second, value: Int(seconds), to: start) else { return nil }

            return .init(date: date, value: value)
        }
    }
}

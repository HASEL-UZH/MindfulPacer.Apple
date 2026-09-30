//
//  StatChart.swift
//  Athleon
//
//  Created by Grigor Dochev on 07.03.2026.
//

import SwiftUI
import Charts

private let statChartSelectionRuleLineWidth: CGFloat = 2

// MARK: - Protocol

/// A data point that can be plotted on a StatChart.
protocol StatChartEntry: Identifiable {
    var date: Date { get }
    var value: Double { get }
}

// MARK: - Mark Style

/// Visual representation style for chart data points.
enum StatChartMarkStyle {
    case bar(cornerRadius: CGFloat = 4)
    case line(lineWidth: CGFloat = 2, showPoints: Bool = false)
    case area(lineWidth: CGFloat = 2, opacity: Double = 0.15)
    case point(size: CGFloat = 6)
}

// MARK: - Summary Mode

/// How the summary value is computed when no data point is selected.
enum StatChartSummaryMode {
    case average
    case total
    case min
    case max
    case latest
}

// MARK: - Period

/// Time period for filtering and display.
enum StatChartPeriod: String, CaseIterable, Identifiable {
    case oneHour = "1H"
    case twoHours = "2H"
    case day = "D"
    case week = "W"
    case month = "M"
    case sixMonths = "6M"
    case year = "Y"

    var id: String { rawValue }
}

// MARK: - Visible Window

/// The date window currently visible in a scrollable StatChart.
struct StatChartVisibleWindow: Equatable {
    let startDate: Date
    let endDate: Date
    let period: StatChartPeriod
}

// MARK: - Chip

/// Describes how a chip affects the chart when active.
enum StatChartChipOverlay: Equatable {
    /// Scroll the chart to a specific date and place a vertical rule there.
    case focusDate(Date)

    /// Draw a horizontal reference line at the given y-value.
    case referenceLine(y: Double)

    /// Highlight specific points with annotated dots (e.g. min / max).
    case highlightPoints([StatChartHighlight])

    /// Dynamically highlight the max and min entries within the visible scroll window.
    /// The chart recomputes highlights as the user scrolls, matching Apple Health behaviour.
    case visibleMinMax(maxColor: Color, minColor: Color)

    /// Overlay a secondary line series on top of the base chart.
    case trendLine([StatChartTrendPoint])
}

/// A single annotated highlight on the chart.
struct StatChartHighlight: Equatable, Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let label: String
    let color: Color

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// A point in a trend overlay line.
struct StatChartTrendPoint: Equatable, Identifiable {
    let id = UUID()
    let date: Date
    let value: Double

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

/// A tappable pill displayed below the chart.
/// Activating it applies an overlay to the chart and shows a value.
struct StatChartChip: Identifiable {
    let id: String
    let label: String
    let valueText: String
    let unitText: String
    let overlay: StatChartChipOverlay
    let systemImage: String?

    init(id: String? = nil, label: String, valueText: String, unitText: String, overlay: StatChartChipOverlay, systemImage: String? = nil) {
        self.id = id ?? label
        self.label = label
        self.valueText = valueText
        self.unitText = unitText
        self.overlay = overlay
        self.systemImage = systemImage
    }
}

// MARK: - Configuration

/// All customisation knobs for a StatChart instance.
struct StatChartConfiguration {

    /// Chart mark type (bar, line, area, point).
    var markStyle: StatChartMarkStyle = .bar()

    /// Tint colour applied to marks and the selection rule.
    var tintColor: Color = .accentColor

    /// Fixed height for the chart area.
    var chartHeight: CGFloat = 260

    /// Unit label shown next to the summary value (e.g. "steps", "kg", "bpm").
    var unitLabel: String

    /// How the aggregate summary is computed when nothing is selected.
    var summaryMode: StatChartSummaryMode = .average

    /// Which period segments are available in the picker.
    var periods: [StatChartPeriod] = StatChartPeriod.allCases

    /// The period selected by default on first render.
    var defaultPeriod: StatChartPeriod = .month

    /// How much of the x-axis is visible at once (in seconds).
    var visibleDomainLength: TimeInterval = 7 * 86_400

    /// Maximum number of data points to render around the visible window.
    /// Keeps scrolling responsive when the backing series is dense.
    var maxRenderedDataPoints: Int = 180

    /// Formats the summary value for display.
    var valueFormatter: (Double) -> String = { Int($0).formatted() }

    /// Date format string used for x-axis tick labels.
    var xAxisDateFormat: String = "EEE"

    /// Calendar component used for the x-axis date unit (e.g. `.day`, `.hour`).
    var xAxisDateUnit: Calendar.Component = .day

    /// Tappable pills below the chart. Each focuses the chart on a date.
    var chips: [StatChartChip] = []

    /// Whether to render the chip row inline below the chart.
    /// Set to `false` when you want to render the chips yourself (e.g. in a separate list section)
    /// while still using an external `activeChipID` binding for overlays.
    var showChipsInline: Bool = true

    /// Maps each period to a visible domain length (in seconds).
    /// When provided, the period picker drives the chart's visible window.
    /// When nil, the chart uses the fixed `visibleDomainLength` for all periods.
    var periodDomainMapping: [StatChartPeriod: TimeInterval]?

    /// Returns the x-axis date format for a given period.
    /// When nil, uses the fixed `xAxisDateFormat` for all periods.
    var xAxisDateFormatForPeriod: ((StatChartPeriod) -> String)?

    /// Optional fixed lower padding for line/area charts, in the measurement's units.
    var minimumValuePadding: Double? = nil
    var dateDomain: ClosedRange<Date>? = nil
    var initialWindowStart: Date? = nil
    var startsAtZero: Bool = false

    /// Scale shared by the chart and its validation, including empty and constant series.
    func yScaleDomain(for values: [Double]) -> ClosedRange<Double> {
        let values = values.filter(\.isFinite)
        guard let minValue = values.min(),
              let maxValue = values.max(),
              minValue.isFinite,
              maxValue.isFinite else {
            return 0...1
        }

        let shouldIncludeZero: Bool = {
            if case .bar = markStyle { return true }
            return false
        }()

        let rawRange = maxValue - minValue
        let fallbackPadding = max(abs(maxValue) * 0.1, 1)
        let padding = rawRange > 0 ? max(rawRange * 0.12, 1) : fallbackPadding
        let allValuesAreNonNegative = values.allSatisfy { $0 >= 0 }

        let lowerPadding = minimumValuePadding ?? padding
        let lower: Double
        if shouldIncludeZero || startsAtZero {
            lower = 0
        } else if allValuesAreNonNegative {
            lower = max(0, minValue - lowerPadding)
        } else {
            lower = minValue - lowerPadding
        }

        let upper = maxValue + padding
        if lower == upper {
            return (lower - 1)...(upper + 1)
        }
        return lower...upper
    }

    /// Summary mode label shown above the value when nothing is selected.
    var summaryModeLabel: String {
        switch summaryMode {
        case .average: "Average"
        case .total: "Total"
        case .min: "Min"
        case .max: "Max"
        case .latest: "Latest"
        }
    }
}

// MARK: - Array Helpers

extension Array where Element: StatChartEntry {

    /// Snap a date to the nearest entry using midpoints between consecutive dates.
    func nearestEntry(for date: Date) -> Element? {
        guard !isEmpty else { return nil }
        if count == 1 { return first }

        let sorted = self.sorted { $0.date < $1.date }

        func mid(_ a: Date, _ b: Date) -> Date {
            Date(
                timeIntervalSinceReferenceDate:
                    (a.timeIntervalSinceReferenceDate + b.timeIntervalSinceReferenceDate) / 2
            )
        }

        for index in sorted.indices {
            if index == 0 {
                let nextMid = mid(sorted[0].date, sorted[1].date)
                if date <= nextMid { return sorted[0] }
            } else if index == sorted.count - 1 {
                let prevMid = mid(sorted[index - 1].date, sorted[index].date)
                if date > prevMid { return sorted[index] }
            } else {
                let prevMid = mid(sorted[index - 1].date, sorted[index].date)
                let nextMid = mid(sorted[index].date, sorted[index + 1].date)
                if date > prevMid && date <= nextMid {
                    return sorted[index]
                }
            }
        }

        // Fallback – closest by absolute distance
        return sorted.min {
            abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
        }
    }

    /// Compute an aggregate value over all entries.
    func summaryValue(mode: StatChartSummaryMode) -> Double {
        guard !isEmpty else { return 0 }
        let values = map(\.value)

        switch mode {
        case .average: return values.reduce(0, +) / Double(count)
        case .total:   return values.reduce(0, +)
        case .min:     return values.min() ?? 0
        case .max:     return values.max() ?? 0
        case .latest:  return last?.value ?? 0
        }
    }

    /// Value for a specific selected date, or the aggregate when `date` is nil.
    func summaryValue(for date: Date?, mode: StatChartSummaryMode) -> Double {
        guard let date else { return summaryValue(mode: mode) }

        return nearestEntry(for: date)?.value ?? 0
    }
}

// MARK: - Health Chart View

/// A generic, reusable chart view that replicates the Apple Health chart pattern.
///
/// ```swift
/// StatChart(
///     entries: stepEntries,
///     configuration: .init(unitLabel: "steps")
/// )
/// ```
struct StatChart<Entry: StatChartEntry>: View {

    // MARK: Inputs

    let entries: [Entry]
    let configuration: StatChartConfiguration

    // MARK: State

    /// Raw selection coming from the Charts framework (ephemeral, set during gesture).
    @State private var rawSelectedDate: Date?

    /// Persistent, snapped selection we actually display.
    @State private var selectedDate: Date?

    /// Currently selected time period.
    @State private var selectedPeriod: StatChartPeriod

    /// External period binding, used when the chart should drive a parent view model.
    @Binding private var externalSelectedPeriod: StatChartPeriod

    /// Leading-edge date of the visible scroll window; updated by Charts.
    @State private var scrollPositionX: Date = .now

    /// X-position of the selected data point in the chart view's coordinate space.
    @State private var selectionXPosition: CGFloat = 0

    /// Measured width of the floating selection card.
    @State private var selectionCardWidth: CGFloat = 0

    /// Width of the parent container.
    @State private var containerWidth: CGFloat = 0

    /// External chip binding (used when `usesExternalChipBinding` is true).
    @Binding private var _externalChipID: String?

    /// Optional external sink for the chart's currently visible date window.
    @Binding private var externalVisibleWindow: StatChartVisibleWindow?

    /// Internal chip state (used when `usesExternalChipBinding` is false).
    @State private var _internalChipID: String?

    /// Whether an external binding drives chip selection.
    private let usesExternalChipBinding: Bool

    /// Whether an external binding drives period selection.
    private let usesExternalPeriodBinding: Bool

    /// The chip whose overlay is currently active, if any.
    private var activeChipID: String? {
        get { usesExternalChipBinding ? _externalChipID : _internalChipID }
        nonmutating set {
            if usesExternalChipBinding {
                _externalChipID = newValue
            } else {
                _internalChipID = newValue
            }
        }
    }

    /// The selected period, optionally synced with a parent view model.
    private var activeSelectedPeriod: StatChartPeriod {
        get { usesExternalPeriodBinding ? externalSelectedPeriod : selectedPeriod }
        nonmutating set {
            if usesExternalPeriodBinding {
                externalSelectedPeriod = newValue
            } else {
                selectedPeriod = newValue
            }
        }
    }

    // MARK: Derived

    /// Resolved active chip (nil when no chip is active).
    private var activeChip: StatChartChip? {
        guard let activeChipID else { return nil }
        return configuration.chips.first { $0.id == activeChipID }
    }

    /// Whether an active chip overlay should make the base series recede.
    private var isEmphasizingOverlay: Bool {
        guard let chip = activeChip else { return false }
        switch chip.overlay {
        case .referenceLine, .highlightPoints, .visibleMinMax, .trendLine:
            return true
        case .focusDate:
            return false
        }
    }

    /// Entries that fall within the currently visible scroll window.
    private var visibleEntries: [Entry] {
        let windowStart = scrollPositionX
        let windowEnd = scrollPositionX.addingTimeInterval(activeDomainLength)
        return entries.filter { $0.date >= windowStart && $0.date <= windowEnd }
    }

    /// A line or area cannot show a lone reading without a point marker.
    /// Check the visible window, since the rest of the history may be offscreen.
    private var isolatedVisibleEntry: Entry? {
        let visible = visibleEntries
        return visible.count == 1 ? visible.first : nil
    }

    private func xValue(for date: Date) -> PlottableValue<Date> {
        if case .bar = configuration.markStyle {
            return .value("Date", date, unit: configuration.xAxisDateUnit)
        }
        // Only bars are calendar buckets. Rounding a measurement to a bucket's
        // midpoint can move a reading at the edge outside the visible window.
        return .value("Date", date)
    }

    /// Entries rendered into the chart. This is intentionally wider than the visible
    /// window so scrolling has breathing room without forcing Charts to draw the full series.
    private var renderedEntries: [Entry] {
        guard entries.count > configuration.maxRenderedDataPoints else { return entries }

        let buffer = activeDomainLength * 0.25
        let renderStart = scrollPositionX.addingTimeInterval(-buffer)
        let renderEnd = scrollPositionX.addingTimeInterval(activeDomainLength + buffer)
        let windowedEntries = entries.filter { $0.date >= renderStart && $0.date <= renderEnd }
        let source = windowedEntries.isEmpty ? visibleEntries : windowedEntries

        guard source.count > configuration.maxRenderedDataPoints else { return source }

        let bucketSize = Double(source.count) / Double(configuration.maxRenderedDataPoints)
        var downsampledEntries: [Entry] = []
        downsampledEntries.reserveCapacity(configuration.maxRenderedDataPoints)

        for index in 0..<configuration.maxRenderedDataPoints {
            let startIndex = Int(Double(index) * bucketSize)
            let endIndex = min(Int(Double(index + 1) * bucketSize), source.count)
            guard startIndex < endIndex else { continue }

            let bucket = source[startIndex..<endIndex]
            if let significantEntry = bucket.max(by: { $0.value < $1.value }) {
                downsampledEntries.append(significantEntry)
            }
        }

        return downsampledEntries
    }

    /// Y-domain based on the visible window instead of the full dataset.
    /// This prevents off-looking axes when distant outliers exist outside the current scroll window.
    private var yScaleDomain: ClosedRange<Double> {
        configuration.yScaleDomain(for: yDomainValues)
    }

    private var yDomainValues: [Double] {
        var values = (visibleEntries.isEmpty ? renderedEntries : visibleEntries).map(\.value)

        if let activeChip {
            switch activeChip.overlay {
            case .focusDate:
                break
            case .referenceLine(let y):
                values.append(y)
            case .highlightPoints(let highlights):
                values.append(contentsOf: highlights.map(\.value))
            case .visibleMinMax:
                values.append(contentsOf: activeHighlightAnnotations.map(\.value))
            case .trendLine(let points):
                let visibleStart = scrollPositionX
                let visibleEnd = scrollPositionX.addingTimeInterval(activeDomainLength)
                values.append(contentsOf: points
                    .filter { $0.date >= visibleStart && $0.date <= visibleEnd }
                    .map(\.value))
            }
        }

        return values
    }

    /// Dynamically resolved highlights for `.visibleMinMax` — recomputed on scroll.
    private func resolvedVisibleMinMaxHighlights(
        maxColor: Color,
        minColor: Color
    ) -> [StatChartHighlight] {
        let visible = visibleEntries
        guard let best = visible.max(by: { $0.value < $1.value }),
              let worst = visible.min(by: { $0.value < $1.value }),
              visible.count > 1 else { return [] }

        return [
            .init(date: best.date, value: best.value, label: "MAX", color: maxColor),
            .init(date: worst.date, value: worst.value, label: "MIN", color: minColor)
        ]
    }

    /// Dynamic range text for the visible window (e.g. "45–120").
    private var visibleMinMaxRangeText: String? {
        let visible = visibleEntries
        guard let best = visible.max(by: { $0.value < $1.value }),
              let worst = visible.min(by: { $0.value < $1.value }),
              visible.count > 1 else { return nil }
        return "\(configuration.valueFormatter(worst.value))–\(configuration.valueFormatter(best.value))"
    }

    /// Visible domain driven by the period picker (or falls back to config default).
    private var activeDomainLength: TimeInterval {
        configuration.periodDomainMapping?[activeSelectedPeriod] ?? configuration.visibleDomainLength
    }

    /// X-axis date format driven by the period picker (or falls back to config default).
    private var activeXAxisDateFormat: String {
        configuration.xAxisDateFormatForPeriod?(activeSelectedPeriod) ?? configuration.xAxisDateFormat
    }

    /// Explicit scrollable x-domain so short data ranges still occupy the full visible window.
    private var xScaleDomain: ClosedRange<Date> {
        if let domain = configuration.dateDomain { return domain }
        let end = entries.map(\.date).max() ?? .now
        let start = entries.map(\.date).min() ?? end.addingTimeInterval(-activeDomainLength)
        return min(start, end.addingTimeInterval(-activeDomainLength))...end
    }

    // MARK: Init

    init(entries: [Entry], configuration: StatChartConfiguration) {
        self.entries = entries
        self.configuration = configuration
        self.usesExternalChipBinding = false
        self.usesExternalPeriodBinding = false
        __externalChipID = .constant(nil)
        _externalSelectedPeriod = .constant(configuration.defaultPeriod)
        _externalVisibleWindow = .constant(nil)
        _selectedPeriod = State(initialValue: configuration.defaultPeriod)

        let defaultDomain = configuration.periodDomainMapping?[configuration.defaultPeriod]
            ?? configuration.visibleDomainLength
        if let start = configuration.initialWindowStart {
            _scrollPositionX = State(initialValue: start)
        } else if let latest = entries.max(by: { $0.date < $1.date }) {
            _scrollPositionX = State(
                initialValue: Self.initialScrollStart(latestDate: latest.date, domain: defaultDomain)
            )
        }
    }

    /// Creates a chart with an externally-controlled chip selection.
    init(entries: [Entry], configuration: StatChartConfiguration, activeChipID: Binding<String?>) {
        self.entries = entries
        self.configuration = configuration
        self.usesExternalChipBinding = true
        self.usesExternalPeriodBinding = false
        __externalChipID = activeChipID
        _externalSelectedPeriod = .constant(configuration.defaultPeriod)
        _externalVisibleWindow = .constant(nil)
        _selectedPeriod = State(initialValue: configuration.defaultPeriod)

        let defaultDomain = configuration.periodDomainMapping?[configuration.defaultPeriod]
            ?? configuration.visibleDomainLength
        if let start = configuration.initialWindowStart {
            _scrollPositionX = State(initialValue: start)
        } else if let latest = entries.max(by: { $0.date < $1.date }) {
            _scrollPositionX = State(
                initialValue: Self.initialScrollStart(latestDate: latest.date, domain: defaultDomain)
            )
        }
    }

    /// Creates a chart with externally-controlled chip selection and visible-window reporting.
    init(
        entries: [Entry],
        configuration: StatChartConfiguration,
        activeChipID: Binding<String?>,
        visibleWindow: Binding<StatChartVisibleWindow?>
    ) {
        self.entries = entries
        self.configuration = configuration
        self.usesExternalChipBinding = true
        self.usesExternalPeriodBinding = false
        __externalChipID = activeChipID
        _externalSelectedPeriod = .constant(configuration.defaultPeriod)
        _externalVisibleWindow = visibleWindow
        _selectedPeriod = State(initialValue: configuration.defaultPeriod)

        let defaultDomain = configuration.periodDomainMapping?[configuration.defaultPeriod]
            ?? configuration.visibleDomainLength
        if let start = configuration.initialWindowStart {
            _scrollPositionX = State(initialValue: start)
        } else if let latest = entries.max(by: { $0.date < $1.date }) {
            _scrollPositionX = State(
                initialValue: Self.initialScrollStart(latestDate: latest.date, domain: defaultDomain)
            )
        }
    }

    /// Creates a chart whose period picker drives an external view model.
    init(
        entries: [Entry],
        configuration: StatChartConfiguration,
        selectedPeriod: Binding<StatChartPeriod>,
        activeChipID: Binding<String?>
    ) {
        self.entries = entries
        self.configuration = configuration
        self.usesExternalChipBinding = true
        self.usesExternalPeriodBinding = true
        __externalChipID = activeChipID
        _externalSelectedPeriod = selectedPeriod
        _externalVisibleWindow = .constant(nil)
        _selectedPeriod = State(initialValue: selectedPeriod.wrappedValue)

        let defaultDomain = configuration.periodDomainMapping?[selectedPeriod.wrappedValue]
            ?? configuration.visibleDomainLength
        if let start = configuration.initialWindowStart {
            _scrollPositionX = State(initialValue: start)
        } else if let latest = entries.max(by: { $0.date < $1.date }) {
            _scrollPositionX = State(
                initialValue: Self.initialScrollStart(latestDate: latest.date, domain: defaultDomain)
            )
        }
    }

    /// Creates a chart whose period picker drives an external view model.
    init(
        entries: [Entry],
        configuration: StatChartConfiguration,
        selectedPeriod: Binding<StatChartPeriod>,
        activeChipID: Binding<String?>,
        visibleWindow: Binding<StatChartVisibleWindow?>
    ) {
        self.entries = entries
        self.configuration = configuration
        self.usesExternalChipBinding = true
        self.usesExternalPeriodBinding = true
        __externalChipID = activeChipID
        _externalSelectedPeriod = selectedPeriod
        _externalVisibleWindow = visibleWindow
        _selectedPeriod = State(initialValue: selectedPeriod.wrappedValue)

        let defaultDomain = configuration.periodDomainMapping?[selectedPeriod.wrappedValue]
            ?? configuration.visibleDomainLength
        if let start = configuration.initialWindowStart {
            _scrollPositionX = State(initialValue: start)
        } else if let latest = entries.max(by: { $0.date < $1.date }) {
            _scrollPositionX = State(
                initialValue: Self.initialScrollStart(latestDate: latest.date, domain: defaultDomain)
            )
        }
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            periodPicker

            Group {
                summarySection
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDate = nil
                    }
            }

            chartContent

            if !configuration.chips.isEmpty && configuration.showChipsInline {
                chipsRow
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            containerWidth = newWidth
        }
        .onChange(of: rawSelectedDate) { _, newValue in
            if let newValue {
                if let nearest = entries.nearestEntry(for: newValue) {
                    selectedDate = nearest.date
                }
            }
        }
        .onChange(of: activeSelectedPeriod) { _, newPeriod in
            selectedDate = nil
            activeChipID = nil

            if let start = configuration.initialWindowStart {
                scrollPositionX = start
            } else if let latest = entries.max(by: { $0.date < $1.date }) {
                let domain = configuration.periodDomainMapping?[newPeriod]
                    ?? configuration.visibleDomainLength
                scrollPositionX = Self.initialScrollStart(latestDate: latest.date, domain: domain)
            }

            updateExternalVisibleWindow()
        }
        .onChange(of: scrollPositionX) {
            selectedDate = nil
            updateExternalVisibleWindow()
        }
        .onAppear {
            updateExternalVisibleWindow()
        }
    }

    private func updateExternalVisibleWindow() {
        let newWindow = StatChartVisibleWindow(
            startDate: scrollPositionX,
            endDate: scrollPositionX.addingTimeInterval(activeDomainLength),
            period: activeSelectedPeriod
        )
        // Charts can report sub-pixel date changes while settling at an edge.
        // Avoid invalidating the parent and all annotations for that jitter.
        if let previous = externalVisibleWindow,
           previous.period == newWindow.period,
           abs(previous.startDate.timeIntervalSince(newWindow.startDate)) < 0.25,
           abs(previous.endDate.timeIntervalSince(newWindow.endDate)) < 0.25 { return }
        externalVisibleWindow = newWindow
    }

    private static func initialScrollStart(latestDate: Date, domain: TimeInterval) -> Date {
        let trailingPadding: TimeInterval = domain >= 86_400 ? 86_400 : 0
        return latestDate.addingTimeInterval(-domain + trailingPadding)
    }
}

// MARK: - Period Picker

private extension StatChart {

    var periodPicker: some View {
        Picker(selection: Binding(
            get: { activeSelectedPeriod },
            set: { activeSelectedPeriod = $0 }
        )) {
            ForEach(configuration.periods) { period in
                Text(period.rawValue)
                    .tag(period)
            }
        } label: {
            EmptyView()
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Chips Row

private extension StatChart {

    var chipsRow: some View {
        VStack(spacing: 10) {
            ForEach(configuration.chips) { chip in
                let isActive = activeChipID == chip.id

                CapsuleSelectableButton(fillColor: configuration.tintColor, isSelected: isActive) {
                    if isActive {
                        activeChipID = nil
                        selectedDate = nil
                    } else {
                        activeChipID = chip.id
                        selectedDate = nil

                        switch chip.overlay {
                        case .focusDate(let date):
                            scrollPositionX = date.addingTimeInterval(-activeDomainLength / 2)
                        case .highlightPoints(let points):
                            if let first = points.first {
                                scrollPositionX = first.date.addingTimeInterval(-activeDomainLength / 2)
                            }
                        case .visibleMinMax, .referenceLine, .trendLine:
                            break
                        }
                    }
                } label: {
                    HStack {
                        Text(chip.label)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(chipValueText(for: chip))
                                .font(.subheadline.weight(.semibold))
                            if !chip.unitText.isEmpty {
                                Text(chip.unitText.uppercased())
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(isActive ? .white.opacity(0.8) : .secondary)
                            }
                        }
                    }
                }

            }
        }
    }

    /// Returns dynamic value text for `.visibleMinMax` chips, static for all others.
    private func chipValueText(for chip: StatChartChip) -> String {
        if case .visibleMinMax = chip.overlay {
            return visibleMinMaxRangeText ?? chip.valueText
        }
        return chip.valueText
    }
}

// MARK: - Summary Section

private extension StatChart {

    /// The display value – aggregate when nothing selected, specific when a date is selected.
    var displayValue: Double {
        if let selectedDate {
            return entries.summaryValue(for: selectedDate, mode: configuration.summaryMode)
        }

        return visibleEntries.summaryValue(mode: configuration.summaryMode)
    }

    /// Whether a user-driven point selection is active.
    var isShowingSelection: Bool { selectedDate != nil }

    var summarySection: some View {
        ZStack(alignment: .leading) {
            staticSummary
                .padding(.vertical, 4)
                .opacity(isShowingSelection ? 0 : 1)

            if isShowingSelection {
                selectionSummary
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.width
                    } action: { newWidth in
                        selectionCardWidth = newWidth
                    }
                    .offset(x: selectionCardOffsetX)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .geometryGroup()
    }

    /// Offset so the selection card centres above the RuleMark, clamped to parent edges.
    private var selectionCardOffsetX: CGFloat {
        guard isShowingSelection else { return 0 }
        let halfCard = selectionCardWidth / 2
        let idealX = selectionXPosition - halfCard
        let maxX = max(containerWidth - selectionCardWidth, 0)
        return max(0, min(idealX, maxX))
    }

    // ── Shared text helpers ──

    /// The static summary shown when nothing is selected.
    private var staticSummary: some View {
        summaryVStack(
            topLabel: activeChip.map { $0.label.uppercased() }
                ?? configuration.summaryModeLabel.uppercased(),
            valueText: activeChip.map { chipValueText(for: $0) }
                ?? (visibleEntries.isEmpty ? "—" : configuration.valueFormatter(displayValue)),
            unitText: activeChip.map { $0.unitText }
                ?? configuration.unitLabel,
            bottomText: visibleDateRangeText
        )
    }

    /// The selection summary shown above the RuleMark.
    private var selectionSummary: some View {
        summaryVStack(
            topLabel: statChartSelectedDateText(for: selectedDate ?? .now),
            valueText: configuration.valueFormatter(displayValue),
            unitText: configuration.unitLabel,
            bottomText: statChartWeekdayText(for: selectedDate ?? .now)
        )
    }

    /// Shared layout so both states have identical intrinsic heights.
    private func summaryVStack(topLabel: String, valueText: String, unitText: String, bottomText: String?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(topLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(valueText)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))

                Text(unitText.uppercased())
                    .font(.headline)
                    .foregroundStyle(Color.secondary)
            }

            Text(bottomText ?? " ")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
        }
    }

    /// Formatted date range currently visible in the chart window.
    var visibleDateRangeText: String? {
        let end = scrollPositionX.addingTimeInterval(activeDomainLength)
        if activeDomainLength < 86_400 {
            return "\(scrollPositionX.formatted(.dateTime.month(.abbreviated).day())) · \(scrollPositionX.formatted(.dateTime.hour().minute()))–\(end.formatted(.dateTime.hour().minute()))"
        }
        return formatDateRange(from: scrollPositionX, to: end.addingTimeInterval(-1))
    }
}

// MARK: - Chart Content

private extension StatChart {

    var chartContent: some View {
        Chart {
            if let selectedDate {
                RuleMark(x: xValue(for: selectedDate))
                    .foregroundStyle(Color(.systemGray3))
                    .lineStyle(StrokeStyle(lineWidth: statChartSelectionRuleLineWidth))
                    .zIndex(0)
            }

            dataMarks
            overlayMarks
        }
        .chartYAxis {
            AxisMarks(position: .trailing) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(configuration.valueFormatter(doubleValue))
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            // Automatic ticks are generated across the entire scrollable history.
            // At hour scale that creates thousands of offscreen labels and stalls layout.
            AxisMarks(values: StatChartAxisDates.visibleTicks(
                start: scrollPositionX, duration: activeDomainLength, period: activeSelectedPeriod
            )) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(statChartXAxisText(for: date, format: activeXAxisDateFormat))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
        }
        .chartScrollableAxes(.horizontal)
        .chartXScale(domain: xScaleDomain)
        .chartYScale(domain: yScaleDomain)
        .chartXVisibleDomain(length: activeDomainLength)
        .chartScrollPosition(x: $scrollPositionX)
        .chartXSelection(value: $rawSelectedDate)
        .chartOverlay { chart in
            GeometryReader { geometry in
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .onChange(of: selectedDate) { _, date in
                            updateSelectionX(chart: chart, geometry: geometry, date: date)
                        }
                        .onChange(of: rawSelectedDate) { _, rawDate in
                            if let rawDate, let nearest = entries.nearestEntry(for: rawDate) {
                                updateSelectionX(chart: chart, geometry: geometry, date: nearest.date)
                            }
                        }

                    chartHighlightAnnotationOverlay(chart: chart, geometry: geometry)
                    reflectionMarkers(chart: chart, geometry: geometry)
                    if visibleEntries.isEmpty {
                        Text("No data in this period")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .allowsHitTesting(false)
                    }
                }
            }
        }
        .frame(height: configuration.chartHeight)
    }

    @ViewBuilder
    private func reflectionMarkers(chart: ChartProxy, geometry: GeometryProxy) -> some View {
        ForEach(configuration.chips) { chip in
            if let icon = chip.systemImage, case .focusDate(let date) = chip.overlay,
               let plotFrame = chart.plotFrame, let x = chart.position(forX: date) {
                let frame = geometry[plotFrame]
                Button {
                    activeChipID = activeChipID == chip.id ? nil : chip.id
                    selectedDate = nil
                } label: {
                    Image(systemName: icon)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(activeChipID == chip.id ? Color.white : Color.accentColor)
                        .frame(width: 28, height: 28)
                        .background(activeChipID == chip.id ? Color.accentColor : Color(.secondarySystemGroupedBackground), in: .circle)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .accessibilityLabel(Text(verbatim: "\(chip.label), \(chip.valueText)"))
                .accessibilityIdentifier("analytics.reflection.\(chip.id)")
                .accessibilityAddTraits(activeChipID == chip.id ? [.isSelected] : [])
                .position(x: min(max(frame.minX + x, 22), geometry.size.width - 44),
                          y: frame.maxY - 18)
            }
        }
    }

    /// Convert a date into an x-position in the chart view's coordinate space.
    private func updateSelectionX(chart: ChartProxy, geometry: GeometryProxy, date: Date?) {
        guard let date,
              let plotFrame = chart.plotFrame,
              let localX = chart.position(forX: date) else { return }
        let plotOriginX = geometry[plotFrame].origin.x
        selectionXPosition = plotOriginX + localX
    }
}

// MARK: - Data Marks

private extension StatChart {

    /// Tint colour for base marks — dimmed when a highlight overlay is active.
    private var baseMarkColor: Color {
        isEmphasizingOverlay
            ? Color(.systemGray5)
            : configuration.tintColor
    }

    @ChartContentBuilder
    var dataMarks: some ChartContent {
        switch configuration.markStyle {
        case .bar(let cornerRadius):
            ForEach(renderedEntries) { entry in
                BarMark(
                    x: .value("Date", entry.date, unit: configuration.xAxisDateUnit),
                    yStart: .value("Baseline", 0),
                    yEnd: .value("Value", entry.value),
                    width: .ratio(0.9)
                )
                .cornerRadius(cornerRadius)
                .foregroundStyle(baseMarkColor)
            }

        case .line(let lineWidth, let showPoints):
            ForEach(renderedEntries) { entry in
                LineMark(
                    x: xValue(for: entry.date),
                    y: .value("Value", entry.value)
                )
                .lineStyle(StrokeStyle(lineWidth: lineWidth))
                .foregroundStyle(baseMarkColor)
                .interpolationMethod(.monotone)
            }

            if showPoints {
                ForEach(renderedEntries) { entry in
                    readingPoint(entry)
                }
            } else if let entry = isolatedVisibleEntry {
                readingPoint(entry)
            }

        case .area(let lineWidth, let opacity):
            let baseline = yScaleDomain.lowerBound
            ForEach(renderedEntries) { entry in
                AreaMark(
                    x: xValue(for: entry.date),
                    yStart: .value("Baseline", baseline),
                    yEnd: .value(configuration.unitLabel, entry.value)
                )
                .foregroundStyle(baseMarkColor.opacity(opacity))
                .interpolationMethod(.catmullRom)
            }

            ForEach(renderedEntries) { entry in
                LineMark(
                    x: xValue(for: entry.date),
                    y: .value("Value", entry.value)
                )
                .lineStyle(StrokeStyle(lineWidth: lineWidth))
                .foregroundStyle(baseMarkColor)
                .interpolationMethod(.catmullRom)
            }

            if let entry = isolatedVisibleEntry {
                readingPoint(entry)
            }

        case .point(let size):
            ForEach(renderedEntries) { entry in
                PointMark(
                    x: xValue(for: entry.date),
                    y: .value("Value", entry.value)
                )
                .symbolSize(size * size)
                .foregroundStyle(baseMarkColor)
            }
        }
    }

    private func readingPoint(_ entry: Entry) -> some ChartContent {
        PointMark(x: xValue(for: entry.date), y: .value("Value", entry.value))
            .symbolSize(36)
            .foregroundStyle(baseMarkColor)
    }
}

// MARK: - Overlay Marks

private extension StatChart {

    private var activeHighlightAnnotations: [StatChartHighlight] {
        guard let chip = activeChip else { return [] }

        switch chip.overlay {
        case .highlightPoints(let highlights):
            return highlights
        case .visibleMinMax(let maxColor, let minColor):
            return resolvedVisibleMinMaxHighlights(maxColor: maxColor, minColor: minColor)
        case .focusDate, .referenceLine, .trendLine:
            return []
        }
    }

    @ChartContentBuilder
    var overlayMarks: some ChartContent {
        if let chip = activeChip {
            switch chip.overlay {
            case .focusDate(let date):
                RuleMark(x: .value("Focus", date))
                    .foregroundStyle(configuration.tintColor.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .zIndex(2)

            case .referenceLine(let yValue):
                RuleMark(y: .value("Reference", yValue))
                    .foregroundStyle(configuration.tintColor)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .zIndex(2)

            case .highlightPoints(let highlights):
                highlightMarks(for: highlights)

            case .visibleMinMax(let maxColor, let minColor):
                highlightMarks(for: resolvedVisibleMinMaxHighlights(maxColor: maxColor, minColor: minColor))

            case .trendLine(let points):
                ForEach(points) { pt in
                    LineMark(
                        x: xValue(for: pt.date),
                        y: .value("Trend", pt.value)
                    )
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .foregroundStyle(configuration.tintColor)
                    .interpolationMethod(.catmullRom)
                    .zIndex(2)
                }
            }
        }
    }

    /// Shared chart content for annotated highlight dots (used by both
    /// `.highlightPoints` and `.visibleMinMax`).
    @ChartContentBuilder
    private func highlightMarks(for highlights: [StatChartHighlight]) -> some ChartContent {
        ForEach(highlights) { point in
            PointMark(
                x: xValue(for: point.date),
                y: .value("Value", point.value)
            )
            .symbolSize(64)
            .foregroundStyle(point.color)
            .zIndex(3)
        }
    }

    @ViewBuilder
    private func chartHighlightAnnotationOverlay(
        chart: ChartProxy,
        geometry: GeometryProxy
    ) -> some View {
        let highlights = activeHighlightAnnotations

        ForEach(highlights) { point in
            if let plotFrame = chart.plotFrame,
               let localX = chart.position(forX: point.date),
               let localY = chart.position(forY: point.value) {
                let plotRect = geometry[plotFrame]
                let x = clamped(
                    plotRect.origin.x + localX,
                    lower: plotRect.minX + 28,
                    upper: plotRect.maxX - 28
                )
                let y = highlightAnnotationY(
                    for: point,
                    in: highlights,
                    pointY: plotRect.origin.y + localY,
                    plotRect: plotRect
                )

                highlightAnnotationLabel(for: point)
                    .position(x: x, y: y)
            }
        }
    }

    private func highlightAnnotationLabel(for point: StatChartHighlight) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text(point.label.uppercased())

            Text(configuration.valueFormatter(point.value))
        }
        .font(.subheadline.weight(.semibold))
        .multilineTextAlignment(.center)
        .foregroundStyle(point.color)
        .fixedSize()
        .allowsHitTesting(false)
    }

    private func highlightAnnotationY(
        for point: StatChartHighlight,
        in highlights: [StatChartHighlight],
        pointY: CGFloat,
        plotRect: CGRect
    ) -> CGFloat {
        let labelHalfHeight: CGFloat = 18
        let labelClearance: CGFloat = 14
        let offset = labelHalfHeight + labelClearance
        let minY = plotRect.minY + labelHalfHeight
        let maxY = plotRect.maxY - labelHalfHeight
        let shouldPlaceAbove = isUpperAnnotation(for: point, in: highlights)
        let preferredY = shouldPlaceAbove ? pointY - offset : pointY + offset

        if shouldPlaceAbove, preferredY < minY {
            return clamped(pointY + offset, lower: minY, upper: maxY)
        }

        if !shouldPlaceAbove, preferredY > maxY {
            return clamped(pointY - offset, lower: minY, upper: maxY)
        }

        return clamped(preferredY, lower: minY, upper: maxY)
    }

    private func isUpperAnnotation(
        for point: StatChartHighlight,
        in highlights: [StatChartHighlight]
    ) -> Bool {
        guard let maxVal = highlights.map(\.value).max() else { return true }
        return point.value == maxVal
    }

    private func clamped(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        guard lower <= upper else { return value }
        return min(max(value, lower), upper)
    }
}

/// Calendar-aligned ticks for the viewport, with a small buffer for horizontal scrolling.
/// The number of labels is independent of how much history has been loaded.
enum StatChartAxisDates {
    static func visibleTicks(start: Date, duration: TimeInterval, period: StatChartPeriod,
                             calendar: Calendar = .current) -> [Date] {
        let component: Calendar.Component
        let count: Int
        let alignment: Calendar.Component
        switch period {
        case .oneHour: (component, count, alignment) = (.minute, 15, .hour)
        case .twoHours: (component, count, alignment) = (.minute, 30, .hour)
        case .day: (component, count, alignment) = (.hour, 6, .day)
        case .week: (component, count, alignment) = (.day, 1, .day)
        case .month: (component, count, alignment) = (.day, 7, .weekOfYear)
        case .sixMonths: (component, count, alignment) = (.month, 1, .month)
        case .year: (component, count, alignment) = (.month, 2, .month)
        }
        let end = start.addingTimeInterval(duration)
        var tick = calendar.dateInterval(of: alignment, for: start)?.start ?? start
        var dates: [Date] = []
        // Include the tick preceding the viewport and one beyond its trailing edge.
        while dates.count < 16 {
            dates.append(tick)
            if tick > end { break }
            guard let next = calendar.date(byAdding: component, value: count, to: tick),
                  next > tick else { break }
            tick = next
        }
        return dates
    }
}

// MARK: - Formatters

private func statChartSelectedDateText(for date: Date) -> String {
    date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year())
}

private func statChartWeekdayText(for date: Date) -> String {
    date.formatted(.dateTime.weekday(.wide))
}

private func statChartXAxisText(for date: Date, format: String) -> String {
    switch format {
    case "HH:mm":
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    case "HH":
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)))
    case "EEE":
        date.formatted(.dateTime.weekday(.abbreviated))
    case "d":
        date.formatted(.dateTime.day())
    case "MMM":
        date.formatted(.dateTime.month(.abbreviated))
    case "MMMMM":
        date.formatted(.dateTime.month(.narrow))
    default:
        date.formatted(.dateTime.month(.abbreviated).day())
    }
}

/// Formats a date range like "2 – 8 Mar 2026" or "28 Feb – 6 Mar 2026".
private func formatDateRange(from start: Date, to end: Date) -> String {
    let calendar = Calendar.current
    let startDay = calendar.component(.day, from: start)
    let endDay = calendar.component(.day, from: end)
    let startMonth = calendar.component(.month, from: start)
    let endMonth = calendar.component(.month, from: end)
    let startYear = calendar.component(.year, from: start)
    let endYear = calendar.component(.year, from: end)

    let endMonthStr = statChartMonthText(for: end)

    if startYear != endYear {
        let startMonthStr = statChartMonthText(for: start)
        return "\(startDay) \(startMonthStr) \(startYear) – \(endDay) \(endMonthStr) \(endYear)"
    } else if startMonth != endMonth {
        let startMonthStr = statChartMonthText(for: start)
        return "\(startDay) \(startMonthStr) – \(endDay) \(endMonthStr) \(endYear)"
    } else {
        return "\(startDay) – \(endDay) \(endMonthStr) \(endYear)"
    }
}

private func statChartMonthText(for date: Date) -> String {
    date.formatted(.dateTime.month(.abbreviated))
}

// MARK: - Previews

/// A simple preview entry for demonstration.
private struct PreviewEntry: StatChartEntry {
    let id = UUID()
    let date: Date
    let value: Double
}

private extension Array where Element == PreviewEntry {
    static var sample: [PreviewEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<30).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let value = Double(abs(((offset * 1_103) ^ 0xABCDEF) % 9_000) + 1_000)
            return PreviewEntry(date: date, value: value)
        }
        .sorted { $0.date < $1.date }
    }

    static var sampleChips: [StatChartChip] {
        let entries = Self.sample
        let values = entries.map(\.value)
        let avg = values.reduce(0, +) / Double(values.count)
        let best = entries.max(by: { $0.value < $1.value })!
        let worst = entries.min(by: { $0.value < $1.value })!

        return [
            .init(
                label: "Average",
                valueText: Int(avg).formatted(),
                unitText: "steps",
                overlay: .referenceLine(y: avg)
            ),
            .init(
                label: "Range",
                valueText: "\(Int(worst.value))–\(Int(best.value))",
                unitText: "steps",
                overlay: .visibleMinMax(maxColor: .accentColor, minColor: .secondary)
            ),
            .init(
                label: "Best Day",
                valueText: Int(best.value).formatted(),
                unitText: "steps",
                overlay: .focusDate(best.date)
            )
        ]
    }
}

#Preview("Bar Chart") {
    StatChart(
        entries: [PreviewEntry].sample,
        configuration: .init(
            markStyle: .bar(),
            tintColor: .accentColor,
            unitLabel: "steps",
            chips: [PreviewEntry].sampleChips
        )
    )
    .padding(.horizontal)
}

#Preview("Line Chart") {
    StatChart(
        entries: [PreviewEntry].sample,
        configuration: .init(
            markStyle: .line(showPoints: true),
            tintColor: .red,
            unitLabel: "bpm",
            summaryMode: .average
        )
    )
    .padding(.horizontal)
}

#Preview("Area Chart") {
    StatChart(
        entries: [PreviewEntry].sample,
        configuration: .init(
            markStyle: .area(),
            tintColor: .green,
            unitLabel: "kcal",
            summaryMode: .total
        )
    )
    .padding(.horizontal)
}

#Preview("Point Chart") {
    StatChart(
        entries: [PreviewEntry].sample,
        configuration: .init(
            markStyle: .point(),
            tintColor: .purple,
            unitLabel: "kg",
            summaryMode: .latest
        )
    )
    .padding(.horizontal)
}

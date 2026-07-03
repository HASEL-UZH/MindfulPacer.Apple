//
//  EditReflectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI
import Charts
import SwiftData

// MARK: - Presentation Enums

enum EditReflectionNavigationDestination: Hashable {
    case activity
    case subactivity(Activity?)
    case mood
}

enum EditReflectionSheet: Identifiable {
    case symptomValueView(Symptom)
    
    var id: Int {
        switch self {
        case .symptomValueView: 0
        }
    }
}

enum EditReflectionAlert: Identifiable {
    case deleteConfirmation
    case unableToSaveReflection
    
    var id: Int {
        hashValue
    }
}

// MARK: - EditReflectionView

// swiftlint:disable:next type_body_length
struct EditReflectionView: View {
    
    // MARK: Properties
    
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: EditReflectionViewModel = ScenesContainer.shared.editReflectionViewModel()
    @FocusState private var focusedField: FocusField?

    @Query(sort: \Activity.name) private var activities: [Activity]
    
    @AppStorage(ModeOfUse.appStorageKey, store: DefaultsStore.shared)
    private var modeOfUseRaw: String = ModeOfUse.essentials.rawValue
    
    private var modeOfUse: ModeOfUse {
        ModeOfUse(rawValue: modeOfUseRaw) ?? .essentials
    }
    
    var reflection: Reflection?
    var onReflectionCreation: (() -> Void)?

    private enum FocusField: Hashable {
        case additionalInformation
    }
    
    // MARK: Body
    
    var body: some View {
        EntryFormSheet(
            title: viewModel.navigationTitle,
            headerTitle: reflectionHeaderTitle,
            headerSystemImage: reflectionHeaderSystemImage,
            headerTint: reflectionHeaderTint,
            canSave: canSave,
            onCancel: { dismiss() },
            onSave: { saveOrDismissKeyboard() }
        ) {
            primaryRows
        } content: {
            secondarySections
        } additionalToolbarContent: {
            keyboardToolbarContent
        }
        .scrollDismissesKeyboard(.interactively)
        .onViewFirstAppear {
            viewModel.onViewFirstAppear()
            viewModel.configureMode(with: reflection)
        }
        .alert(item: $viewModel.activeAlert) { alert in
            alertContent(for: alert)
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
    }
    
    // MARK: Alert Content
    
    private func alertContent(for alert: EditReflectionAlert) -> Alert {
        switch alert {
        case .deleteConfirmation:
            return reviewDeletionConfirmationAlert
        case .unableToSaveReflection:
            return unableToSaveReflectionAlert
        }
    }
    
    // MARK: Sheet Content
    
    @ViewBuilder
    private func sheetContent(for sheet: EditReflectionSheet) -> some View {
        switch sheet {
        case .symptomValueView(let symptom):
            Group {
                switch symptom {
                case .wellBeing:
                    SymptomValueView(symptom: viewModel.wellBeingBinding)
                case .fatigue:
                    SymptomValueView(symptom: viewModel.fatigueBinding)
                case .shortnessOfBreath:
                    SymptomValueView(symptom: viewModel.shortnessOfBreathBinding)
                case .sleepDisorder:
                    SymptomValueView(symptom: viewModel.sleepDisorderBinding)
                case .cognitiveImpairment:
                    SymptomValueView(symptom: viewModel.cognitiveImpairmentBinding)
                case .physicalPain:
                    SymptomValueView(symptom: viewModel.physicalPainBinding)
                case .depressionOrAnxiety:
                    SymptomValueView(symptom: viewModel.depressionOrAnxietyBinding)
                }
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: Header

    private var reflectionHeaderTitle: String {
        viewModel.selectedSubactivity?.name ??
        viewModel.selectedActivity?.name ??
        String(localized: "Reflection")
    }

    private var reflectionHeaderSystemImage: String {
        viewModel.selectedSubactivity?.icon ??
        viewModel.selectedActivity?.icon ??
        "book.closed.fill"
    }

    private var reflectionHeaderTint: Color {
        viewModel.selectedActivity == nil ? .secondary : Color("BrandPrimary")
    }

    // MARK: Primary Rows

    @ViewBuilder
    private var primaryRows: some View {
        formRow(title: "Date", systemImage: "calendar") {
            DatePicker(
                "Date",
                selection: $viewModel.date,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
        }

        activityRow

        if viewModel.selectedActivity != nil {
            subactivityRow
        }

        if modeOfUse == .expanded {
            moodRow
        }

        wellBeingRow
    }

    @ViewBuilder
    private var activityRow: some View {
        formRow(title: "Activity", systemImage: "rectangle.grid.2x2") {
            Menu {
                Button("Uncategorized", systemImage: "questionmark") {
                    viewModel.selectedActivity = nil
                }

                ForEach(activities) { activity in
                    Button(activity.name, systemImage: activity.icon) {
                        viewModel.selectedActivity = activity
                    }
                }
            } label: {
                rowValue(
                    viewModel.selectedActivity?.name ?? String(localized: "Select"),
                    isRequiredMissing: viewModel.selectedActivity == nil
                )
            }
        }
    }

    @ViewBuilder
    private var subactivityRow: some View {
        if let activity = viewModel.selectedActivity {
            formRow(title: "Subactivity", systemImage: "rectangle.grid.3x3") {
                Menu {
                    Button("None", systemImage: "minus.circle") {
                        viewModel.selectedSubactivity = nil
                    }

                    ForEach((activity.subactivities ?? []).sorted { $0.name < $1.name }) { subactivity in
                        Button(subactivity.name, systemImage: subactivity.icon) {
                            viewModel.selectedSubactivity = subactivity
                        }
                    }
                } label: {
                    rowValue(
                        viewModel.selectedSubactivity?.name ?? String(localized: "None")
                    )
                }
            }
        }
    }

    private var moodRow: some View {
        formRow(title: "Mood", systemImage: "face.smiling") {
            Menu {
                Button("None", systemImage: "minus.circle") {
                    viewModel.selectedMood = nil
                }

                ForEach(DefaultMoodData.moods, id: \.emoji) { mood in
                    Button("\(mood.emoji) \(mood.text)") {
                        viewModel.selectedMood = mood
                    }
                }
            } label: {
                rowValue(
                    viewModel.selectedMood.map { "\($0.emoji) \($0.text)" } ?? String(localized: "Not Set")
                )
            }
        }
    }

    private var wellBeingRow: some View {
        formRow(title: viewModel.wellBeing.displayName, systemImage: viewModel.wellBeing.icon) {
            Menu {
                Button("Not Set", systemImage: "minus.circle") {
                    viewModel.wellBeing.setValue(nil)
                }

                ForEach(0 ..< viewModel.wellBeing.numOptions, id: \.self) { value in
                    Button(viewModel.wellBeing.description(for: value), systemImage: "\(value).circle") {
                        viewModel.wellBeing.setValue(value)
                    }
                }
            } label: {
                rowValue(
                    viewModel.wellBeing.description
                )
            }
        }
    }

    // MARK: Secondary Sections

    @ViewBuilder
    private var secondarySections: some View {
        if modeOfUse == .expanded {
            Section("Symptoms") {
                ForEach(editableSymptoms, id: \.displayName) { symptom in
                    symptomRow(symptom)
                }
            }

            Section {
                Toggle(isOn: $viewModel.didTriggerCrash) {
                    Label("Triggered Crash", systemImage: "exclamationmark.triangle.fill")
                        .font(.body)
                }
                .tint(.accentColor)

                TextField("Additional Information", text: $viewModel.additionalInformation, axis: .vertical)
                    .focused($focusedField, equals: .additionalInformation)
                    .lineLimit(3...8)
            }
        }

        if !viewModel.isReflectionDeleted {
            reminderSection
        }

        if viewModel.mode == .edit {
            Section {
                deleteButton
            }
        }
    }

    private func symptomRow(_ symptom: Symptom) -> some View {
        Button {
            viewModel.presentSymptomValueSheet(for: symptom)
        } label: {
            HStack(spacing: 12) {
                Label(symptom.displayName, systemImage: symptom.icon)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text(symptom.description)
                    .font(.body)
                    .foregroundStyle(symptom.value == nil ? Color.secondary : Color.accentColor)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var reminderSection: some View {
        if let reflection,
           let reminderMeasurementType = reflection.measurementType,
           let reminderType = reflection.reminderType {
            Section("Reminder") {
                HStack {
                    Label(reminderMeasurementType.localized, systemImage: reminderMeasurementType.icon)
                        .font(.body)
                        .foregroundStyle(reminderMeasurementType.color)

                    Spacer()

                    Text(reflection.reminderTriggerSummary)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                TriggerDataChartView(reflection: reflection)
                    .frame(height: 250)
            }
        } else if reflection != nil {
            Section("Reminder") {
                Text("This reflection was created manually.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Row Helpers

    private func formRow<Field: View>(
        title: String,
        systemImage: String,
        @ViewBuilder field: () -> Field
    ) -> some View {
        HStack(spacing: 12) {
            Label(title, systemImage: systemImage)
                .font(.body)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer(minLength: 12)

            field()
                .frame(maxWidth: 230, alignment: .trailing)
        }
    }

    private func rowValue(
        _ title: String,
        isRequiredMissing: Bool = false
    ) -> some View {
        Text(title)
            .lineLimit(1)
            .truncationMode(.middle)
        .font(.body)
        .foregroundStyle(isRequiredMissing ? Color.red : Color.accentColor)
    }

    private var editableSymptoms: [Symptom] {
        [
            viewModel.fatigue,
            viewModel.shortnessOfBreath,
            viewModel.sleepDisorder,
            viewModel.cognitiveImpairment,
            viewModel.physicalPain,
            viewModel.depressionOrAnxiety
        ]
    }

    // MARK: Save

    private var canSave: Bool {
        switch viewModel.mode {
        case .create:
            !viewModel.isActionButtonDisabled
        case .edit:
            !viewModel.isSaveButtonDisabled
        }
    }

    private func saveOrDismissKeyboard() {
        if focusedField != nil {
            focusedField = nil
            return
        }

        switch viewModel.mode {
        case .create:
            viewModel.createReflection()
            onReflectionCreation?()
            dismiss()

        case .edit:
            viewModel.saveReflection(reflection)
            dismiss()
        }
    }
    
    // MARK: Delete Button
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.presentAlert(.deleteConfirmation)
        } label: {
            Label("Delete Reflection", systemImage: "trash")
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
        }
        .tint(.red)
    }

    // MARK: Toolbar Content

    @ToolbarContentBuilder
    private var keyboardToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()

            Button("Done") {
                focusedField = nil
            }
        }
    }
    
    // MARK: Reflection Deletion Confirmation Alert
    
    private var reviewDeletionConfirmationAlert: Alert {
        Alert(
            title: Text("Delete Reflection"),
            message: Text("Are you sure you want to delete this reflection? This action cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                viewModel.deleteReflection(reflection)
                dismiss()
            },
            secondaryButton: .cancel()
        )
    }
    
    // MARK: - Unable to Save Reflection Alert
    
    private var unableToSaveReflectionAlert: Alert {
        Alert(
            title: Text("Save Error"),
            message: Text("Unable to save your Reflection.\nPlease try again.\nIf this problem persists, please contact us."),
            dismissButton: .default(Text("Ok"))
        )
    }
}

// MARK: - TriggerDataChartView

struct TriggerDataChartView: View {
    let reflection: Reflection
    @State private var selectedDate: Date?

    @State private var cachedSamples: [MeasurementSample] = []
    @State private var series: [MeasurementSample] = []
    @State private var downsampled: [MeasurementSample] = []
    @State private var yDomain: ClosedRange<Double> = 0...1
    @State private var xAxisValues: [Date] = []
    @State private var windowStart: Date?
    @State private var windowEnd: Date?
    @State private var chartColor: Color = .teal
    @State private var yLabel: String = "Value"
    @State private var isReady = false

    private let maxDataPoints = 200

    var body: some View {
        Group {
            if !isReady {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if downsampled.isEmpty {
                Text("No trigger data was saved for this reflection.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            } else {
                Chart {
                    if let start = windowStart, let end = windowEnd, let interval = reflection.interval, interval != .oneDay {
                        RectangleMark(
                            xStart: .value("Start", start),
                            xEnd: .value("End", end)
                        )
                        .foregroundStyle(chartColor.opacity(0.1))
                    }

                    ForEach(downsampled, id: \.date) { s in
                        LineMark(
                            x: .value("Time", s.date),
                            y: .value(yLabel, s.value)
                        )
                        .foregroundStyle(chartColor)
                        .interpolationMethod(.catmullRom)
                    }

                    if let threshold = reflection.threshold {
                        RuleMark(y: .value("Goal", threshold))
                            .foregroundStyle(reflection.reminderType?.color ?? .primary)
                            .lineStyle(.init(lineWidth: 1, dash: [5]))
                            .annotation(position: .top, alignment: .leading) {
                                Text("\(threshold)")
                                    .font(.caption2)
                                    .foregroundColor(reflection.reminderType?.color ?? .primary)
                            }
                    }
                }
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(values: xAxisValues) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: xAxisFormatStyle, collisionResolution: .greedy)
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geo in
                        if let selectedDate {
                            let xPos = proxy.position(forX: selectedDate) ?? 0
                            Rectangle()
                                .fill(chartColor.opacity(0.3))
                                .frame(width: 2, height: geo.size.height)
                                .position(x: xPos, y: geo.size.height / 2)

                            if let s = nearestSample(to: selectedDate) {
                                valuePopover(for: s)
                                    .position(x: xPos, y: geo.size.height / 2 - 40)
                            }
                        }
                    }
                }
                .chartXSelection(value: $selectedDate)
            }
        }
        .task(id: reflection.id) {
            await buildCachesAsync()
        }
    }

    // MARK: - Build caches (off main thread)

    private func buildCachesAsync() async {
        // Capture immutable inputs before going off-thread.
        let triggerData = reflection.triggerData
        let interval = reflection.interval
        let threshold = reflection.threshold

        // Do the expensive work (decode, sort, rolling sums, downsample) off-main.
        let result: ChartCacheResult? = await Task.detached(priority: .userInitiated) {
            let samples = Self.decodeSamplesStatic(from: triggerData)
            guard !samples.isEmpty else { return nil as ChartCacheResult? }

            let sorted = samples.sorted { $0.date < $1.date }
            let isSteps = samples.first?.type == .steps
            let isOneDay = (interval == .oneDay)
            let windowSeconds = interval?.timeInterval ?? 0

            let s: [MeasurementSample]
            if isSteps {
                if isOneDay {
                    s = Self.runningTotalSeriesStatic(sorted)
                } else {
                    s = Self.rollingSumSeriesStatic(sorted, window: windowSeconds)
                }
            } else {
                s = sorted
            }

            let ds = Self.downsampleStatic(s, to: 200)
            let xAxis = Self.makeXAxisValuesStatic(for: s)
            let window = Self.makeTriggerWindowStatic(for: s, interval: interval)
            let yDom = Self.makeYDomainStatic(for: s, threshold: threshold)
            let color: Color = (samples.first?.type == .heartRate) ? .pink : .teal
            let label = (samples.first?.type == .steps)
                ? (isOneDay ? "Steps (running total)" : "Steps (rolling sum)")
                : "BPM"

            return ChartCacheResult(
                samples: samples, series: s, downsampled: ds,
                yDomain: yDom, xAxisValues: xAxis,
                windowStart: window.0, windowEnd: window.1,
                chartColor: color, yLabel: label
            )
        }.value

        // Apply the results on the main thread.
        guard let result else {
            isReady = true
            return
        }

        cachedSamples = result.samples
        series = result.series
        downsampled = result.downsampled
        yDomain = result.yDomain
        xAxisValues = result.xAxisValues
        windowStart = result.windowStart
        windowEnd = result.windowEnd
        chartColor = result.chartColor
        yLabel = result.yLabel
        isReady = true
    }

    /// Intermediate struct to shuttle computed results back to the main thread.
    private struct ChartCacheResult: Sendable {
        let samples: [MeasurementSample]
        let series: [MeasurementSample]
        let downsampled: [MeasurementSample]
        let yDomain: ClosedRange<Double>
        let xAxisValues: [Date]
        let windowStart: Date?
        let windowEnd: Date?
        let chartColor: Color
        let yLabel: String
    }

    // MARK: - Helpers (static for off-main-thread use)

    nonisolated private static func decodeSamplesStatic(from data: Data?) -> [MeasurementSample] {
        guard let data else { return [] }
        do { return try JSONDecoder().decode([MeasurementSample].self, from: data) }
        catch {
            print("DEBUGY: Error decoding triggerData: \(error)")
            return []
        }
    }

    nonisolated private static func rollingSumSeriesStatic(_ data: [MeasurementSample], window: TimeInterval) -> [MeasurementSample] {
        guard window > 0 else { return data }
        var out: [MeasurementSample] = []
        var q: [(Date, Double)] = []
        var sum: Double = 0
        out.reserveCapacity(data.count)

        for s in data {
            sum += s.value
            q.append((s.date, s.value))
            let cutoff = s.date.addingTimeInterval(-window)
            while let first = q.first, first.0 < cutoff {
                sum -= first.1
                q.removeFirst()
            }
            out.append(.init(type: s.type, value: sum, date: s.date))
        }
        return out
    }

    nonisolated private static func runningTotalSeriesStatic(_ data: [MeasurementSample]) -> [MeasurementSample] {
        var out: [MeasurementSample] = []
        out.reserveCapacity(data.count)
        var total: Double = 0
        for s in data {
            total += s.value
            out.append(.init(type: s.type, value: total, date: s.date))
        }
        return out
    }

    nonisolated private static func downsampleStatic(_ data: [MeasurementSample], to maxPoints: Int) -> [MeasurementSample] {
        guard data.count > maxPoints else { return data }
        var out: [MeasurementSample] = []
        out.reserveCapacity(maxPoints)
        let bucketSize = Double(data.count) / Double(maxPoints)
        for i in 0..<maxPoints {
            let start = Int(Double(i) * bucketSize)
            let end   = min(Int(Double(i + 1) * bucketSize), data.count)
            if start < end {
                if let pick = data[start..<end].max(by: { $0.value < $1.value }) {
                    out.append(pick)
                }
            }
        }
        return out
    }

    nonisolated private static func makeYAxisRangeStatic(for values: [Double], threshold: Double?) -> ClosedRange<Double> {
        let minY = values.min() ?? 0
        let maxY = values.max() ?? 1
        let t = threshold ?? maxY
        let overallMin = min(minY, t)
        let overallMax = max(maxY, t)
        let padding = max(5, (overallMax - overallMin) * 0.1)
        return (overallMin - padding)...(overallMax + padding)
    }

    nonisolated private static func makeYDomainStatic(for series: [MeasurementSample], threshold: Int?) -> ClosedRange<Double> {
        makeYAxisRangeStatic(for: series.map { $0.value }, threshold: threshold.map(Double.init))
    }

    nonisolated private static func makeXAxisValuesStatic(for series: [MeasurementSample]) -> [Date] {
        guard let first = series.first?.date, let last = series.last?.date, first < last else { return [] }
        let mid = first.addingTimeInterval(last.timeIntervalSince(first) / 2)
        return [first, mid, last]
    }

    nonisolated private static func makeTriggerWindowStatic(for series: [MeasurementSample], interval: Reminder.Interval?) -> (Date?, Date?) {
        guard let end = series.last?.date, let seconds = interval?.timeInterval else { return (nil, nil) }
        return (end.addingTimeInterval(-seconds), end)
    }

    private var xAxisFormatStyle: Date.FormatStyle {
        guard let interval = reflection.interval else { return .dateTime.hour().minute().second() }
        switch interval {
        case .immediately, .oneMinute, .twoMinutes: return .dateTime.hour().minute().second()
        case .fiveMinutes, .tenMinutes,
             .fifteenMinutes, .thirtyMinutes,
             .oneHour, .twoHours: return .dateTime.hour().minute()
        case .fourHours, .oneDay: return .dateTime.hour()
        }
    }

    private func nearestSample(to date: Date) -> MeasurementSample? {
        guard !series.isEmpty else { return nil }
        return series.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }

    // MARK: - Popover

    @ViewBuilder
    private func valuePopover(for sample: MeasurementSample) -> some View {
        let isSteps = (cachedSamples.first?.type == .steps)
        let isOneDay = (reflection.interval == .oneDay)

        VStack(alignment: .leading, spacing: 2) {
            Text(sample.date.formatted(.dateTime.hour().minute().second()))
                .font(.caption)
                .foregroundColor(chartColor)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(sample.value))")
                    .font(.body.weight(.bold))
                Text(isSteps ? (isOneDay ? "steps total" : "steps in window") : "bpm")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8).fill(Material.thick)
        }
    }
}

// MARK: - Array+Ext

fileprivate extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
        if range.startIndex >= self.startIndex && range.endIndex <= self.endIndex {
            return self[range]
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.editReflectionViewModel()
    
    return EditReflectionView(viewModel: viewModel) {}
        .tint(Color("BrandPrimary"))
}

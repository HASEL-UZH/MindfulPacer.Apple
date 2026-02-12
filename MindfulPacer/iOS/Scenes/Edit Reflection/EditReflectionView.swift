//
//  EditReflectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI
import Charts

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
    
    @AppStorage(ModeOfUse.appStorageKey, store: DefaultsStore.shared)
    private var modeOfUseRaw: String = ModeOfUse.essentials.rawValue
    
    private var modeOfUse: ModeOfUse {
        ModeOfUse(rawValue: modeOfUseRaw) ?? .essentials
    }
    
    var reflection: Reflection?
    var onReflectionCreation: (() -> Void)?
    
    // MARK: Body
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        date
                        
                        VStack(spacing: 0) {
                            activity
                            if viewModel.selectedActivity.isNotNil {
                                Divider()
                                subactivity
                            }
                        }
                        
                        if modeOfUse == .expanded {
                            mood
                        }
                        
                        wellBeing
                        
                        if modeOfUse == .expanded {
                            symptoms(width: proxy.size.width / 2)
                            triggerCrash
                            additionalInformation
                        }
                        
                        if !viewModel.isReflectionDeleted {
                            reminder
                        }
                        
                        if viewModel.mode == .edit {
                            deleteButton
                        }
                    }
                    .padding(.horizontal)
                }
                .safeAreaPadding(.bottom)
            }
            .foregroundStyle(Color.primary)
            .scrollContentBackground(.hidden)
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .navigationTitle(viewModel.navigationTitle)
            .safeAreaInset(edge: .bottom) {
                if viewModel.mode == .create {
                    createButton
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    hideKeyboardButton
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.mode == .edit {
                        Button("Save") {
                            viewModel.saveReflection(reflection)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .fontWeight(.semibold)
                        .disabled(viewModel.isSaveButtonDisabled)
                    }
                }
            }
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
            .navigationDestination(for: EditReflectionNavigationDestination.self) { destination in
                navigationDestination(for: destination)
            }
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
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(16)
        }
    }
    
    // MARK: Navigation Destination
    
    @ViewBuilder
    private func navigationDestination(for destination: EditReflectionNavigationDestination) -> some View {
        switch destination {
        case .activity:
            ActivityView(viewModel: viewModel)
        case .subactivity(let activity):
            SubactivityView(
                activity: activity.unsafelyUnwrapped,
                viewModel: viewModel
            )
        case .mood:
            MoodView(viewModel: viewModel)
        }
    }
    
    // MARK: Date
    
    private var date: some View {
        Card {
            DatePicker(selection: $viewModel.date) {
                IconLabel(
                    icon: "calendar",
                    title: String(localized: "Date"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)
            }
        }
    }
    
    // MARK: Activity
    
    private var activity: some View {
        NavigationLink(value: EditReflectionNavigationDestination.activity) {
            HStack {
                IconLabel(
                    icon: "rectangle.grid.2x2.fill",
                    title: String(localized: "Activity"),
                    labelColor: viewModel.selectedActivity.isNil ? Color.red : Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)
                
                Spacer(minLength: 16)
                
                HStack(spacing: 4) {
                    if let activity = viewModel.selectedActivity {
                        Text(activity.name)
                            .foregroundStyle(Color(.systemGray2))
                            .fixedSize(horizontal: true, vertical: false)
                    } else {
                        Label("Uncategorized", systemImage: "questionmark")
                            .foregroundStyle(Color.red)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background {
                if viewModel.selectedActivity.isNil {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
                } else {
                    UnevenRoundedRectangle(cornerRadii: .init(topLeading: 16, topTrailing: 16))
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
                }
            }
        }
    }
    
    // MARK: Subactivity
    
    private var subactivity: some View {
        NavigationLink(value: EditReflectionNavigationDestination.subactivity(viewModel.selectedActivity)) {
            HStack {
                IconLabel(
                    icon: "rectangle.grid.3x3.fill",
                    title: String(localized: "Subactivity"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)
                
                Spacer(minLength: 16)
                
                HStack(spacing: 4) {
                    if let subactivity = viewModel.selectedSubactivity {
                        Text(subactivity.name)
                            .foregroundStyle(Color(.systemGray2))
                            .fixedSize(horizontal: true, vertical: false)
                    }
                    
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background {
                UnevenRoundedRectangle(cornerRadii: .init(bottomLeading: 16, bottomTrailing: 16))
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }
    }
    
    // MARK: Mood
    
    private var mood: some View {
        NavigationLink(value: EditReflectionNavigationDestination.mood) {
            Card {
                HStack {
                    IconLabel(
                        icon: "face.smiling.fill",
                        title: String(localized: "Mood"),
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .layoutPriority(1)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        if let mood = viewModel.selectedMood {
                            Text(mood.emoji)
                                .frame(width: 24, height: 24)
                        }
                        
                        Icon(name: "chevron.right", color: Color(.systemGray2))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }
    
    // MARK: Well Being
    
    private var wellBeing: some View {
        Button {
            viewModel.presentSymptomValueSheet(for: .wellBeing(nil))
        } label: {
            Card {
                HStack {
                    IconLabel(
                        icon: viewModel.wellBeing.icon,
                        title: viewModel.wellBeing.displayName,
                        labelColor: Color("BrandPrimary"),
                        background: true
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    Spacer()
                    
                    Text(viewModel.wellBeing.description)
                        .foregroundColor(viewModel.wellBeing.description == "Not Set" ? Color(.systemGray2) : viewModel.wellBeing.color)
                }
            }
        }
    }
    
    // MARK: Symptoms
    
    @ViewBuilder private func symptoms(width: CGFloat) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(spacing: 16), count: 2),
            spacing: 16
        ) {
            Group {
                symptomCard(for: viewModel.fatigue)
                symptomCard(for: viewModel.shortnessOfBreath)
                symptomCard(for: viewModel.sleepDisorder)
                symptomCard(for: viewModel.cognitiveImpairment)
                symptomCard(for: viewModel.physicalPain)
                symptomCard(for: viewModel.depressionOrAnxiety)
            }
            .frame(maxWidth: width)
        }
    }
    
    // MARK: Symptom Card
    
    @ViewBuilder private func symptomCard(for symptom: Symptom) -> some View {
        Button {
            viewModel.presentSymptomValueSheet(for: symptom)
        } label: {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: symptom.icon,
                    title: symptom.displayName,
                    labelColor: Color("BrandPrimary"),
                    background: true,
                    axis: .vertical,
                    truncationMode: symptom.truncationMode
                )
            ) {
                Text(symptom.description)
                    .foregroundColor(symptom.description == "Not Set" ? Color(.systemGray2) : symptom.color)
            }
        }
    }
    
    // MARK: Trigger Crash
    
    private var triggerCrash: some View {
        Card {
            Toggle(isOn: $viewModel.didTriggerCrash) {
                IconLabel(
                    icon: "exclamationmark.triangle.fill",
                    title: String(localized: "Did this trigger a crash?"),
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .layoutPriority(1)
            }
            .tint(.accentColor)
        }
    }
    
    // MARK: Additional Information
    
    private var additionalInformation: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "pencil.line",
                title: String(localized: "Additional Information"),
                labelColor: Color("BrandPrimary"),
                background: true
            )
        ) {
            TextField("You can write anything here", text: $viewModel.additionalInformation, axis: .vertical)
        }
    }
    
    // MARK: - Reminder
    
    @ViewBuilder
    private var reminder: some View {
        VStack(spacing: 16) {
            if let reflection {
                if let reminderMeasurementType = reflection.measurementType,
                   let reminderType = reflection.reminderType {
                    IconLabelGroupBox(
                        label: IconLabel(
                            icon: "alarm",
                            title: String(localized: "Reminder"),
                            labelColor: Color("BrandPrimary"),
                            background: true
                        ),
                        description:
                            Text("View the data that triggered this reminder.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    ) {
                        Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    IconLabel(
                                        icon: reminderMeasurementType.icon,
                                        title: reminderMeasurementType.rawValue,
                                        labelColor: reminderMeasurementType == .heartRate ? .pink : .teal
                                    )
                                    .font(.subheadline.weight(.semibold))
                                    
                                    Text(reflection.reminderTriggerSummary)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Icon(
                                    name: "alarm",
                                    color: reminderType.color,
                                    background: true
                                )
                            }
                            .foregroundStyle(Color.primary)
                        }
                    } footer: {
                        TriggerDataChartView(reflection: reflection)
                            .frame(height: 250)
                    }
                    .iconLabelGroupBoxStyle(.divider)
                } else {
                    Card(backgroundColor: Color(.tertiarySystemFill)) {
                        IconLabel(
                            icon: "person",
                            title: String(localized: "Manually Created Reflection"),
                            labelColor: .secondary,
                            background: true
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .layoutPriority(1)
                    }
                }
            }
        }
    }
    
    // MARK: Create Button
    
    private var createButton: some View {
        PrimaryButton(title: String(localized: "Create")) {
            viewModel.createReflection()
            onReflectionCreation?()
            dismiss()
        }
        .padding([.horizontal, .top])
        .background(.ultraThinMaterial)
        .disabled(viewModel.isActionButtonDisabled)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    // MARK: Delete Button
    
    private var deleteButton: some View {
        PrimaryButton(
            title: String(localized: "Delete Reflection"),
            icon: "trash",
            color: .red
        ) {
            viewModel.presentAlert(.deleteConfirmation)
        }
    }
    
    // MARK: Hide Keyboard Button
    
    private var hideKeyboardButton: some View {
        Button {
            hideKeyboard()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down.fill")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
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

    // Cache all heavy derived data once per reflection.id (+ date if needed)
    @State private var cachedSamples: [MeasurementSample] = []
    @State private var series: [MeasurementSample] = []
    @State private var downsampled: [MeasurementSample] = []
    @State private var yDomain: ClosedRange<Double> = 0...1
    @State private var xAxisValues: [Date] = []
    @State private var windowStart: Date?
    @State private var windowEnd: Date?
    @State private var chartColor: Color = .teal
    @State private var yLabel: String = "Value"

    private let maxDataPoints = 200

    var body: some View {
        Group {
            if downsampled.isEmpty {
                Text("No trigger data was saved for this reflection.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(height: 150)
            } else {
                Chart {
                    if let start = windowStart, let end = windowEnd {
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
                        .interpolationMethod(.catmullRom) // change to .linear for even faster
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
        // Rebuild caches when the reflection changes
        .onAppear(perform: buildCachesIfNeeded)
        .onChange(of: reflection.id) { _, _ in buildCaches() }
        // If your trigger data can change while the view is alive, also watch triggerData:
        // .onChange(of: reflection.triggerData) { _, _ in buildCaches() }
    }

    // MARK: - Build caches once

    @MainActor
    private func buildCachesIfNeeded() {
        if series.isEmpty { buildCaches() }
    }

    @MainActor
    private func buildCaches() {
        // 1) Decode once
        let samples = decodeSamples(from: reflection.triggerData) // cheap Data→Array
        cachedSamples = samples

        // 2) Sort once
        let sorted = samples.sorted { $0.date < $1.date }

        // 3) Compute series once
        let isSteps = samples.first?.type == .steps
        let interval = reflection.interval
        let isOneDay = (interval == .oneDay)
        let windowSeconds = interval?.timeInterval ?? 0

        let s: [MeasurementSample]
        if isSteps {
            if isOneDay {
                s = runningTotalSeries(sorted)
            } else {
                s = rollingSumSeries(sorted, window: windowSeconds)
            }
        } else {
            s = sorted // heart rate raw
        }
        series = s

        // 4) Downsample once
        downsampled = downsample(s, to: maxDataPoints)

        // 5) Precompute axes once
        xAxisValues = makeXAxisValues(for: s)
        (windowStart, windowEnd) = makeTriggerWindow(for: s, interval: interval)

        // 6) Y domain once
        yDomain = makeYDomain(for: s, threshold: reflection.threshold)

        // 7) Static bits
        chartColor = (samples.first?.type == .heartRate) ? .pink : .teal
        yLabel = (samples.first?.type == .steps)
            ? (isOneDay ? "Steps (running total)" : "Steps (rolling sum)")
            : "BPM"
    }

    // MARK: - Helpers (pure functions)

    private func decodeSamples(from data: Data?) -> [MeasurementSample] {
        guard let data else { return [] }
        do { return try JSONDecoder().decode([MeasurementSample].self, from: data) }
        catch {
            print("DEBUGY: Error decoding triggerData: \(error)")
            return []
        }
    }

    private func rollingSumSeries(_ data: [MeasurementSample], window: TimeInterval) -> [MeasurementSample] {
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

    private func runningTotalSeries(_ data: [MeasurementSample]) -> [MeasurementSample] {
        var out: [MeasurementSample] = []
        out.reserveCapacity(data.count)
        var total: Double = 0
        for s in data {
            total += s.value
            out.append(.init(type: s.type, value: total, date: s.date))
        }
        return out
    }

    private func downsample(_ data: [MeasurementSample], to maxPoints: Int) -> [MeasurementSample] {
        guard data.count > maxPoints else { return data }
        var out: [MeasurementSample] = []
        out.reserveCapacity(maxPoints)
        let bucketSize = Double(data.count) / Double(maxPoints)
        for i in 0..<maxPoints {
            let start = Int(Double(i) * bucketSize)
            let end   = min(Int(Double(i + 1) * bucketSize), data.count)
            if start < end {
                // pick peak in bucket
                if let pick = data[start..<end].max(by: { $0.value < $1.value }) {
                    out.append(pick)
                }
            }
        }
        return out
    }

    private func makeYAxisRange(for values: [Double], threshold: Double?) -> ClosedRange<Double> {
        let minY = values.min() ?? 0
        let maxY = values.max() ?? 1
        let t = threshold ?? maxY
        let overallMin = min(minY, t)
        let overallMax = max(maxY, t)
        let padding = max(5, (overallMax - overallMin) * 0.1)
        return (overallMin - padding)...(overallMax + padding)
    }

    private func makeYDomain(for series: [MeasurementSample], threshold: Int?) -> ClosedRange<Double> {
        makeYAxisRange(for: series.map { $0.value }, threshold: threshold.map(Double.init))
    }

    private func makeXAxisValues(for series: [MeasurementSample]) -> [Date] {
        guard let first = series.first?.date, let last = series.last?.date, first < last else { return [] }
        let mid = first.addingTimeInterval(last.timeIntervalSince(first) / 2)
        return [first, mid, last]
    }

    private func makeTriggerWindow(for series: [MeasurementSample], interval: Reminder.Interval?) -> (Date?, Date?) {
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
        // Use the already-built series; no recompute.
        guard !series.isEmpty else { return nil }
        // Binary search would be faster; linear is fine after downsampling.
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

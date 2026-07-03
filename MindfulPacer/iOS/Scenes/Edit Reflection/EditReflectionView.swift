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

enum EditReflectionEditorRow: Hashable {
    case date
    case activity
    case subactivity
    case mood
    case wellBeing
    case symptoms
    case triggerCrash
    case additionalInformation
    case reminder
}

// MARK: - EditReflectionView

// swiftlint:disable:next type_body_length
struct EditReflectionView: View {
    
    // MARK: Properties
    
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: EditReflectionViewModel = ScenesContainer.shared.editReflectionViewModel()
    @State private var activeEditorRow: EditReflectionEditorRow?

    @Query(sort: \Activity.name) private var activities: [Activity]
    
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
            editorContent
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
    
    // MARK: Editor Content

    private var editorContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                dateRow
                activityRow

                if viewModel.selectedActivity != nil {
                    subactivityRow
                }

                if modeOfUse == .expanded {
                    moodRow
                }

                wellBeingRow

                if modeOfUse == .expanded {
                    symptomsRow
                    triggerCrashRow
                    additionalInformationRow
                }

                if !viewModel.isReflectionDeleted {
                    reminderRow
                }

                if viewModel.mode == .edit {
                    deleteButton
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .safeAreaPadding(.bottom)
    }

    private var dateRow: some View {
        editorRow(
            id: .date,
            title: "Date",
            subtitle: viewModel.date.formatted(.dateTime.day().month().year().hour().minute()),
            systemImage: "calendar",
            tint: Color("BrandPrimary")
        ) {
            DatePicker("Date", selection: $viewModel.date)
                .datePickerStyle(.compact)
                .font(.subheadline.weight(.semibold))
        }
    }

    private var activityRow: some View {
        editorRow(
            id: .activity,
            title: "Activity",
            subtitle: viewModel.selectedActivity?.name ?? String(localized: "Uncategorized"),
            systemImage: viewModel.selectedActivity?.icon ?? "rectangle.grid.2x2",
            tint: viewModel.selectedActivity == nil ? .red : Color("BrandPrimary")
        ) {
            ExpandableMetadataScroll {
                ExpandableMetadataChipButton(
                    title: "Uncategorized",
                    systemImage: "questionmark",
                    isActive: viewModel.selectedActivity == nil,
                    tint: .red
                ) {
                    viewModel.selectedActivity = nil
                }

                ForEach(activities) { activity in
                    ExpandableMetadataChipButton(
                        title: activity.name,
                        systemImage: activity.icon,
                        isActive: viewModel.selectedActivity == activity
                    ) {
                        viewModel.selectedActivity = activity
                    }
                }

                ExpandableMetadataChipButton(
                    title: "Full Editor",
                    systemImage: "arrow.up.right.square",
                    isActive: false
                ) {
                    viewModel.navigateTo(destination: .activity)
                }
            }
        }
    }

    @ViewBuilder
    private var subactivityRow: some View {
        if let activity = viewModel.selectedActivity {
            editorRow(
                id: .subactivity,
                title: "Subactivity",
                subtitle: viewModel.selectedSubactivity?.name ?? String(localized: "None"),
                systemImage: viewModel.selectedSubactivity?.icon ?? "rectangle.grid.3x3",
                tint: Color("BrandPrimary")
            ) {
                ExpandableMetadataScroll {
                    ExpandableMetadataChipButton(
                        title: "None",
                        systemImage: "minus.circle",
                        isActive: viewModel.selectedSubactivity == nil
                    ) {
                        viewModel.selectedSubactivity = nil
                    }

                    ForEach((activity.subactivities ?? []).sorted { $0.name < $1.name }) { subactivity in
                        ExpandableMetadataChipButton(
                            title: subactivity.name,
                            systemImage: subactivity.icon,
                            isActive: viewModel.selectedSubactivity == subactivity
                        ) {
                            viewModel.selectedSubactivity = subactivity
                        }
                    }

                    ExpandableMetadataChipButton(
                        title: "Full Editor",
                        systemImage: "arrow.up.right.square",
                        isActive: false
                    ) {
                        viewModel.navigateTo(destination: .subactivity(activity))
                    }
                }
            }
        }
    }

    private var moodRow: some View {
        editorRow(
            id: .mood,
            title: "Mood",
            subtitle: viewModel.selectedMood.map { "\($0.emoji) \($0.text)" } ?? String(localized: "Not Set"),
            systemImage: "face.smiling",
            tint: Color("BrandPrimary")
        ) {
            ExpandableMetadataScroll {
                ExpandableMetadataChipButton(
                    title: "None",
                    systemImage: "minus.circle",
                    isActive: viewModel.selectedMood == nil
                ) {
                    viewModel.selectedMood = nil
                }

                ForEach(DefaultMoodData.moods, id: \.emoji) { mood in
                    ExpandableMetadataChipButton(
                        title: "\(mood.emoji) \(mood.text)",
                        systemImage: "face.smiling",
                        isActive: viewModel.selectedMood == mood
                    ) {
                        viewModel.selectedMood = mood
                    }
                }

                ExpandableMetadataChipButton(
                    title: "Full Editor",
                    systemImage: "arrow.up.right.square",
                    isActive: false
                ) {
                    viewModel.navigateTo(destination: .mood)
                }
            }
        }
    }

    private var wellBeingRow: some View {
        editorRow(
            id: .wellBeing,
            title: viewModel.wellBeing.displayName,
            subtitle: viewModel.wellBeing.description,
            systemImage: viewModel.wellBeing.icon,
            tint: viewModel.wellBeing.color
        ) {
            symptomValueChips(
                symptom: viewModel.wellBeing,
                setValue: { viewModel.wellBeing.setValue($0) },
                openFullEditor: { viewModel.presentSymptomValueSheet(for: .wellBeing(nil)) }
            )
        }
    }

    private var symptomsRow: some View {
        editorRow(
            id: .symptoms,
            title: "Symptoms",
            subtitle: symptomsSubtitle,
            systemImage: "cross.case.fill",
            tint: Color("BrandPrimary")
        ) {
            ExpandableMetadataScroll {
                ForEach(editableSymptoms, id: \.displayName) { symptom in
                    ExpandableMetadataChipButton(
                        title: symptomChipTitle(symptom),
                        systemImage: symptom.icon,
                        isActive: symptom.value != nil,
                        tint: symptom.color
                    ) {
                        viewModel.presentSymptomValueSheet(for: symptom)
                    }
                }
            }
        }
    }

    private var triggerCrashRow: some View {
        editorRow(
            id: .triggerCrash,
            title: "Crash",
            subtitle: viewModel.didTriggerCrash ? String(localized: "Triggered") : String(localized: "Not Triggered"),
            systemImage: "exclamationmark.triangle.fill",
            tint: .orange
        ) {
            ExpandableMetadataScroll {
                ExpandableMetadataChipButton(
                    title: "No",
                    systemImage: "xmark.circle",
                    isActive: !viewModel.didTriggerCrash
                ) {
                    viewModel.didTriggerCrash = false
                }

                ExpandableMetadataChipButton(
                    title: "Yes",
                    systemImage: "checkmark.circle",
                    isActive: viewModel.didTriggerCrash,
                    tint: .orange
                ) {
                    viewModel.didTriggerCrash = true
                }
            }
        }
    }

    private var additionalInformationRow: some View {
        editorRow(
            id: .additionalInformation,
            title: "Additional Information",
            subtitle: viewModel.additionalInformation.isEmpty ? String(localized: "None") : viewModel.additionalInformation,
            systemImage: "pencil.line",
            tint: Color("BrandPrimary")
        ) {
            TextField("You can write anything here", text: $viewModel.additionalInformation, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(3...8)
                .padding(12)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var reminderRow: some View {
        if let reflection,
           let reminderMeasurementType = reflection.measurementType,
           let reminderType = reflection.reminderType {
            editorRow(
                id: .reminder,
                title: "Reminder",
                subtitle: reflection.reminderTriggerSummary,
                systemImage: reminderMeasurementType.icon,
                tint: reminderType.color
            ) {
                VStack(alignment: .leading, spacing: 12) {
                    Label(reminderMeasurementType.localized, systemImage: reminderMeasurementType.icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(reminderMeasurementType.color)

                    TriggerDataChartView(reflection: reflection)
                        .frame(height: 250)
                }
            }
        } else if reflection != nil {
            editorRow(
                id: .reminder,
                title: "Manual Reflection",
                subtitle: "Not created from a reminder",
                systemImage: "person",
                tint: .secondary
            ) {
                Text("This reflection was created manually.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func editorRow<ExpandedContent: View>(
        id: EditReflectionEditorRow,
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        @ViewBuilder expandedContent: @escaping () -> ExpandedContent
    ) -> some View {
        ExpandableMetadataRow(
            id: id,
            activeID: $activeEditorRow,
            expandedContentLeadingInset: 44
        ) { isActive in
            EditReflectionRowContent(
                title: title,
                subtitle: subtitle,
                systemImage: systemImage,
                tint: tint,
                isActive: isActive
            )
        } rowAccessory: { isActive in
            Image(systemName: isActive ? "checkmark.circle.fill" : "slider.horizontal.3")
                .font(.body.weight(.semibold))
                .foregroundStyle(isActive ? tint : Color(.tertiaryLabel))
                .padding(.top, 8)
        } expandedContent: {
            expandedContent()
        }
    }

    private func symptomValueChips(
        symptom: Symptom,
        setValue: @escaping (Int?) -> Void,
        openFullEditor: @escaping () -> Void
    ) -> some View {
        ExpandableMetadataScroll {
            ExpandableMetadataChipButton(
                title: "Not Set",
                systemImage: "minus.circle",
                isActive: symptom.value == nil
            ) {
                setValue(nil)
            }

            ForEach(0 ..< symptom.numOptions, id: \.self) { value in
                ExpandableMetadataChipButton(
                    title: symptom.description(for: value),
                    systemImage: "\(value).circle",
                    isActive: symptom.value == value,
                    tint: symptom.color(for: value)
                ) {
                    setValue(value)
                }
            }

            ExpandableMetadataChipButton(
                title: "Full Editor",
                systemImage: "arrow.up.right.square",
                isActive: false
            ) {
                openFullEditor()
            }
        }
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

    private var symptomsSubtitle: String {
        let count = editableSymptoms.filter { $0.value != nil }.count
        return count == 0 ? String(localized: "None Set") : String(localized: "\(count) set")
    }

    private func symptomChipTitle(_ symptom: Symptom) -> String {
        symptom.value == nil ? symptom.displayName : "\(symptom.displayName): \(symptom.description)"
    }
    
    // MARK: Create Button
    
    private var createButton: some View {
        Button {
            viewModel.createReflection()
            onReflectionCreation?()
            dismiss()
        } label: {
            Label("Create", systemImage: "checkmark")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .padding([.horizontal, .top])
        .background(.ultraThinMaterial)
        .disabled(viewModel.isActionButtonDisabled)
        .overlay(alignment: .top) {
            Divider()
        }
    }
    
    // MARK: Delete Button
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            viewModel.presentAlert(.deleteConfirmation)
        } label: {
            Label("Delete Reflection", systemImage: "trash")
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(.red)
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

// MARK: - Edit Reflection Row Content

private struct EditReflectionRowContent: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color
    let isActive: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(isActive ? tint : .secondary)
                .frame(width: 32, height: 32)
                .background(
                    (isActive ? tint.opacity(0.16) : Color(.tertiarySystemGroupedBackground)),
                    in: Circle()
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
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

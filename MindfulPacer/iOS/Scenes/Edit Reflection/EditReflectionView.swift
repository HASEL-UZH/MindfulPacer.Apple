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
    @AppStorage(ModeOfUse.appStorageKey) private var modeOfUse: ModeOfUse = .essentials
    @State var viewModel: EditReflectionViewModel = ScenesContainer.shared.editReflectionViewModel()
    
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
                        )
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
                        DisclosureGroup {
                            TriggerDataChartView(reflection: reflection)
                                .frame(height: 250)
                                .padding(.top)
                        } label: {
                            IconLabel(
                                icon: "chart.xyaxis.line",
                                title: "Chart",
                                description: "View the data that triggered this reminder",
                                labelColor: .primary
                            )
                            .font(.subheadline.weight(.semibold))
                        }
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
    
    var samples: [MeasurementSample] { reflection.triggerSamples }
    
    private var measurementType: Reminder.MeasurementType? {
        samples.first?.type
    }
    
    private var eventStartDate: Date? {
        samples.first?.date
    }
    
    private var eventEndDate: Date? {
        samples.last?.date
    }
    
    private var xAxisValues: [Date] {
        guard let startDate = eventStartDate, let endDate = eventEndDate else { return [] }
        let middleDate = startDate.addingTimeInterval((endDate.timeIntervalSince(startDate)) / 2)
        return [startDate, middleDate, endDate]
    }
    
    private var downsampledSamples: [MeasurementSample] {
        let maxDataPoints = 200
        
        guard samples.count > maxDataPoints else {
            return samples
        }
        
        var downsampledData: [MeasurementSample] = []
        let bucketSize = Double(samples.count) / Double(maxDataPoints)
        
        for i in 0..<maxDataPoints {
            let bucketStart = Int(Double(i) * bucketSize)
            let bucketEnd = Int(Double(i + 1) * bucketSize)
            
            guard let bucketSlice = samples[safe: bucketStart..<bucketEnd] else { continue }
            let bucket = Array(bucketSlice)
            guard !bucket.isEmpty else { continue }
            
            if let significantPoint = bucket.max(by: { $0.value < $1.value }) {
                downsampledData.append(significantPoint)
            }
        }
        
        return downsampledData
    }
    
    private var yDomain: ClosedRange<Double> {
        let values = samples.map { $0.value }
        let minY = values.min() ?? 0
        let maxY = values.max() ?? 100
        let threshold = Double(reflection.threshold ?? Int(maxY))
        
        let overallMin = min(minY, threshold)
        let overallMax = max(maxY, threshold)
        
        let padding = (overallMax - overallMin) * 0.1
        return (overallMin - (padding + 5))...(overallMax + (padding + 5))
    }
    
    private var selectedSample: MeasurementSample? {
        guard let selectedDate else { return nil }
        return samples.min(by: { abs($0.date.distance(to: selectedDate)) < abs($1.date.distance(to: selectedDate)) })
    }
    
    private var minValue: Double {
        samples.map(\.value).min() ?? 0
    }
    
    private var chartColor: Color {
        measurementType == .heartRate ? .pink : .teal
    }
    
    private var xAxisFormatStyle: Date.FormatStyle {
        if let interval = reflection.interval {
            switch interval {
            case .immediately:
                return .dateTime.hour().minute().second()
            case .oneMinute:
                return .dateTime.hour().minute().second()
            case .fiveMinutes:
                return .dateTime.hour().minute()
            case .tenMinutes:
                return .dateTime.hour().minute()
            case .fifteenMinutes:
                return .dateTime.hour().minute()
            case .thirtyMinutes:
                return .dateTime.hour().minute()
            case .oneHour:
                return .dateTime.hour().minute()
            case .twoHours:
                return .dateTime.hour().minute()
            case .fourHours:
                return .dateTime.hour()
            case .oneDay:
                return .dateTime.hour()
            }
        } else {
            return .dateTime.hour().minute().second()
        }
    }
    
    private var triggerWindowStartDate: Date? {
        guard let endDate = eventEndDate, let interval = reflection.interval?.timeInterval else { return nil }
        return endDate.addingTimeInterval(-interval)
    }
    
    private var triggerWindowEndDate: Date? {
        return eventEndDate
    }
    
    var body: some View {
        if samples.isEmpty {
            Text("No trigger data was saved for this reflection.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(height: 150)
        } else {
            Chart {
                if let startDate = triggerWindowStartDate, let endDate = triggerWindowEndDate {
                    RectangleMark(
                        xStart: .value("Start", startDate),
                        xEnd: .value("End", endDate)
                    )
                    .foregroundStyle(chartColor.opacity(0.1))
                }
                
                ForEach(downsampledSamples, id: \.date) { sample in
                    LineMark(
                        x: .value("Time", sample.date),
                        y: .value("BPM", sample.value)
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
                AxisMarks(values: xAxisValues) { value in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisFormatStyle, collisionResolution: .greedy)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    if let selectedDate {
                        let datePosition = proxy.position(forX: selectedDate) ?? 0
                        
                        Rectangle()
                            .fill(chartColor.opacity(0.3))
                            .frame(width: 2, height: geometry.size.height)
                            .position(x: datePosition, y: geometry.size.height / 2)
                        
                        if let selectedSample {
                            valuePopover(for: selectedSample)
                                .position(x: datePosition, y: geometry.size.height / 2 - 40)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
        }
    }
    
    @ViewBuilder
    private func valuePopover(for sample: MeasurementSample) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(sample.date.formatted(.dateTime.hour().minute().second()))
                .font(.caption)
                .foregroundColor(chartColor)
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(Int(sample.value)))
                    .font(.body.weight(.bold))
                Text(measurementType == .heartRate ? "bpm" : "steps")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Material.thick)
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

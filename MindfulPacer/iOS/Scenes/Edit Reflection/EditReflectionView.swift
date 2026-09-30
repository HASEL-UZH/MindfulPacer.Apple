//
//  EditReflectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Presentation Enums

enum EditReflectionNavigationDestination: Hashable {
    case activity
    case subactivity(Activity?)
    case mood
}

enum EditReflectionSheet: Identifiable {
    case symptomValueView(Symptom)
    case activity
    case subactivity(Activity)
    case mood
    
    var id: Int {
        switch self {
        case .symptomValueView: 0
        case .activity: 1
        case .subactivity: 2
        case .mood: 3
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: EditReflectionViewModel = ScenesContainer.shared.editReflectionViewModel()
    @FocusState private var focusedField: FocusField?

    
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
        case .activity:
            NavigationStack {
                ActivityView(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { CloseButton() } }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        case .subactivity(let activity):
            NavigationStack {
                SubactivityView(activity: activity, viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { CloseButton() } }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        case .mood:
            NavigationStack {
                MoodView(viewModel: viewModel)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { CloseButton() } }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
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
            .presentationDetents([.medium, .large])
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
        dateRow

        activityRow

        if viewModel.selectedActivity != nil {
            subactivityRow
        }

        if modeOfUse == .expanded {
            moodRow
        }

        wellBeingRow
    }

    private var dateRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                dateLabel.fixedSize()
                Spacer(minLength: 0)
                datePicker.fixedSize()
            }
            VStack(alignment: .leading, spacing: 8) {
                dateLabel
                datePicker
            }
        }
    }

    private var dateLabel: some View {
        Label("Date", systemImage: "calendar")
            .labelStyle(.titleAndIcon)
            .font(.body)
            .foregroundStyle(Color.primary)
    }

    private var datePicker: some View {
        DatePicker("Date", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
            .labelsHidden()
            .datePickerStyle(.compact)
    }

    private var activityRow: some View {
        Button {
            viewModel.presentSheet(.activity)
        } label: {
            formRow(title: "Activity", systemImage: "rectangle.grid.2x2") {
                rowValue(viewModel.selectedActivity?.name ?? String(localized: "Select"),
                         isRequiredMissing: viewModel.selectedActivity == nil)
            }
            .contentShape(.rect)
        }
        .accessibilityIdentifier("reflection.activity")
    }

    @ViewBuilder
    private var subactivityRow: some View {
        if let activity = viewModel.selectedActivity {
            Button {
                viewModel.presentSheet(.subactivity(activity))
            } label: {
                formRow(title: "Subactivity", systemImage: "rectangle.grid.3x3") {
                    rowValue(viewModel.selectedSubactivity?.name ?? String(localized: "None"))
                }
                .contentShape(.rect)
            }
            .accessibilityIdentifier("reflection.subactivity")
        }
    }

    private var moodRow: some View {
        Button {
            viewModel.presentSheet(.mood)
        } label: {
            formRow(title: "Mood", systemImage: "face.smiling") {
                rowValue(viewModel.selectedMood.map { "\($0.emoji) \($0.text)" } ?? String(localized: "Not Set"))
            }
            .contentShape(.rect)
        }
        .accessibilityIdentifier("reflection.mood")
    }

    private var wellBeingRow: some View {
        Button {
            viewModel.presentSymptomValueSheet(for: viewModel.wellBeing)
        } label: {
            formRow(title: viewModel.wellBeing.displayName, systemImage: viewModel.wellBeing.icon, singleLine: true) {
                Text(viewModel.wellBeing.description)
                    .foregroundStyle(viewModel.wellBeing.value == nil ? Color.secondary : viewModel.wellBeing.color)
            }
            .contentShape(.rect)
        }
        .accessibilityIdentifier("reflection.wellbeing")
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
                    .foregroundStyle(Color.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text(symptom.description)
                    .font(.body)
                    .foregroundStyle(symptom.value == nil ? Color.secondary : symptom.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
    }

    @ViewBuilder
    private var reminderSection: some View {
        if let reflection,
           let trendData = MissedReflectionTrendCard.Data(
               reflection: reflection,
               subtitle: String(localized: "Triggered on \(reflection.date.formatted(.dateTime.month().day().hour().minute()))"),
               layout: .compact,
               chartHeight: 176
           ) {
            Section("Reminder") {
                MissedReflectionTrendCard(
                    data: trendData,
                    presentationStyle: .listSection
                )
            }
        } else if reflection != nil {
            Section("Reminder") {
                Text("This reflection was created manually.")
                    .foregroundStyle(Color.secondary)
            }
        }
    }

    // MARK: Row Helpers

    private func formRow<Field: View>(
        title: String,
        systemImage: String,
        singleLine: Bool = false,
        @ViewBuilder field: () -> Field
    ) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 12))
        return layout {
            Label(title, systemImage: systemImage)
                .font(.body)
                .foregroundStyle(Color.primary)
                .lineLimit(singleLine && !dynamicTypeSize.isAccessibilitySize ? 1 : nil)
                .minimumScaleFactor(singleLine ? 0.85 : 1)
                .layoutPriority(singleLine ? 1 : 0)
                .fixedSize(horizontal: false, vertical: true)

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 12)
            }

            field()
                .lineLimit(singleLine && !dynamicTypeSize.isAccessibilitySize ? 1 : nil)
                .fixedSize(horizontal: singleLine && !dynamicTypeSize.isAccessibilitySize, vertical: true)
                .frame(maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : (singleLine ? nil : 230),
                       alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
        }
    }

    private func rowValue(
        _ title: String,
        isRequiredMissing: Bool = false
    ) -> some View {
        Text(title)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
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
            Label("Delete Reflection", systemImage: "trash.fill")
                .fontWeight(.semibold)
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

// MARK: - Preview

#Preview {
    EditReflectionView()
        .tint(Color("BrandPrimary"))
}

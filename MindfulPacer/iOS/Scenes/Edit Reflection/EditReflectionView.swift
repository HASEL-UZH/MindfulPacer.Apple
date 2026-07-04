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
                    .foregroundStyle(Color.primary)
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
    let viewModel = ScenesContainer.shared.editReflectionViewModel()
    
    return EditReflectionView(viewModel: viewModel) {}
        .tint(Color("BrandPrimary"))
}

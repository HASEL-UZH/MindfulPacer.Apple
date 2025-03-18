//
//  EditReflectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI

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
//    @Environment(\.keyboardShowing) private var keyboardShowing
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
                    title: "Date",
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
                    title: "Activity",
                    labelColor: Color("BrandPrimary"),
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
                    title: "Subactivity",
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
                        title: "Mood",
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
        if let reflection = reflection {
            if let reminderMeasurementType = reflection.measurementType,
               let reminderType = reflection.reminderType {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "alarm",
                        title: String(localized: "Reminder"),
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description: Text("The Reminder that triggered this reflection.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            IconLabel(
                                icon: reminderMeasurementType.icon,
                                title: reminderMeasurementType.rawValue,
                                labelColor: reminderMeasurementType == .heartRate ? .pink : .teal
                            )
                            .font(.subheadline.weight(.semibold))

                            Text(viewModel.reminderTriggerSummary(for: reflection))
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
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                    }
                }
                .iconLabelGroupBoxStyle(.divider)
            } else {
                manualReflection
            }
        } else {
            manualReflection
        }
    }

    // MARK: Manual Reflection

    private var manualReflection: some View {
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

    // MARK: Create Button

    private var createButton: some View {
        PrimaryButton(title: "Create") {
            viewModel.createReflection()
            onReflectionCreation?()
            dismiss()
        }
//        .padding(keyboardShowing ? [.all] : [.horizontal, .top])
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
            title: "Delete Reflection",
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

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.editReflectionViewModel()

    return EditReflectionView(viewModel: viewModel) {}
        .tint(Color("BrandPrimary"))
}

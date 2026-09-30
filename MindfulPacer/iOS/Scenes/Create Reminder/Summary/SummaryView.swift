//
//  SummaryView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

extension CreateReminderView {
    /// The same editor is used at the end of creation and when opening an existing reminder.
    struct SummaryView: View {
        @Bindable var viewModel: CreateReminderViewModel
        var reminder: Reminder?
        @Environment(\.dynamicTypeSize) private var dynamicTypeSize
        @State private var activeField: Field?

        private enum Field: String, Identifiable {
            case measurement, strength, threshold, interval
            var id: String { rawValue }
            var title: String {
                switch self {
                case .measurement: String(localized: "Measurement Type")
                case .strength: String(localized: "Reminder Type")
                case .threshold: String(localized: "Threshold")
                case .interval: String(localized: "Interval")
                }
            }
        }

        var body: some View {
            EntryFormSheet(
                title: viewModel.summaryViewTitle,
                headerTitle: viewModel.mode == .create ? String(localized: "Review Reminder") : String(localized: "Reminder"),
                headerSystemImage: viewModel.selectedMeasurementType?.icon ?? "bell.fill",
                headerTint: viewModel.selectedMeasurementType?.color ?? .accentColor,
                canSave: !viewModel.isSaveButtonDisabled,
                usesNavigationStack: false,
                saveTitle: viewModel.mode == .create ? String(localized: "Create") : String(localized: "Save"),
                onCancel: { viewModel.shouldDismiss = true },
                onSave: {
                    if viewModel.mode == .create { viewModel.actionButtonTapped() }
                    else { viewModel.saveReminder(reminder) }
                }
            ) {
                editorRow(.measurement, icon: "ruler", value: viewModel.selectedMeasurementType?.localized)
                editorRow(.strength, icon: "alarm", value: viewModel.selectedReminderType?.localized,
                          tint: viewModel.selectedReminderType?.color ?? .accentColor)
                editorRow(.threshold, icon: "chart.line.flattrend.xyaxis",
                          value: viewModel.threshold.map { "\($0.formatted()) \(viewModel.thresholdUnitText)" })
                editorRow(.interval, icon: "timer", value: viewModel.selectedInterval?.localized)
            } content: {
                if viewModel.mode == .edit {
                    Section {
                        Button(role: .destructive) {
                            viewModel.presentAlert(.deleteConfirmation)
                        } label: {
                            Label("Delete Reminder", systemImage: "trash.fill")
                                .fontWeight(.semibold)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                        }
                        .tint(.red)
                    }
                }
            } additionalToolbarContent: {
                ToolbarItemGroup(placement: .secondaryAction) { }
            }
            .navigationBarBackButtonHidden()
            .sheet(item: $activeField) { field in
                fieldEditor(field)
            }
        }

        @ViewBuilder
        private func editorRow(_ field: Field, icon: String, value: String?, tint: Color = .accentColor) -> some View {
            if viewModel.mode == .edit && (field == .measurement || field == .strength) {
                rowContent(field, icon: icon, value: value, tint: field == .measurement ? .secondary : tint)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("reminder.editor.\(field.rawValue)")
            } else {
                Button { activeField = field } label: {
                    rowContent(field, icon: icon, value: value, tint: tint)
                }
                .accessibilityIdentifier("reminder.editor.\(field.rawValue)")
            }
        }

        private func rowContent(_ field: Field, icon: String, value: String?, tint: Color) -> some View {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                : AnyLayout(HStackLayout(spacing: 12))
            return layout {
                Label(field.title, systemImage: icon).foregroundStyle(Color.primary)
                if !dynamicTypeSize.isAccessibilitySize { Spacer(minLength: 8) }
                Text(value ?? String(localized: "Select"))
                    .foregroundStyle(value == nil ? Color.red : tint)
                    .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
            }
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }

        private func fieldEditor(_ field: Field) -> some View {
            NavigationStack {
                Group {
                    if field == .threshold {
                        Form {
                            HStack {
                                TextField("Threshold", value: $viewModel.threshold, format: .number)
                                    .keyboardType(.numberPad)
                                    .accessibilityIdentifier("reminder.threshold.input")
                                Text(viewModel.thresholdUnitText).foregroundStyle(Color.secondary)
                            }
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 12) { choices(for: field) }
                                .padding(16)
                        }
                        .background(Color(.systemGroupedBackground))
                    }
                }
                .navigationTitle(field.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { activeField = nil }
                    }
                }
            }
            .presentationDetents(field == .threshold ? [.medium] : [.medium, .large])
            .presentationDragIndicator(.visible)
        }

        @ViewBuilder
        private func choices(for field: Field) -> some View {
            switch field {
            case .measurement:
                ForEach(MeasurementType.allCases, id: \.self) { measurement in
                    SingleSelectRow(isSelected: viewModel.selectedMeasurementType == measurement) {
                        viewModel.selectedMeasurementType = measurement
                        activeField = nil
                    } content: {
                        Label(measurement.localized, systemImage: measurement.icon)
                    }
                }
            case .strength:
                ForEach(Reminder.ReminderType.allCases, id: \.self) { strength in
                    SingleSelectRow(isSelected: viewModel.selectedReminderType == strength, tint: strength.color) {
                        viewModel.selectedReminderType = strength
                        activeField = nil
                    } content: {
                        Label(strength.localized, systemImage: strength.icon)
                    }
                }
            case .interval:
                ForEach(viewModel.validIntervals, id: \.self) { interval in
                    SingleSelectRow(isSelected: viewModel.selectedInterval == interval) {
                        viewModel.selectedInterval = interval
                        activeField = nil
                    } content: {
                        Label(interval.localized, systemImage: interval.icon)
                    }
                }
            case .threshold:
                EmptyView()
            }
        }
    }
}

//
//  MeasurementTypeView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - MeasurementTypeView

extension CreateReminderView {
    struct MeasurementTypeView: View {
        
        // MARK: Properties

        @Bindable var viewModel: CreateReminderViewModel

        // MARK: Body

        var body: some View {
            List {
                Section {
                    VStack(spacing: 12) {
                        measurementTypeSelectionList
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                } header: {
                    ReminderCreationListHero(
                        title: "Choose the Measurement Type",
                        systemImage: viewModel.selectedMeasurementType?.icon ?? "waveform.path.ecg.text.clipboard",
                        tint: viewModel.selectedMeasurementType?.color ?? Color("BrandPrimary")
                    )
                } footer: {
                    Text("Select for which measurement type you want to receive reminders to do a reflection.")
                }
                .listRowBackground(Color.clear)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("")
            .safeAreaBar(edge: .bottom) {
                if viewModel.showActionButton {
                    ReminderCreationActionBar(
                        title: viewModel.actionButtonTitle,
                        isDisabled: viewModel.isActionButtonDisabled
                    ) {
                        viewModel.actionButtonTapped()
                    }
                }
            }
            .toolbar {
                if viewModel.mode == .create {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Close", systemImage: "xmark") { viewModel.shouldDismiss = true }
                    }
                }
            }
        }

        // MARK: Measurement Type Selection List

        @ViewBuilder
        private var measurementTypeSelectionList: some View {
            ForEach(MeasurementType.allCases, id: \.self) { measurementType in
                ReminderCreationSelectionRow(
                    isSelected: viewModel.selectedMeasurementType == measurementType,
                    tint: measurementType.color
                ) {
                    viewModel.toggleSelection(
                        measurementType,
                        selectedItem: &viewModel.selectedMeasurementType
                    )
                } label: {
                    ReminderCreationOptionLabel(
                        title: measurementType.localized,
                        subtitle: measurementType.units,
                        systemImage: measurementType.icon,
                        tint: measurementType.color
                    )
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReminderViewModel()

    NavigationStack {
        CreateReminderView.MeasurementTypeView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

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
                    measurementTypeSelectionList
                } footer: {
                    Text("Select the measurement that should trigger this reminder.")
                }
            }
            .navigationTitle("Measurement Type")
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

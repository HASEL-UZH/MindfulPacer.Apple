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
                ReminderCreationListHero(
                    systemImage: viewModel.selectedMeasurementType?.icon ?? "chart.xyaxis.line",
                    tint: viewModel.selectedMeasurementType?.color ?? Color("BrandPrimary")
                )

                Section {
                    measurementTypeSelectionList
                } footer: {
                    Text("Select for which measurement type you want to receive reminders to do a reflection.")
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

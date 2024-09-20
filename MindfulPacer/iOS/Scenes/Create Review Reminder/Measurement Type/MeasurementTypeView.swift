//
//  MeasurementTypeView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - MeasurementTypeView

extension CreateReviewReminderView {
    struct MeasurementTypeView: View {
        // MARK: Properties

        @Bindable var viewModel: CreateReviewReminderViewModel

        // MARK: Body

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    measurementTypeSelectionList
                    descriptionText
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Measurement Type")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        viewModel.dismissView()
                    }
                }
            }
        }

        // MARK: Measurement Type Selection List

        @ViewBuilder
        private var measurementTypeSelectionList: some View {
            ForEach(MeasurementType.allCases, id: \.self) { measurementType in
                SelectableButton(
                    shape: .roundedRectangle(cornerRadius: 16),
                    isSelected: viewModel.selectedMeasurementType == measurementType
                ) {
                    viewModel.toggleSelection(
                        measurementType,
                        selectedItem: &viewModel.selectedMeasurementType
                    )
                } label: {
                    HStack {
                        IconLabel(
                            icon: measurementType.icon,
                            title: measurementType.rawValue,
                            labelColor: viewModel.selectedMeasurementType == measurementType ? Color("BrandPrimary") : Color.primary
                        )
                        Spacer()
                        if viewModel.selectedMeasurementType == measurementType {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
            }
        }

        // MARK: Description Text

        private var descriptionText: some View {
            Text("Select for which measurement type you want to receive reminders to do a review.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()

    NavigationStack {
        CreateReviewReminderView.MeasurementTypeView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

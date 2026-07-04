//
//  ThresholdView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

//
//  ThresholdView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - ThresholdView

extension CreateReminderView {
    struct ThresholdView: View {
        
        // MARK: Properties

        @Bindable var viewModel: CreateReminderViewModel
        @FocusState private var isThresholdFocused: Bool
        
        // MARK: Body

        var body: some View {
            Form {
                Section {
                    thresholdInput
                } header: {
                    ReminderCreationListHero(
                        title: "Set the Threshold",
                        systemImage: viewModel.selectedMeasurementType?.icon ?? "chart.line.flattrend.xyaxis",
                        tint: viewModel.selectedMeasurementType?.color ?? Color("BrandPrimary")
                    )
                } footer: {
                    description
                }
                .listRowBackground(Color(.quaternarySystemFill))

                if viewModel.showActionButton {
                    ReminderCreationActionSection(
                        title: viewModel.actionButtonTitle,
                        isDisabled: viewModel.isActionButtonDisabled
                    ) {
                        viewModel.actionButtonTapped()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                if viewModel.mode == .create {
                    ToolbarItem(placement: .destructiveAction) {
                        if isThresholdFocused {
                            Button {
                                isThresholdFocused = false
                            } label: {
                                Image(systemName: "checkmark")
                            }
                        } else {
                            CloseButton()
                        }
                    }
                }
            }
        }

        // MARK: Threshold Input

        private var thresholdInput: some View {
            HStack(alignment: .lastTextBaseline) {
                TextField("0", value: $viewModel.threshold, format: .number)
                    .font(.title.weight(.semibold))
                    .foregroundStyle(viewModel.selectedMeasurementType?.color ?? Color("BrandPrimary"))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)
                    .focused($isThresholdFocused)

                Text(viewModel.thresholdUnitText)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }

        // MARK: Description

        private var description: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set a threshold that triggers a reminder when reached for a specified interval.")

                Button("Learn More") {
                    viewModel.presentSheet(.heartRateThresholdInfo)
                }
                .font(.subheadline.weight(.semibold))
            }
        }

    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReminderViewModel()

    NavigationStack {
        CreateReminderView.ThresholdView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

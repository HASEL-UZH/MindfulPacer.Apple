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
                } footer: {
                    description
                }
            }
            .navigationTitle("Threshold")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    hideKeyboardButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.heartRateThresholdInfo)
                    } label: {
                        Image(systemName: "info.circle")
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
            Text("Set the value that must be reached before this reminder can trigger.")
        }

        // MARK: Hide Keyboard Button

        private var hideKeyboardButton: some View {
            Button {
                isThresholdFocused = false
            } label: {
                Image(systemName: "keyboard.chevron.compact.down.fill")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
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

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

        // MARK: Body

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    thresholdInput
                    description
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Threshold")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    hideKeyboardButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        viewModel.dismissView()
                    }
                }
            }
        }

        // MARK: Threshold Input

        private var thresholdInput: some View {
            HStack(alignment: .lastTextBaseline) {
                TextField("0", value: $viewModel.threshold, format: .number)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(Color("BrandPrimary"))
                    .multilineTextAlignment(.trailing)
                    .keyboardType(.numberPad)

                Text(viewModel.thresholdUnitText)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }

        // MARK: Description

        private var description: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set a threshold that triggers a reminder when reached for a specified interval.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Button("Learn More") {
                    viewModel.presentSheet(.heartRateThresholdInfo)
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal)
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

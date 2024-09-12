//
//  ThresholdView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - ThresholdView

extension CreateReviewReminderView {
    struct ThresholdView: View {
        // MARK: Properties

        @Bindable var viewModel: CreateReviewReminderViewModel

        // MARK: Body

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    thresholdInput
                    descriptionText
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Threshold")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    infoButton
                }

                ToolbarItem(placement: .keyboard) {
                    hideKeyboardButton
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

        // MARK: Description Text

        private var descriptionText: some View {
            Text("Set a threshold that triggers a reminder when reached for a specified interval.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }

        // MARK: Info Button

        private var infoButton: some View {
            Button {
                viewModel.presentSheet(.heartRateThresholdInfo)
            } label: {
                Image(systemName: "info.circle.fill")
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
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()

    NavigationStack {
        CreateReviewReminderView.ThresholdView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

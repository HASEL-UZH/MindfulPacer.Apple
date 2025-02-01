//
//  ThresholdView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Threshold View

extension CreateReviewReminderView {
    struct ThresholdView: View {
        @Bindable var viewModel: CreateReviewReminderViewModel

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    HStack(alignment: .lastTextBaseline) {
                        TextField("0", value: $viewModel.threshold, format: .number)
                            .font(.largeTitle)
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

                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Threshold")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.heartRateThresholdInfo)
                    } label: {
                        Image(systemName: "info.circle.fill")
                    }
                }

                ToolbarItem(placement: .keyboard) {
                    hideKeyboardButton
                }
            }
        }
    }
}

extension CreateReviewReminderView.ThresholdView {
    private var hideKeyboardButton: some View {
        Button {
            hideKeyboard()
        } label: {
            Image(systemName: "keyboard.chevron.compact.down.fill")
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = CreateReviewReminderViewModel(
        modelContext: container.mainContext,
        triggerHapticFeedbackUseCase: UseCasesContainer.shared.triggerHapticFeedbackUseCase()
    )

    NavigationStack {
        CreateReviewReminderView.ThresholdView(viewModel: viewModel)
    }
    .tint(Color("PrimaryGreen"))
}

//
//  ThresholdView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - ThresholdView

extension CreateReviewReminderView {
    struct ThresholdView: View {
        @Bindable var viewModel: CreateReviewReminderViewModel
        
        // MARK: Body
        
        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
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
                    
                    Text("Set a threshold that triggers a reminder when reached for a specified interval.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
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
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    NavigationStack {
        CreateReviewReminderView.ThresholdView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}


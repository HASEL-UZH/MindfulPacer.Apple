//
//  MeasurementTypeView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - MeasurementTypeView

extension CreateReviewReminderView {
    struct MeasurementTypeView: View {
        @Bindable var viewModel: CreateReviewReminderViewModel
        
        // MARK: Body
        
        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ForEach(ReviewReminder.MeasurementType.allCases, id: \.self) { measurementType in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedMeasurementType == measurementType,
                            action: {
                                viewModel.toggleSelection(
                                    measurementType,
                                    selectedItem: &viewModel.selectedMeasurementType
                                )
                            }) {
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
                    
                    Text("Select for which measurement type you want to receive reminders to do a review.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Measurement Type")
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    NavigationStack {
        CreateReviewReminderView.MeasurementTypeView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

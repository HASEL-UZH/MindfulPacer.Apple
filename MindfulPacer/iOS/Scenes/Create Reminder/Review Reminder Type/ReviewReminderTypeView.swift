//
//  ReminderTypeView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - ReminderTypeView

extension CreateReminderView {
    struct ReminderTypeView: View {
        
        // MARK: Properties

        @Bindable var viewModel: CreateReminderViewModel

        // MARK: Body

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    reminderTypeSelectionList
                    description
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Reflection Reminder Type")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        viewModel.dismissView()
                    }
                }
            }
        }

        // MARK: Reflection Reminder Type Selection List

        @ViewBuilder
        private var reminderTypeSelectionList: some View {
            ForEach(Reminder.ReminderType.allCases, id: \.self) { reminderType in
                SelectableButton(
                    shape: .roundedRectangle(cornerRadius: 16),
                    isSelected: viewModel.selectedReminderType == reminderType
                ) {
                    viewModel.toggleSelection(
                        reminderType,
                        selectedItem: &viewModel.selectedReminderType
                    )
                } label: {
                    HStack {
                        IconLabel(
                            icon: "circle.fill",
                            title: reminderType.rawValue,
                            titleColor: viewModel.selectedReminderType == reminderType ? Color("BrandPrimary") : Color.primary,
                            iconColor: viewModel.selectedReminderType == reminderType ? Color("BrandPrimary") : reminderType.color
                        )
                        Spacer()
                        if viewModel.selectedReminderType == reminderType {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
            }
        }
        
        // MARK: Description
        
        private var description: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Choose a reflection reminder type, which will be reflected in the color of the reflection reminder notifications you receive.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Button("Learn More") {
                    viewModel.presentSheet(.reminderTypeInfo)
                }
                .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReminderViewModel()

    NavigationStack {
        CreateReminderView.ReminderTypeView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

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
            List {
                Section {
                    reminderTypeSelectionList
                } header: {
                    ReminderCreationListHero(
                        title: "Choose the Reminder Type",
                        systemImage: viewModel.selectedReminderType?.icon ?? "applewatch.radiowaves.left.and.right",
                        tint: viewModel.selectedReminderType?.color ?? Color("BrandPrimary")
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
            .toolbar {
                if viewModel.mode == .create {
                    ToolbarItem(placement: .destructiveAction) {
                        CloseButton()
                    }
                }
            }
        }

        // MARK: Reminder Type Selection List

        @ViewBuilder
        private var reminderTypeSelectionList: some View {
            ForEach(Reminder.ReminderType.allCases, id: \.self) { reminderType in
                ReminderCreationSelectionRow(
                    isSelected: viewModel.selectedReminderType == reminderType,
                    tint: reminderType.color
                ) {
                    viewModel.toggleSelection(
                        reminderType,
                        selectedItem: &viewModel.selectedReminderType
                    )
                } label: {
                    ReminderCreationOptionLabel(
                        title: reminderType.localized,
                        subtitle: nil,
                        systemImage: reminderType.icon,
                        tint: reminderType.color
                    )
                }
            }
        }
        
        // MARK: Description
        
        @ViewBuilder
        private var description: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("The strength and duration of the vibration varies by reminder type.")

                Button("Learn More") {
                    viewModel.presentSheet(.reminderTypeInfo)
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
        CreateReminderView.ReminderTypeView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

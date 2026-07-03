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
        
        @AppStorage(DeviceMode.appStorageKey, store: DefaultsStore.shared)
        private var deviceModeRaw: String = DeviceMode.iPhoneAndWatch.rawValue
        
        private var deviceMode: DeviceMode {
            DeviceMode(rawValue: deviceModeRaw) ?? .iPhoneAndWatch
        }
        
        // MARK: Body
        
        var body: some View {
            List {
                Section {
                    reminderTypeSelectionList
                } footer: {
                    description
                }
            }
            .navigationTitle("Reminder Type")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.reminderTypeInfo)
                    } label: {
                        Image(systemName: "info.circle")
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
                        subtitle: reminderType.description,
                        systemImage: reminderType.icon,
                        tint: reminderType.color
                    )
                }
            }
        }
        
        // MARK: Description
        
        @ViewBuilder
        private var description: some View {
            if deviceMode == .iPhoneAndWatch {
                Text("The strength and duration of the vibration varies by reminder type.")
            } else {
                Text("Choose how prominent this reminder should be.")
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

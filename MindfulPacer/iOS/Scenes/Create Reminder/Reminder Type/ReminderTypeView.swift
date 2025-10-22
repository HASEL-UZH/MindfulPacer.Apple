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
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    reminderTypeSelectionList
                    if deviceMode == .iPhoneAndWatch {
                        description
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Reminder Type")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        viewModel.dismissView()
                    }
                }
            }
        }

        // MARK: Reminder Type Selection List

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
                    HStack(spacing: 16) {
                        if deviceMode == .iPhoneAndWatch {
                            reminderType.image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 128)
                        }
                        
                        IconLabel(
                            icon: "circle.fill",
                            title: reminderType.localized,
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
            Label("The strength and duration of the vibration varies by reminder type.", systemImage: "applewatch.radiowaves.left.and.right")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.secondary)
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

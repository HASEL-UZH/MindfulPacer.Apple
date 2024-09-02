//
//  AlarmTypeView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - AlarmTypeView

extension CreateReviewReminderView {
    struct AlarmTypeView: View {
        @Bindable var viewModel: CreateReviewReminderViewModel
        
        // MARK: Body
        
        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ForEach(ReviewReminder.AlarmType.allCases, id: \.self) { alarmType in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedAlarmType == alarmType,
                            action: {
                                viewModel.toggleSelection(
                                    alarmType,
                                    selectedItem: &viewModel.selectedAlarmType
                                )
                            }) {
                                HStack {
                                    IconLabel(
                                        icon: "circle.fill",
                                        title: alarmType.rawValue,
                                        textColor: viewModel.selectedAlarmType == alarmType ? Color("BrandPrimary") : Color.primary,
                                        iconColor: viewModel.selectedAlarmType == alarmType ? Color("BrandPrimary") : alarmType.color
                                    )
                                    Spacer()
                                    if viewModel.selectedAlarmType == alarmType {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                    }
                    
                    Text("Choose an alarm type, which will be reflected in the color of the Review Reminder notifications you receive.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Alarm Type")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.alarmTypeInfo)
                    } label: {
                        Image(systemName: "info.circle.fill")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()

    NavigationStack {
        CreateReviewReminderView.AlarmTypeView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

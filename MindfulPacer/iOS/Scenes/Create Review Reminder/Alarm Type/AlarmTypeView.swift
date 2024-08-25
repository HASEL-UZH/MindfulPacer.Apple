//
//  AlarmTypeView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

//extension CreateReviewReminderView {
//    struct AlarmTypeView: View {
//        @Bindable var viewModel: CreateReviewReminderViewModel
//        
//        var body: some View {
//            ZStack {
//                Color(.systemGroupedBackground)
//                    .ignoresSafeArea()
//                
//                VStack(spacing: 16) {
//                    ForEach(ReviewReminder.AlarmType.allCases, id: \.self) { alarmType in
//                        SelectableButton(
//                            shape: .roundedRectangle(cornerRadius: 16),
//                            isSelected: viewModel.selectedAlarmType == alarmType,
//                            action: {
//                                viewModel.toggleSelection(
//                                    alarmType,
//                                    selectedItem: &viewModel.selectedAlarmType
//                                )
//                            }) {
//                                HStack {
//                                    SFSymbolLabel(icon: alarmType.icon, title: alarmType.rawValue)
//                                    Spacer()
//                                    if viewModel.selectedAlarmType == alarmType {
//                                        Image(systemName: "checkmark.circle.fill")
//                                    }
//                                }
//                            }
//                    }
//                    
//                    Spacer()
//                }
//                .padding(.horizontal)
//            }
//            .navigationTitle("Alarm Type")
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        viewModel.presentSheet(.alarmTypeInfo)
//                    } label: {
//                        Image(systemName: "info.circle.fill")
//                    }
//                }
//            }
//        }
//    }
//}

// MARK: - Preview

//#Preview {
//    let container = ModelContainer.preview
//    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()
//
//    NavigationStack {
//        CreateReviewReminderView.AlarmTypeView(viewModel: viewModel)
//    }
//    .tint(Color("BrandPrimary"))
//}

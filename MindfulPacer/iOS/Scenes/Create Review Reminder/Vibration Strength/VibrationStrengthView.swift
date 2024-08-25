//
//  VibrationStrengthView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

//extension CreateReviewReminderView {
//    struct VibrationStrengthView: View {
//        @Bindable var viewModel: CreateReviewReminderViewModel
//        
//        var body: some View {
//            ZStack {
//                Color(.systemGroupedBackground)
//                    .ignoresSafeArea()
//                
//                VStack(spacing: 16) {
//                    ForEach(ReviewReminder.VibrationStrength.allCases, id: \.self) { vibrationStrength in
//                        SelectableButton(
//                            shape: .roundedRectangle(cornerRadius: 16),
//                            isSelected: viewModel.selectedVibrationStrength == vibrationStrength,
//                            action: {
//                                viewModel.toggleSelection(
//                                    vibrationStrength,
//                                    selectedItem: &viewModel.selectedVibrationStrength
//                                )
//                            }) {
//                                HStack {
//                                    Text(vibrationStrength.rawValue)
//                                    Spacer()
//                                    if viewModel.selectedVibrationStrength == vibrationStrength {
//                                        Image(systemName: "checkmark.circle.fill")
//                                    }
//                                }
//                            }
//                    }
//                    
//                    Button {
//                        viewModel.testVibrationStrengthTapped()
//                    } label: {
//                        Label("Test on Apple Watch", systemImage: "hand.tap.fill")
//                            .fontWeight(.semibold)
//                    }
//                    .buttonBorderShape(.capsule)
//                    .buttonStyle(.bordered)
//                    .disabled(viewModel.selectedVibrationStrength.isNil)
//                    .padding(.top)
//                    
//                    Spacer()
//                }
//                .padding(.horizontal)
//            }
//            .navigationTitle("Vibration Strength")
//            .toolbar {
//                ToolbarItem(placement: .topBarTrailing) {
//                    Button {
//                        viewModel.presentSheet(.vibrationStrengthInfo)
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
//        CreateReviewReminderView.VibrationStrengthView(viewModel: viewModel)
//    }
//    .tint(Color("BrandPrimary"))
//}

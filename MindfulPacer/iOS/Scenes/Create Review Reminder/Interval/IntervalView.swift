//
//  IntervalView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI
import SwiftData

extension CreateReviewReminderView {
    struct IntervalView: View {
        @Bindable var viewModel: CreateReviewReminderViewModel
        
        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ForEach(ReviewReminder.Interval.allCases, id: \.self) { interval in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedInterval == interval,
                            action: {
                                viewModel.toggleSelection(
                                    interval,
                                    selectedItem: &viewModel.selectedInterval
                                )
                            }) {
                                HStack {
                                    SFSymbolLabel(
                                        icon: interval.icon,
                                        title: interval.rawValue,
                                        symbolColor: viewModel.selectedInterval == interval ? Color("BrandPrimary") : .primary
                                    )
                                    Spacer()
                                    if viewModel.selectedInterval == interval {
                                        Image(systemName: "checkmark.circle.fill")
                                    }
                                }
                            }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Interval")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.intervalInfo)
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
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()
    
    NavigationStack {
        CreateReviewReminderView.IntervalView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

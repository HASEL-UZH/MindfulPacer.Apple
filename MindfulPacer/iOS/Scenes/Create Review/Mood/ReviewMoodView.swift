//
//  ReviewMoodView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI

// MARK: - ReviewMoodView

extension CreateReviewView {
    struct ReviewMoodView: View {
        @Bindable var viewModel: CreateReviewViewModel
        
        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 5),
                    spacing: 16
                ) {
                    ForEach(DefaultMoodData.moods, id: \.id) { mood in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 12),
                            isSelected: viewModel.selectedMood == mood,
                            action: {
                                viewModel.toggleSelection(mood, selectedItem: &viewModel.selectedMood)
                            }) {
                                Text(mood.emoji)
                                    .font(.title)
                            }
                            .contextMenu {
                                Text(mood.description)
                            }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Mood")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReviewViewModel()
    
    NavigationStack {
        CreateReviewView.ReviewMoodView(viewModel: viewModel)
            .navigationTitle("Mood")
            .tint(Color("BrandPrimary"))
    }
}

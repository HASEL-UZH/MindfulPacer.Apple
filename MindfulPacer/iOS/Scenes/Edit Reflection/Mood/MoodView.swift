//
//  MoodView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI

// MARK: - MoodView

extension EditReflectionView {
    struct MoodView: View {
        
        // MARK: Properties

        @Bindable var viewModel: EditReflectionViewModel

        // MARK: Body

        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 5),
                    spacing: 16
                ) {
                    ForEach(DefaultMoodData.moods, id: \.emoji) { mood in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 12),
                            isSelected: viewModel.selectedMood == mood
                        ) {
                            viewModel.toggleSelection(mood, selectedItem: &viewModel.selectedMood)
                        } label: {
                            Text(mood.emoji)
                                .font(.title)
                        }
                        .contextMenu {
                            Text(mood.text)
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
    let viewModel = ScenesContainer.shared.editReflectionViewModel()

    NavigationStack {
        EditReflectionView.MoodView(viewModel: viewModel)
            .navigationTitle("Mood")
            .tint(Color("BrandPrimary"))
    }
}

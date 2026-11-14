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

        @Environment(\.dismiss) private var dismiss
        @Bindable var viewModel: EditReflectionViewModel

        // MARK: Body

        var body: some View {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(DefaultMoodData.moods, id: \.emoji) { mood in
                        SingleSelectRow(isSelected: viewModel.selectedMood == mood) {
                            viewModel.selectedMood = viewModel.selectedMood == mood ? nil : mood
                            dismiss()
                        } content: {
                            HStack(spacing: 12) {
                                Text(mood.emoji).frame(width: 24)
                                Text(mood.text).font(.body)
                            }
                        }
                        .accessibilityLabel(mood.text)
                    }
                }
                .padding(16)
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

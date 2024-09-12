//
//  CategoryView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI

// MARK: - CategoryView

extension EditReviewView {
    struct CategoryView: View {
        // MARK: Properties

        @Bindable var viewModel: EditReviewViewModel

        // MARK: Body

        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 2),
                    spacing: 16
                ) {
                    ForEach(viewModel.categories) { category in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.toggleSelection(category, selectedItem: &viewModel.selectedCategory)
                        } label: {
                            VStack(spacing: 16) {
                                Image(systemName: category.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(width: 32, height: 32)
                                Text(category.name)
                                    .font(.subheadline)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Category")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.editReviewViewModel()

    NavigationStack {
        EditReviewView.CategoryView(viewModel: viewModel)
            .navigationTitle("Category")
            .tint(Color("BrandPrimary"))
            .onAppear {
                viewModel.onViewFirstAppear()
            }
    }
}

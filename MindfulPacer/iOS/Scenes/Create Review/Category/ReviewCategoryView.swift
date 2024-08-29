//
//  ReviewCategoryView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - ReviewCategoryView

extension CreateReviewView {
    struct ReviewCategoryView: View {
        @Bindable var viewModel: CreateReviewViewModel
        
        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 2),
                    spacing: 16
                ) {
                    ForEach(viewModel.categories) { category in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedCategory == category,
                            action: {
                                viewModel.toggleSelection(category, selectedItem: &viewModel.selectedCategory)
                            }) {
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
    let container = ModelContainer.preview
    let viewModel = ScenesContainer.shared.createReviewViewModel()
    
    NavigationStack {
        CreateReviewView.ReviewCategoryView(viewModel: viewModel)
            .navigationTitle("Category")
            .modelContainer(container)
            .tint(Color("BrandPrimary"))
            .onAppear {
                viewModel.onViewFirstAppear()
            }
    }
}

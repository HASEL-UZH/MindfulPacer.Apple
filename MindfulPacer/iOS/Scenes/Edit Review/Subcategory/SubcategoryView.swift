//
//  SubcategoryView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI

// MARK: - SubcategoryView

extension EditReviewView {
    struct SubcategoryView: View {
        // MARK: Properties

        var category: Category
        @Bindable var viewModel: EditReviewViewModel

        // MARK: Body

        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 2),
                    spacing: 16
                ) {
                    ForEach(category.subcategories!) { subcategory in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedSubcategory == subcategory
                        ) {
                            viewModel.toggleSelection(subcategory, selectedItem: &viewModel.selectedSubcategory)
                        } label: {
                            VStack(spacing: 16) {
                                Image(systemName: subcategory.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(width: 32, height: 32)
                                Text(subcategory.name)
                                    .font(.subheadline)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Subcategory")
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

    EditReviewView.SubcategoryView(category: Category(), viewModel: viewModel)
        .tint(Color("BrandPrimary"))
}

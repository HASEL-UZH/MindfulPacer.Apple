//
//  SubcategoryView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - SubcategoryView

extension EditReviewView {
    struct SubcategoryView: View {
        var category: Category
        @Bindable var viewModel: EditReviewViewModel
        
        var body: some View {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(spacing: 16), count: 2),
                    spacing: 16
                ) {
                    ForEach(category.subcategories!) { subcategory in
                        SelectableButton(
                            shape: .roundedRectangle(cornerRadius: 16),
                            isSelected: viewModel.selectedSubcategory == subcategory,
                            action: {
                                viewModel.toggleSelection(subcategory, selectedItem: &viewModel.selectedSubcategory)
                            }) {
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
    let container = ModelContainer.preview
    
    EditReviewView.SubcategoryView(category: Category(), viewModel: viewModel)
        .modelContainer(container)
        .tint(Color("BrandPrimary"))
}

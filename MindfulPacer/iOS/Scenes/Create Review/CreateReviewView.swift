//
//  CreateReviewView.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Navigation

enum CreateReviewNavigationDestination: Hashable {
    case category
    case subcategory(Category?)
}

// MARK: - Create Review

struct CreateReviewView: View {
    @State var viewModel: CreateReviewViewModel = ScenesContainer.shared.createReviewViewModel()
    
    var body: some View {
        NavigationStack(path: $viewModel.navigationPath) {
            List {
                category
                if viewModel.selectedCategory.isNotNil {
                    subcategory
                }
            }
            .navigationTitle("Create Review")
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
            .navigationDestination(for: CreateReviewNavigationDestination.self) { destination in
                switch destination {
                case .category:
                    reviewCategoryView
                case .subcategory(let category):
                    reviewSubCategoryView(category.unsafelyUnwrapped)
                }
            }
        }
    }
    
    private var category: some View {
        NavigationLink(value: CreateReviewNavigationDestination.category) {
            if let selectedCategory = viewModel.selectedCategory {
                Label(selectedCategory.name, systemImage: selectedCategory.icon)
                    .fontWeight(.semibold)
                    .symbolVariant(.fill)
            } else {
                Label("Category", systemImage: "square.grid.2x2.fill")
                    .fontWeight(.semibold)
            }
        }
    }
    
    private var subcategory: some View {
        NavigationLink(value: CreateReviewNavigationDestination.subcategory(viewModel.selectedCategory)) {
            if let selectedSubcategory = viewModel.selectedSubcategory {
                Label(selectedSubcategory.name, systemImage: selectedSubcategory.icon)
                    .fontWeight(.semibold)
                    .symbolVariant(.fill)
            } else {
                Label("Subcategory", systemImage: "rectangle.grid.3x3.fill")
                    .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Review Category

extension CreateReviewView {
    private var reviewCategoryView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(spacing: 16), count: 2), spacing: 16) {
                ForEach(viewModel.categories) { category in
                    SelectableButton(
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    } content: {
                        VStack(spacing: 16) {
                            Image(systemName: category.icon)
                                .resizable()
                                .scaledToFit()
                                .symbolVariant(.fill)
                                .frame(width: 64, height: 64)
                            Text(category.name)
                                .fontWeight(.semibold)
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

// MARK: - Review Subcategory

extension CreateReviewView {
    @ViewBuilder private func reviewSubCategoryView(_ category: Category) -> some View {
        ScrollView {
            
        }
    }
}

// MARK: - Preview

#Preview {
    let container = ModelContainer.preview
    let viewModel = CreateReviewViewModel(
        modelContext: container.mainContext,
        fetchDefaultCategoriesUseCase: UseCasesContainer.shared.fetchDefaultCategoriesUseCase()
    )
    
    return CreateReviewView(viewModel: viewModel)
        .tint(Color("PrimaryGreen"))
        .modelContainer(container)
}

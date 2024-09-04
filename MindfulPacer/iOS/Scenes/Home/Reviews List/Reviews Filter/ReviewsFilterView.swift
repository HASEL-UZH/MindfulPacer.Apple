//
//  ReviewsFilterView.swift
//  iOS
//
//  Created by Grigor Dochev on 03.09.2024.
//

import SwiftUI

// MARK: - ReviewsFilterView

struct ReviewsFilterView: View {
    @Bindable var viewModel: HomeViewModel
    
    // MARK: Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    categories
                    triggerCrash
                }
                .padding(.horizontal)
            }
            .cornerRadius(30)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Filter Reviews")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    resetButton
                }
            }
        }
    }
    
    // MARK: Reset Button
    
    private var resetButton: some View {
        Button {
            // TODO: Reset active filters
        } label: {
            HStack {
                Image(systemName: "arrow.uturn.backward")
                Text("Reset")
            }
            .fontWeight(.semibold)
        }
    }
    
    // MARK: - Categories
    
    private var categories: some View {
        NavigationLink {
            categoriesFilterView
        } label: {
            HStack {
                Label {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categories")
                            .font(.subheadline.weight(.semibold))
                        
                        if !viewModel.reviewFilterOptions.selectedCategories.isEmpty {
                            Text(viewModel.reviewFilterOptions.selectedCategories.map { $0.name }.joined(separator: ", "))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                } icon: {
                    Icon(name: "rectangle.grid.2x2.fill", background: true)
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 4) {
                    if !viewModel.reviewFilterOptions.selectedCategories.isEmpty {
                        Text("\(viewModel.reviewFilterOptions.selectedCategories.count)")
                            .foregroundStyle(Color(.systemGray2))
                    }
                    
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
        }
        .foregroundStyle(.primary)
    }
    
    // MARK: Categories Filter View
    
    private var categoriesFilterView: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(spacing: 16), count: 3),
                spacing: 16
            ) {
                ForEach(viewModel.categories) { category in
                    SelectableButton(
                        shape: .roundedRectangle(cornerRadius: 16),
                        isSelected: viewModel.reviewFilterOptions.selectedCategories.contains(category),
                        action: {
                            viewModel.updateReviewFilterOptions(with: category)
                        }) {
                            VStack(spacing: 16) {
                                Image(systemName: category.icon)
                                    .resizable()
                                    .scaledToFit()
                                    .symbolVariant(.fill)
                                    .frame(width: 24, height: 24)
                                Text(category.name)
                                    .font(.footnote)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Categories")
        .background {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
        }
    }
    
    // MARK: Trigger Crash
    
    private var triggerCrash: some View {
        Toggle(isOn: $viewModel.reviewFilterOptions.triggeredCrash) {
            IconLabel(
                icon: "bandage.fill",
                title: "Triggered Crash",
                iconColor: Color("BrandPrimary"),
                background: true
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .layoutPriority(1)
        }
        .tint(.accentColor)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(Color(.secondarySystemGroupedBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    ReviewsFilterView(viewModel: viewModel)
        .tint(Color("BrandPrimary"))
}

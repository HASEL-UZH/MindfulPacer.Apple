//
//  ReflectionsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.08.2024.
//

import SwiftUI

// MARK: - ReflectionsListView

extension HomeView {
    struct ReflectionsListView: View {
        
        // MARK: - Properties

        @Bindable var viewModel: HomeViewModel

        // MARK: Body
        
        var body: some View {
            VStack {
                if viewModel.reflections.isEmpty {
                    reviewsEmptyState
                        .frame(maxHeight: .infinity, alignment: .center)
                } else if viewModel.filteredReflections.isEmpty {
                    filteredReflectionsEmptyState
                        .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        ForEach(viewModel.filteredReflections, id: \.id) { reflection in
                            ReflectionCell(reflection: reflection, backgroundColor: .clear) {
                                viewModel.presentSheet(.editReflectionView(reflection))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reflections")
            .toolbar {
                if !viewModel.reflections.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.presentSheet(.reviewsFilterView)
                        } label: {
                            Label("Filter Reflections", systemImage: filterButtonSystemImage)
                                .foregroundStyle(hasActiveFilters ? Color("BrandPrimary") : .primary)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.editReflectionView(nil))
                    } label: {
                        Label("New Reflection", systemImage: "plus.circle.fill")
                    }
                }
            }
        }

        // MARK: Filter Button State

        private var hasActiveFilters: Bool {
            viewModel.reviewFilter.activeFilterCount != 0
        }

        private var filterButtonSystemImage: String {
            hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease"
        }
        
        // MARK: Reflections Empty State

        private var reviewsEmptyState: some View {
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView {
                    Label("No Reflections", systemImage: "book.pages.fill")
                } description: {
                    Text("You have not created any reflections.")
                } actions: {
                    Button {
                        viewModel.presentSheet(.editReflectionView(nil))
                    } label: {
                        Text("Create Reflection")
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        
        // MARK: Filtered Reflections Empty State
        
        private var filteredReflectionsEmptyState: some View {
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No reflections match your current filter criteria.")
                } actions: {
                    Button {
                        viewModel.presentSheet(.reviewsFilterView)
                    } label: {
                        Text("Modify Filters")
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()

    NavigationStack {
        HomeView.ReflectionsListView(viewModel: viewModel)
    }
    .tint(.brandPrimary)
}

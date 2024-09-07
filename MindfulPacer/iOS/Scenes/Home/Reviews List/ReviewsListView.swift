//
//  ReviewsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.08.2024.
//

import SwiftUI

// MARK: - ReviewsListView

extension HomeView {
    struct ReviewsListView: View {
        // MARK: - Properties
        
        @Bindable var viewModel: HomeViewModel
        
        // MARK: Body
        
        var body: some View {
            VStack(spacing: 16) {
                if viewModel.reviewFilter.activeFilterCount != 0 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        reviewFilterSortingSummary
                            .safeAreaPadding(.horizontal)
                    }
                }
                
                if viewModel.filteredReviews.isEmpty {
                    if viewModel.reviewFilter.activeFilterCount > 0 {
                        filteredReviewsEmptyState
                            .frame(maxHeight: .infinity, alignment: .center)
                    } else {
                        reviewsEmptyState
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                } else {
                    RoundedList {
                        ForEach(viewModel.filteredReviews) { review in
                            ReviewCell(review: review) {
                                viewModel.presentSheet(.editReviewSheet(review))
                            }
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Reviews")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.presentSheet(.editReviewSheet(nil))
                    } label: {
                        Label("New Review", systemImage: "plus")
                    }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if !viewModel.reviews.isEmpty {
                    filterButton
                }
            }
        }
        
        // MARK: Filter Button
        
        private var filterButton: some View {
            Button {
                viewModel.presentSheet(.reviewsFilterView)
            } label: {
                IconLabel(
                    icon: "line.3.horizontal.decrease",
                    title: viewModel.filterButtonTitle,
                    labelColor: Color("BrandPrimary")
                )
                    .font(.footnote.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .foregroundStyle(Color("BrandPrimary").opacity(0.1))
                    }
            }
            .padding([.bottom, .trailing])
        }
        
        // MARK: Reviews Empty State
        
        private var reviewsEmptyState: some View {
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView {
                    Label("No Reviews", systemImage: "book.pages.fill")
                } description: {
                    Text("You have not created any reviews.")
                } actions: {
                    Button {
                        viewModel.presentSheet(.editReviewSheet(nil))
                    } label: {
                        Text("Create Review")
                    }
                    .buttonBorderShape(.capsule)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        
        // MARK: Filtered Reviews Empty State
        
        private var filteredReviewsEmptyState: some View {
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No reviews match your current filter criteria.")
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

// MARK: Review Filter Sorting Summary

extension HomeView.ReviewsListView {
    var reviewFilterSortingSummary: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.reviewFilter.selectedCategories) { category in
                HStack(spacing: 4) {
                    Icon(name: category.icon, color: .secondary)
                    Text(category.name)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Button {
                        viewModel.toggleFilterCategory(category)
                    } label: {
                        Icon(name: "xmark.circle", renderingMode: .hierarchical)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .foregroundStyle(Color(.systemGray5))
                }
            }
            
            ForEach(viewModel.reviewFilter.selectedMoods, id: \.description) { mood in
                HStack(spacing: 4) {
                    Text(mood.emoji)
                        .frame(width: 24, height: 24)
                    Button {
                        viewModel.toggleFilterMood(mood)
                    } label: {
                        Icon(name: "xmark.circle", renderingMode: .hierarchical)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .foregroundStyle(Color(.systemGray5))
                }
            }
            
            if viewModel.reviewFilter.triggeredCrash {
                HStack(spacing: 4) {
                    Icon(name: "pill", color: .secondary)
                    Text("Triggered Crash")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Button {
                        viewModel.toggleTriggeredCrash()
                    } label: {
                        Icon(name: "xmark.circle", renderingMode: .hierarchical)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .foregroundStyle(Color(.systemGray5))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    NavigationStack {
        HomeView.ReviewsListView(viewModel: viewModel)
    }
}

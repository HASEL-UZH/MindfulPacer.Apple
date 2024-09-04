//
//  ReviewsListView.swift
//  iOS
//
//  Created by Grigor Dochev on 29.08.2024.
//

import SwiftUI

// MARK: - ReviewsListView

struct ReviewsListView: View {
    @Bindable var viewModel: HomeViewModel
    
    // MARK: Body
    
    var body: some View {
        VStack {
            if viewModel.reviews.isEmpty {
                reviewsEmptyState
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.reviews) { review in
                            ReviewCell(review: review) {
                                viewModel.presentSheet(.editReviewSheet(review))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .listStyle(.grouped)
        .navigationTitle("Reviews")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.presentSheet(.editReviewSheet(nil))
                    } label: {
                        Label("New Review", systemImage: "plus")
                    }
                    
                    Button {
                        viewModel.presentSheet(.reviewsFilterView)
                    } label: {
                        Label("Filter Reviews", systemImage: "line.3.horizontal.decrease")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
    
    // MARK: Reviews Empty State
    
    var reviewsEmptyState: some View {
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
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    NavigationStack {
        ReviewsListView(viewModel: viewModel)
    }
}

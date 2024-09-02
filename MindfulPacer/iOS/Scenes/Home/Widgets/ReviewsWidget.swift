//
//  ReviewsWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - ReviewsWidget

extension HomeView {
    struct ReviewsWidget: View {
        @Bindable var viewModel: HomeViewModel
        
        // MARK: Body
        
        var body: some View {
            NavigationLink(value: HomeViewNavigationDestination.reviewsList) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "book.pages.fill",
                        title: "Reviews",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description:
                        Text("Summary of your most recent reviews.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    if viewModel.reviews.isEmpty {
                        ContentUnavailableView(
                            "No Reviews",
                            systemImage: "book.pages.fill",
                            description: Text("Tap the **+** button to create a review.")
                        )
                    } else {
                        recentReviewsSummary
                    }
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                } footer: {
                    createReviewButton
                }
            }
            .foregroundStyle(.primary)
        }
        
        // MARK: Create Review Button
        
        private var createReviewButton: some View {
            Button {
                viewModel.presentSheet(.editReviewSheet(nil))
            } label: {
                IconLabel(icon: "plus.circle", title: "Create Review", labelColor: Color("BrandPrimary"))
                    .font(.subheadline.weight(.semibold))
            }
        }
        
        // MARK:  Recent Reviews Summary
        
        private var recentReviewsSummary: some View {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(viewModel.recentReviews) { review in
                    ReviewCell(review: review, withBackground: false) {
                        viewModel.presentSheet(.editReviewSheet(review))
                    }
                    if review != viewModel.recentReviews.last {
                        Divider()
                    }
                }
            }
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundStyle(Color(.tertiarySystemGroupedBackground))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.ReviewsWidget(viewModel: viewModel)
}

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
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.reviews.prefix(3)) { review in
                                reviewCell(for: review)
                                if review != viewModel.reviews.prefix(3).last {
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
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                } footer: {
                    Button {
                        viewModel.presentSheet(.editReviewSheet(nil))
                    } label: {
                        IconLabel(icon: "plus.circle", title: "Create Review", labelColor: Color("BrandPrimary"))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .foregroundStyle(.primary)
        }
    }
}

// MARK: - Review Cell

extension HomeView.ReviewsWidget {
    @ViewBuilder private func reviewCell(for review: Review) -> some View {
        Button {
            viewModel.presentSheet(.editReviewSheet(review))
        } label: {
            HStack(spacing: 16) {
                if let category = review.category {
                    VStack(alignment: .leading, spacing: 8) {
                        IconLabel(icon: category.icon, title: category.name)
                            .font(.subheadline.weight(.semibold))
                        Text(review.date.formatted(.dateTime.day().month().hour().minute()))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                                    
                Spacer()
                
                if let mood = review.mood {
                    Text(mood)
                        .frame(width: 24, height: 24)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.ReviewsWidget(viewModel: viewModel)
}

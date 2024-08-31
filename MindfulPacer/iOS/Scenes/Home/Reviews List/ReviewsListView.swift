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
        .background(Color(.systemGroupedBackground))
        .listStyle(.grouped)
        .navigationTitle("Reviews")
    }
}

// MARK: - ReviewCell

extension ReviewsListView {
    struct ReviewCell: View {
        var review: Review
        var onTap: () -> Void
        
        var body: some View {
            Button {
                onTap()
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
                .padding()
                .foregroundStyle(Color.primary)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(Color(.secondarySystemGroupedBackground))
                }
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

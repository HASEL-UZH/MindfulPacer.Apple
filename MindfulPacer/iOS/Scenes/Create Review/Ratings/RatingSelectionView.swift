//
//  RatingSelectionView.swift
//  iOS
//
//  Created by Grigor Dochev on 20.08.2024.
//

import SwiftUI

// MARK: - RatingSelectionView

extension CreateReviewView {
    struct RatingSelectionView: View {
        let rating: ReviewMetricRating
        let onRatingSelected: (Int?) -> Void
        
        var body: some View {
            NavigationStack {
                VStack {
                    VStack(alignment: .leading, spacing: 16) {
                        InfoBox(text: "How much did this affect you?")
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 16) {
                                ForEach(0 ..< 4, id: \.self) { index in
                                    VStack(spacing: 12) {
                                        SelectableButton(
                                            shape: .circle,
                                            color: rating.color(for: index).opacity(0.1),
                                            selectionColor: Color("BrandPrimary"),
                                            isSelected: rating.value == index,
                                            action: {
                                                onRatingSelected(index)
                                            }) {
                                                Text("\(index)")
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(rating.value == index ? Color("BrandPrimary") : rating.color(for: index))
                                            }
                                            .buttonStyle(.plain)
                                        
                                        Text(rating.description(for: index))
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(rating.value == index ? Color("BrandPrimary") : rating.color(for: index))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .background(Color(.systemGroupedBackground).ignoresSafeArea())
                .navigationTitle(rating.type.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        CloseButton()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var currentRatingType: ReviewMetricRatingType = ReviewMetricRatingType.energyLevel
    let viewModel = ScenesContainer.shared.createReviewViewModel()
    
    CreateReviewView.RatingSelectionView(
        rating: ReviewMetricRating(type: currentRatingType),
        onRatingSelected: { rating in
            viewModel.setRating(for: currentRatingType, with: rating)
        }
    )
}

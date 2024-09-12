//
//  ReviewReminderTypeView.swift
//  iOS
//
//  Created by Grigor Dochev on 18.08.2024.
//

import SwiftUI

// MARK: - ReviewReminderTypeView

extension CreateReviewReminderView {
    struct ReviewReminderTypeView: View {
        // MARK: Properties

        @Bindable var viewModel: CreateReviewReminderViewModel

        // MARK: Body

        var body: some View {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    reviewReminderTypeSelectionList
                    descriptionText
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Review Reminder Type")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    infoButton
                }
            }
        }

        // MARK: Review Reminder Type Selection List

        @ViewBuilder
        private var reviewReminderTypeSelectionList: some View {
            ForEach(ReviewReminder.ReviewReminderType.allCases, id: \.self) { reviewReminderType in
                SelectableButton(
                    shape: .roundedRectangle(cornerRadius: 16),
                    isSelected: viewModel.selectedReviewReminderType == reviewReminderType
                ) {
                    viewModel.toggleSelection(
                        reviewReminderType,
                        selectedItem: &viewModel.selectedReviewReminderType
                    )
                } label: {
                    HStack {
                        IconLabel(
                            icon: "circle.fill",
                            title: reviewReminderType.rawValue,
                            textColor: viewModel.selectedReviewReminderType == reviewReminderType ? Color("BrandPrimary") : Color.primary,
                            iconColor: viewModel.selectedReviewReminderType == reviewReminderType ? Color("BrandPrimary") : reviewReminderType.color
                        )
                        Spacer()
                        if viewModel.selectedReviewReminderType == reviewReminderType {
                            Image(systemName: "checkmark.circle.fill")
                        }
                    }
                }
            }
        }

        // MARK: Description Text

        private var descriptionText: some View {
            Text("Choose a review reminder type, which will be reflected in the color of the review reminder notifications you receive.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }

        // MARK: Info Button

        private var infoButton: some View {
            Button {
                viewModel.presentSheet(.reviewReminderTypeInfo)
            } label: {
                Image(systemName: "info.circle.fill")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.createReviewReminderViewModel()

    NavigationStack {
        CreateReviewReminderView.ReviewReminderTypeView(viewModel: viewModel)
    }
    .tint(Color("BrandPrimary"))
}

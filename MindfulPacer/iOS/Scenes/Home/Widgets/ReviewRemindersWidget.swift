//
//  ReviewRemindersWidget.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import SwiftUI

// MARK: - ReviewRemindersWidget

extension HomeView {
    struct ReviewRemindersWidget: View {
        
        // MARK: Properties

        @Bindable var viewModel: HomeViewModel

        // MARK: Body
        
        var body: some View {
            NavigationLink(value: HomeViewNavigationDestination.reviewRemindersList) {
                IconLabelGroupBox(
                    label: IconLabel(
                        icon: "bell.badge.fill",
                        title: "Review Reminders",
                        labelColor: Color("BrandPrimary"),
                        background: true
                    ),
                    description:
                        Text("Summary of your review reminders.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                ) {
                    if viewModel.reviewReminders.isEmpty {
                        EmptyStateView(
                            image: "bell.badge.slash",
                            title: "No Review Reminders",
                            description: "Tap the + button to create a review reminder."
                        )
                    } else {
                        recentReviewRemindersSummary
                    }
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                } footer: {
                    createReviewReminderButton
                }
            }
            .foregroundStyle(.primary)
        }

        // MARK: Recent Review Reminders Summary

        private var recentReviewRemindersSummary: some View {
            Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.recentReviewReminders, id: \.self) { reviewReminder in
                        ReviewReminderCell(reviewReminder: reviewReminder, withBackground: false) {
                            viewModel.presentSheet(.createReviewReminderView(reviewReminder))
                        }
                        if viewModel.recentReviewReminders.last != reviewReminder {
                            Divider()
                        }
                    }
                }
            }
        }

        // MARK: Create Review Reminder Button

        private var createReviewReminderButton: some View {
            Button {
                viewModel.presentSheet(.createReviewReminderView(nil))
            } label: {
                IconLabel(icon: "plus.circle", title: "Create Review Reminder", labelColor: Color("BrandPrimary"))
                    .font(.subheadline.weight(.semibold))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    ScrollView {
        HomeView.ReviewRemindersWidget(viewModel: viewModel)
    }
    .background(Color(.systemGroupedBackground))
}

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
        @Bindable var viewModel: HomeViewModel
        
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
                        VStack(alignment: .leading, spacing: 16) {
                            ContentUnavailableView(
                                "No Review Reminders",
                                systemImage: "bell.badge.slash.fill",
                                description: Text("Tap the **+** button to create a review reminder.")
                            )
                        }
                    } else {
                        Card(backgroundColor: Color(.tertiarySystemGroupedBackground)) {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(viewModel.recentReviewReminders, id: \.self) { reviewReminder in
                                    ReviewReminderCell(reviewReminder: reviewReminder, withBackground: false) {
                                        viewModel.presentSheet(.createReviewReminderSheet(reviewReminder))
                                    }
                                    if viewModel.recentReviewReminders.last != reviewReminder {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                } accessoryIndicator: {
                    Icon(name: "chevron.right", color: Color(.systemGray2))
                        .font(.subheadline.weight(.semibold))
                } footer: {
                    Button {
                        viewModel.presentSheet(.createReviewReminderSheet(nil))
                    } label: {
                        IconLabel(icon: "plus.circle", title: "Create Review Reminder", labelColor: Color("BrandPrimary"))
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.ReviewRemindersWidget(viewModel: viewModel)
}

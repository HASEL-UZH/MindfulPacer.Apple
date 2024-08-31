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
                    // TODO: Implement ReviewReminderSummaryCell
                    if viewModel.reviewReminders.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            ContentUnavailableView(
                                "No Review Reminders",
                                systemImage: "bell.badge.slash.fill",
                                description: Text("Tap the **+** button to create a review reminder.")
                            )
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.reviewReminders.prefix(3), id: \.self) { reviewReminder in
                                reviewReminderCell(for: reviewReminder)
                                if viewModel.reviewReminders.last != reviewReminder {
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
                        viewModel.presentSheet(.createReviewReminderSheet)
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

// MARK: - Review Reminder Cell

extension HomeView.ReviewRemindersWidget {
    @ViewBuilder private func reviewReminderCell(for reviewReminder: ReviewReminder) -> some View {
        NavigationLink(value: Int()) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    IconLabel(
                        icon: reviewReminder.measurementType.icon,
                        title: reviewReminder.measurementType.rawValue,
                        labelColor: reviewReminder.measurementType == .heartRate ? .pink : .teal
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    Text("Above \(reviewReminder.threshold) \(reviewReminder.measurementType == .heartRate ? "bpm" : "steps") for \(reviewReminder.interval.rawValue)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Icon(
                    name: "alarm.waves.left.and.right",
                    color: reviewReminder.alarmType.color
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    
    HomeView.ReviewRemindersWidget(viewModel: viewModel)
}

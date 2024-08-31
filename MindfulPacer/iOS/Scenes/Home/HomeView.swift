//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Presentation Enums

enum HomeViewNavigationDestination: Hashable {
    case reviewsList
    case reviewRemindersList
}

enum HomeViewSheet: Identifiable {
    case editReviewSheet(Review?)
    case createReviewReminderSheet
    
    var id: Int {
        switch self {
        case .editReviewSheet(_): 0
        case .createReviewReminderSheet: 1
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StepsWidget()
                            HeartRateWidget()
                        }
                        ReviewsWidget(viewModel: viewModel)
                        reviewRemindersWidget
                        AlarmTypeWidget()
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.bottom)
            }
            .navigationTitle("Home")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .navigationDestination(for: HomeViewNavigationDestination.self) { destination in
                switch destination {
                case .reviewsList:
                    ReviewsListView(viewModel: viewModel)
                case .reviewRemindersList:
                    Text("Review Reminders List View")
                }
            }
            .sheet(item: $viewModel.activeSheet, onDismiss: {
                viewModel.onSheetDismissed()
            }) { sheet in
                switch sheet {
                case .editReviewSheet(let review):
                    EditReviewView(review: review)
                        .interactiveDismissDisabled(review.isNil)
                        .presentationCornerRadius(16)
                        .presentationDragIndicator(review.isNil ? .hidden : .visible)
                case .createReviewReminderSheet:
                    CreateReviewReminderView()
                        .interactiveDismissDisabled()
                        .presentationCornerRadius(16)
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
        }
    }
}

// MARK: - Review Reminders Widget

extension HomeView {
    private var reviewRemindersWidget: some View {
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
                        ForEach(viewModel.reviewReminders.prefix(3)) { reviewReminder in
                            ReviewReminderSummaryCell(reviewReminder: reviewReminder)
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

// MARK: - ReviewReminderSummaryCell

fileprivate struct ReviewReminderSummaryCell: View {
    var reviewReminder: ReviewReminder
    
    var body: some View {
        NavigationLink(value: Int()) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    IconLabel(
                        icon: reviewReminder.measurementType.icon,
                        title: reviewReminder.measurementType.rawValue,
                        labelColor: reviewReminder.measurementType == .heartRate ? .pink : .teal
                    )
                    .font(.subheadline.weight(.semibold))
                    
                    Text("Above \(reviewReminder.threshold) \(reviewReminder.measurementType == .heartRate ? "bpm" : "steps")")
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
    TabView {
        HomeView()
            .tabItem {
                Label("Home", systemImage: "house")
            }
    }
    .tint(Color("BrandPrimary"))
}

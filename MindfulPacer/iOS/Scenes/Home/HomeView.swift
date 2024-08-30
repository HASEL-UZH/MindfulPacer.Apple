//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Navigation Enums

enum HomeViewNavigationDestination: Hashable {
    case reviewsList
    case reviewRemindersList
}

enum HomeViewSheet: Identifiable {
    case createReviewSheet
    case createReviewReminderSheet
    
    var id: Int {
        hashValue
    }
}

// MARK: - HomeView

struct HomeView: View {
    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    @Query private var reviews: [Review]
    @Query private var reviewReminders: [ReviewReminder]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            stepsWidget
                            heartRateWidget
                        }
                        reviewsWidget
                        reviewRemindersWidget
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
            .alert(item: $viewModel.alertItem) { $0.alert }
            .navigationDestination(for: HomeViewNavigationDestination.self) { destination in
                switch destination {
                case .reviewsList:
                    ReviewsListView(viewModel: viewModel)
                case .reviewRemindersList:
                    Text("Review Reminders List View")
                }
            }
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .createReviewSheet:
                    CreateReviewView()
                        .interactiveDismissDisabled()
                        .presentationCornerRadius(16)
                case .createReviewReminderSheet:
                    CreateReviewReminderView()
                        .interactiveDismissDisabled()
                        .presentationCornerRadius(16)
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
            .onChange(of: reviews) { viewModel.updateReviews(with: reviews) }
            .onChange(of: reviewReminders) { viewModel.updateReviewReminders(with: reviewReminders) }
        }
    }
}

// MARK: - Steps Widget

extension HomeView {
    private var stepsWidget: some View {
        NavigationLink(value: Int()) {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: "figure.walk",
                    title: "Steps",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
            ) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("9,870")
                        .font(.title.weight(.semibold))
                    Text("steps")
                        .foregroundStyle(.secondary)
                }
            } accessoryIndicator: {
                Icon(name: "chevron.right", color: Color(.systemGray2))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.primary)
        }
    }
}

// MARK: - Heart Rate Widget

extension HomeView {
    private var heartRateWidget: some View {
        NavigationLink(value: Int()) {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: "heart.fill",
                    title: "Heart Rate",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
            ) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("68")
                        .font(.title.weight(.semibold))
                    Text("bpm")
                        .foregroundStyle(.secondary)
                }
            } accessoryIndicator: {
                Icon(name: "chevron.right", color: Color(.systemGray2))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(.primary)
        }
    }
}

// MARK: - Reviews Widget

extension HomeView {
    private var reviewsWidget: some View {
        NavigationLink(value: HomeViewNavigationDestination.reviewsList) {
            IconLabelGroupBox(
                label: IconLabel(
                    icon: "book.pages.fill",
                    title: "Reviews",
                    labelColor: Color("BrandPrimary"),
                    background: true
                ),
                description:
                    Text("This is a summary of your most recent reviews.")
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
                            ReviewSummaryCell(review: review)
                            if review != viewModel.reviews.last {
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
                    viewModel.presentSheet(.createReviewSheet)
                } label: {
                    IconLabel(icon: "plus.circle", title: "Create Review", labelColor: Color("BrandPrimary"))
                        .font(.subheadline.weight(.semibold))
                }
            }
//            .iconLabelGroupBoxStyle(.divider)
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - ReviewSummaryCell

fileprivate struct ReviewSummaryCell: View {
    var review: Review
    
    var body: some View {
        NavigationLink(value: Int()) {
            Button {
                // TODO: Navigation to Review
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
                    
//                    summaryIcons
                    if let mood = review.mood {
                        Text(mood)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .foregroundStyle(.primary)
        }
    }
    
    private var summaryIcons: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(spacing: 16), count: 4),
            spacing: 16
        ) {
            if let mood = review.mood {
                Text(mood)
                    .frame(width: 24, height: 24)
            }
            
            ratingIcon(for: .headaches, value: review.headachesRating)
            ratingIcon(for: .energyLevel, value: review.perceivedEnergyLevelRating)
            ratingIcon(for: .shortnessOfBreath, value: review.shortnessOfBreatheRating)
            ratingIcon(for: .fever, value: review.feverRating)
            ratingIcon(for: .painsAndNeedles, value: review.painsAndNeedlesRating)
            ratingIcon(for: .muscleAches, value: review.muscleAchesRating)
        }
    }
    
    @ViewBuilder private func ratingIcon(for type: ReviewMetricRatingType, value: Int?) -> some View {
        if value != nil {
            let reviewMetricRating = ReviewMetricRating(type: type, value: value)
            Icon(
                name: reviewMetricRating.type.icon,
                color: reviewMetricRating.color
            )
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
                    Text("This is a summary of your review reminders.")
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
//            .iconLabelGroupBoxStyle(.divider)
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - ReviewReminderSummaryCell

fileprivate struct ReviewReminderSummaryCell: View {
    var reviewReminder: ReviewReminder
    
    var body: some View {
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

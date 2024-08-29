//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI
import SwiftData

// MARK: - Navigation Enums

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
            .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .createReviewSheet:
                    CreateReviewView()
                        .interactiveDismissDisabled()
                case .createReviewReminderSheet:
                    CreateReviewReminderView()
                        .interactiveDismissDisabled()
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
            .onChange(of: reviews) { viewModel.updateReviews(with: reviews) }
        }
    }
    
    private var stepsWidget: some View {
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
        } button: {
            Button {
                // TODO: Show Steps analytics
            } label: {
                Icon(name: "chevron.right.circle", variant: .fill)
            }
        }
    }
    
    private var heartRateWidget: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "heart.fill",
                title: "Heart Rate",
                labelColor: Color("BrandPrimary")
            )
        ) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("68")
                    .font(.title.weight(.semibold))
                Text("bpm")
                    .foregroundStyle(.secondary)
            }
        } button: {
            Button {
                // TODO: Show Heart Rate analytics
            } label: {
                Icon(name: "chevron.right", color: .secondary)
            }
        }
        .iconLabelGroupBoxStyle(.divider)
    }
    
    private var reviewsWidget: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "book.pages.fill",
                title: "Reviews",
                labelColor: Color("BrandPrimary"),
                background: true
            ),
            description:
                Text("This is a summary of your reviews.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        ) {
            VStack(alignment: .leading, spacing: 16) {
                if viewModel.reviews.isEmpty {
                    ContentUnavailableView(
                        "No Reviews",
                        systemImage: "book.pages.fill",
                        description: Text("Tap the **+** button to create a review.")
                    )
                } else {
                    ForEach(viewModel.reviews) { review in
                        ReviewCell(review: review)
                        if review != viewModel.reviews.last {
                            Divider()
                        }
                    }
                }
            }
        } button: {
            Button {
                
            } label: {
                Icon(name: "chevron.right.circle", variant: .fill)
            }
        } footer: {
            Button {
                viewModel.presentSheet(.createReviewSheet)
            } label: {
                IconLabel(icon: "plus.circle", title: "Create Review", labelColor: Color("BrandPrimary"))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .iconLabelGroupBoxStyle(.divider)
    }
    
    private var reviewRemindersWidget: some View {
        IconLabelGroupBox(
            label: IconLabel(
                icon: "bell.badge.fill",
                title: "Review Reminders",
                labelColor: Color("BrandPrimary")
            ),
            description:
                Text("This is a summary of your review reminders.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        ) {
            VStack(alignment: .leading, spacing: 16) {
                ContentUnavailableView(
                    "No Review Reminders",
                    systemImage: "bell.badge.slash.fill",
                    description: Text("Tap the **+** button to create a review reminder.")
                )
            }
        } button: {
            Button {
                viewModel.presentSheet(.createReviewReminderSheet)
            } label: {
                Icon(name: "plus", variant: .circle)
            }
        }
        .iconLabelGroupBoxStyle(.divider)
    }
}

// MARK: - ReviewCell

private struct ReviewCell: View {
    var review: Review
    
    var body: some View {
        NavigationLink(value: Int()) {
            HStack(spacing: 16) {
                if let category = review.category {
                    Icon(name: category.icon, color: Color("BrandPrimary"), background: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .fontWeight(.semibold)
                        
                        Text(review.date.formatted(.dateTime.day().month().hour().minute()))
                            .font(.footnote)
                    }
                }
                
                Spacer()
                  
                summaryIcons
            }
        }
        .foregroundStyle(.primary)
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

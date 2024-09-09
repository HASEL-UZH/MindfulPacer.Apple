//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum HomeViewNavigationDestination: Hashable {
    case reviewsList
    case reviewRemindersList
}

enum HomeViewSheet: Identifiable {
    case editReviewSheet(Review?)
    case createReviewReminderSheet(ReviewReminder?)
    case reviewsFilterView
    
    var id: Int {
        switch self {
        case .editReviewSheet(_): 0
        case .createReviewReminderSheet(_): 1
        case .reviewsFilterView: 2
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    // MARK: Properties
    
    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    // MARK: Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    stepsAndHeartRateSection
                    ReviewsWidget(viewModel: viewModel)
                    ReviewRemindersWidget(viewModel: viewModel)
                    ReviewReminderTypeWidget()
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Home")
            .background {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
            }
            .navigationDestination(for: HomeViewNavigationDestination.self, destination: navigationDestination)
            .sheet(item: $viewModel.activeSheet, onDismiss: {
                withAnimation {
                    viewModel.onSheetDismissed()
                }
            }) { sheetContent(for: $0) }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
        }
    }
    
    // MARK: Steps and Heart Rate Section
    
    private var stepsAndHeartRateSection: some View {
        HStack(spacing: 16) {
            StepsWidget(viewModel: viewModel)
            HeartRateWidget()
        }
    }
    
    // MARK: Navigation Destination
    
    @ViewBuilder
    private func navigationDestination(for destination: HomeViewNavigationDestination) -> some View {
        switch destination {
        case .reviewsList:
            ReviewsListView(viewModel: viewModel)
        case .reviewRemindersList:
            ReviewRemindersListView(viewModel: viewModel)
        }
    }
    
    // MARK: Sheet Content
    
    @ViewBuilder
    private func sheetContent(for sheet: HomeViewSheet) -> some View {
        switch sheet {
        case .editReviewSheet(let review):
            EditReviewView(review: review)
                .interactiveDismissDisabled(review.isNil)
                .presentationCornerRadius(16)
                .presentationDragIndicator(review.isNil ? .hidden : .visible)
        case .createReviewReminderSheet(let reviewReminder):
            CreateReviewReminderView(reviewReminder: reviewReminder)
                .interactiveDismissDisabled(reviewReminder.isNil)
                .presentationCornerRadius(16)
                .presentationDragIndicator(reviewReminder.isNil ? .hidden : .visible)
        case .reviewsFilterView:
            ReviewsFilterView(filterAndSortingPublisher: viewModel.filterAndSortingPublisher)
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(16)
            .presentationDragIndicator(.visible)
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

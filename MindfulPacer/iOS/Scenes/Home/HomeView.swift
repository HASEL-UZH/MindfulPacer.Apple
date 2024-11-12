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
    case analytics
}

enum HomeViewSheet: Identifiable {
    case editReviewView(Review?)
    case createReviewReminderView(ReviewReminder?)
    case reviewsFilterView

    var id: Int {
        switch self {
        case .editReviewView: 0
        case .createReviewReminderView: 1
        case .reviewsFilterView: 2
        }
    }
}

// MARK: - HomeView

struct HomeView: View {
    
    // MARK: Properties

    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()
    var onWidgetTap: () -> Void
    
    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ReviewsWidget(viewModel: viewModel)
                    stepsAndHeartRateWidgets
                    ReviewRemindersWidget(viewModel: viewModel)
//                    ReviewReminderTypeWidget()
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
            }, content: { sheet in
                sheetContent(for: sheet)
            })
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
            .onAppear {
                viewModel.onViewAppear()
            }
        }
    }
    
    // MARK: Steps and Heart Rate Widgets
    
    private var stepsAndHeartRateWidgets: some View {
        HStack(spacing: 16) {
            Button {
                onWidgetTap()
            } label: {
                StepsWidget(viewModel: viewModel)
            }
            
            Button {
                onWidgetTap()
            } label: {
                HeartRateWidget(viewModel: viewModel)
            }
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
        case .analytics:
            AnalyticsView()
        }
    }

    // MARK: Sheet Content

    @ViewBuilder
    private func sheetContent(for sheet: HomeViewSheet) -> some View {
        switch sheet {
        case .editReviewView(let review):
            EditReviewView(review: review)
                .interactiveDismissDisabled(review.isNil)
                .presentationCornerRadius(16)
                .presentationDragIndicator(review.isNil ? .hidden : .visible)
        case .createReviewReminderView(let reviewReminder):
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
        HomeView(onWidgetTap: { })
            .tabItem {
                Label("Home", systemImage: "house")
            }
    }
    .tint(Color("BrandPrimary"))
}

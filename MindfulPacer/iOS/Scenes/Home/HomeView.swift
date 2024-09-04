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
    @State var viewModel: HomeViewModel = ScenesContainer.shared.homeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StepsWidget(viewModel: viewModel)
                            HeartRateWidget()
                        }
                        ReviewsWidget(viewModel: viewModel)
                        ReviewRemindersWidget(viewModel: viewModel)
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
                    ReviewRemindersListView(viewModel: viewModel)
                }
            }
            .sheet(item: $viewModel.activeSheet, onDismiss: {
                withAnimation {
                    viewModel.onSheetDismissed()
                }
            }) { sheet in
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
                    ReviewsFilterView(viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                        .presentationCornerRadius(16)
                        .presentationDragIndicator(.visible)
                }
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
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

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
    case missedReviews

    var id: Int {
        switch self {
        case .editReviewView: 0
        case .createReviewReminderView: 1
        case .reviewsFilterView: 2
        case .missedReviews: 3
        }
    }
}

enum HomeViewToast: Identifiable {
    case successfullyCreatedReview
    
    var id: Int {
        hashValue
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
                    missedReviewsWidget
                    ReviewsWidget(viewModel: viewModel)
                    stepsAndHeartRateWidgets
                    ReviewRemindersWidget(viewModel: viewModel)
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
            .toast(item: $viewModel.activeToast) { toast in
                toastContent(for: toast)
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
            .onAppear {
                viewModel.onViewAppear()
            }
        }
    }
    
    // MARK: Missed Reviews Widget
    
    @ViewBuilder
    private var missedReviewsWidget: some View {
        if !viewModel.missedReviews.isEmpty {
            Button {
                viewModel.presentSheet(.missedReviews)
            } label: {
                Card {
                    Label {
                        Text(viewModel.missedReviewsWidgetTitle)
                            .font(.subheadline.weight(.semibold))
                    } icon: {
                        Image(systemName: "bell.badge.fill")
                            .symbolRenderingMode(.palette)
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.red, Color.brandPrimary)
                            .padding(4)
                            .background {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundStyle(Color.brandPrimary.opacity(0.1))
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.brandPrimary.opacity(0.1), lineWidth: 1.5)
                                }
                            }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            EmptyView()
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
            EditReviewView(review: review, onReviewCreation: {
                viewModel.presentToast(.successfullyCreatedReview)
            })
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
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        case .missedReviews:
            MissedReviewsView(viewModel: viewModel)
                .presentationCornerRadius(16)
                .presentationDragIndicator(.visible)
        }
    }
    
    // MARK: Toast Content
    
    private func toastContent(for toast: HomeViewToast) -> some View {
        switch toast {
        case .successfullyCreatedReview:
            Toast(
                title: "Successfully Created Review",
                message: "Your review has been saved"
            )
            .toastStyle(.success)
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

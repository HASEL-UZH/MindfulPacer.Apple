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
                    Text("Review Reminders List View")
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

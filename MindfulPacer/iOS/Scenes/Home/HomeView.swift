//
//  HomeView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import SwiftUI

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
        }
    }
    
    private var stepsWidget: some View {
        SFSymbolGroupBox(
            label: SFSymbolLabel(
                icon: "figure.walk",
                title: "Steps",
                labelColor: Color("BrandPrimary")
            )
        ) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("9,870")
                    .font(.title.weight(.semibold))
                Text("steps")
                    .foregroundStyle(.secondary)
            }
        } button: {
            Button("View Graph", systemImage: "chevron.down.circle.fill") {
                
            }
            .labelStyle(.iconOnly)
        }
    }
    
    private var heartRateWidget: some View {
        SFSymbolGroupBox(
            label: SFSymbolLabel(
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
            Button("View Graph", systemImage: "chevron.down.circle.fill") {
                
            }
            .labelStyle(.iconOnly)
        }
    }
    
    private var reviewsWidget: some View {
        SFSymbolGroupBox(
            label: SFSymbolLabel(
                icon: "book.pages.fill",
                title: "Reviews",
                labelColor: Color("BrandPrimary")
            )
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("This is a summary of your reviews.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                if viewModel.reviews.isEmpty {
                    ContentUnavailableView(
                        "No Reviews",
                        systemImage: "book.pages.fill",
                        description: Text("Tap the **+** button to create a review.")
                    )
                } else {
                    ForEach(viewModel.reviews) { review in
                        if review.category != nil {
                            ReviewCell(review: review)
                        }
                    }
                }
            }
        } button: {
            Button("Add Review", systemImage: "plus.circle.fill") {
                viewModel.presentSheet(.createReviewSheet)
            }
            .labelStyle(.iconOnly)
        }
    }
    
    private var reviewRemindersWidget: some View {
        SFSymbolGroupBox(
            label: SFSymbolLabel(
                icon: "bell.badge.fill",
                title: "Review Reminders",
                labelColor: Color("BrandPrimary")
            )
        ) {
            VStack(alignment: .leading, spacing: 16) {
                Text("This is a summary of your review reminders.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Divider()
                
                ContentUnavailableView(
                    "No Reviews",
                    systemImage: "bell.badge.slash.fill",
                    description: Text("Tap the **+** button to create a review reminder.")
                )
            }
        } button: {
            Button("Add Review", systemImage: "plus.circle.fill") {
                viewModel.presentSheet(.createReviewReminderSheet)
            }
            .labelStyle(.iconOnly)
        }
    }
}

// MARK: - ReviewCell

private struct ReviewCell: View {
    var review: Review
    
    var body: some View {
        NavigationLink(value: Int()) {
            HStack(spacing: 16) {
                if let category = review.category {
                    SFSymbolIcon(name: category.icon, color: Color("BrandPrimary"), background: true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(category.name)
                            .fontWeight(.semibold)
                        
                        Text(review.date.formatted(.dateTime.day().month().hour().minute()))
                            .font(.footnote)
                    }
                }
                
                Spacer()
            }
        }
        .foregroundStyle(.primary)
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

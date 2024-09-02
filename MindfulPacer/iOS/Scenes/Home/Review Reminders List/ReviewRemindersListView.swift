//
//  ReviewRemindersListView.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import SwiftUI

// MARK: - ReviewRemindersListView

struct ReviewRemindersListView: View {
    @Bindable var viewModel: HomeViewModel
    
    // MARK: Body
    
    var body: some View {
        VStack {
            if viewModel.reviewReminders.isEmpty {
                reviewRemindersEmptyState
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(viewModel.reviewReminders) { reviewReminder in
                            ReviewReminderCell(reviewReminder: reviewReminder) {
                                viewModel.presentSheet(.createReviewReminderSheet(reviewReminder))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .listStyle(.grouped)
        .navigationTitle("Review Reminders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentSheet(.createReviewReminderSheet(nil))
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    // MARK: Review Reminders Empty State
    
    var reviewRemindersEmptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            ContentUnavailableView {
                Label("No Review Reminders", systemImage: "bell.badge.fill")
            } description: {
                Text("You have not created any review reminders.")
            } actions: {
                Button {
                    viewModel.presentSheet(.editReviewSheet(nil))
                } label: {
                    Text("Create Review")
                }
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = ScenesContainer.shared.homeViewModel()
    
    NavigationStack {
        ReviewRemindersListView(viewModel: viewModel)
    }
}

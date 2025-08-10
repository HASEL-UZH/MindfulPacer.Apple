//
//  RemindersListView.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import SwiftUI

// MARK: - RemindersListView

struct RemindersListView: View {
    
    // MARK: Properties

    @Bindable var viewModel: HomeViewModel

    // MARK: Body

    var body: some View {
        VStack {
            if viewModel.reminders.isEmpty {
                remindersEmptyState
                    .frame(maxHeight: .infinity, alignment: .center)
            } else {
                RoundedList {
                    Section {
                        ForEach(viewModel.reminders) { reminder in
                            ReminderCell(reminder: reminder) {
                                viewModel.presentSheet(.createReminderView(reminder))
                            }
                        }
                    }
                    
                    Section {
                        PrimaryButton(title: "Sync with Watch", icon: "applewatch.radiowaves.left.and.right") {
                            WatchUpdateService.shared.notifyWatchOfReminderChange()
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .listStyle(.grouped)
        .navigationTitle("Reminders")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentSheet(.createReminderView(nil))
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
        }
    }

    // MARK: Reminders Empty State

    var remindersEmptyState: some View {
        VStack(alignment: .leading, spacing: 16) {
            ContentUnavailableView {
                Label("No Reminders", systemImage: "bell.badge.fill")
            } description: {
                Text("You have not created any reminders.")
            } actions: {
                Button {
                    viewModel.presentSheet(.createReminderView(nil))
                } label: {
                    Text("Create Reminder")
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
        RemindersListView(viewModel: viewModel)
    }
}

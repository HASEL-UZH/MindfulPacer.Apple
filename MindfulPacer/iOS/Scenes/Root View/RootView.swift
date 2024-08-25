//
//  RootView.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    
    // TODO: Temporary, remove for production
    @State private var showCreateReviewView = false
    @State private var showCreateReviewReminderView = false
    @Query private var reviewReminders: [ReviewReminder]
    
    var body: some View {
        TabView {
            List {
                if reviewReminders.isEmpty {
                    Text("No Review Reminders")
                } else {
                    ForEach(reviewReminders) { reviewReminder in
                        VStack(alignment: .leading, spacing: 16) {
                            Text(reviewReminder.measurementType.rawValue)
//                            Text(reviewReminder.alarmType.rawValue)
                            Text(String(reviewReminder.threshold))
//                            Text(reviewReminder.vibrationStrength.rawValue)
                            Text(reviewReminder.interval.rawValue)
                        }
                    }
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .onAppear {
                showCreateReviewReminderView.toggle()
            }
        }
        .onViewFirstAppear {
            viewModel.onViewFirstAppear()
        }
        .sheet(isPresented: $showCreateReviewView) {
            CreateReviewView()
        }
        .sheet(isPresented: $showCreateReviewReminderView) {
            CreateReviewReminderView()
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
}

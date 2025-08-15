//
//  SelectActivityView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 15.08.2025.
//

import SwiftUI
import SwiftData

@Observable
class ActivitySelection {
    var reflectionID: UUID
    var selectedActivity: Activity?
    var selectedSubactivity: Subactivity?
    
    init(reflectionID: UUID) {
        self.reflectionID = reflectionID
    }
}

struct SelectActivityView: View {
    // This view now only needs the ID of the Reminder that triggered it.
    let reminderID: UUID
    
    private let fetchDefaultActivitiesUseCase = DefaultFetchDefaultActivitiesUseCase(modelContext: ModelContainer.prod.mainContext)
    @State private var activities: [Activity] = []
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(activities) { activity in
                NavigationLink(destination: SelectSubactivityView(reminderID: reminderID, activity: activity)) {
                    Label(activity.name, systemImage: activity.icon)
                }
            }
            .navigationTitle("Select Activity")
            .onAppear(perform: loadActivities)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        SystemDelegate.shared.createAndSendReflection(reminderID: reminderID, activity: nil, subactivity: nil)
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func loadActivities() {
        if let fetchedActivities = fetchDefaultActivitiesUseCase.execute() {
            self.activities = fetchedActivities
        }
    }
}

struct SelectSubactivityView: View {
    let reminderID: UUID
    let activity: Activity
    
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(activity.subactivities ?? []) { subactivity in
            Button {
                // When a subactivity is chosen, this is the final step on the watch.
                SystemDelegate.shared.createAndSendReflection(
                    reminderID: reminderID,
                    activity: activity,
                    subactivity: subactivity
                )
                dismiss()
            } label: {
                Label(subactivity.name, systemImage: subactivity.icon)
            }
        }
        .navigationTitle(activity.name)
    }
}

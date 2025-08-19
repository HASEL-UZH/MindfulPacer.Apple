//
//  SelectActivityView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 15.08.2025.
//

import SwiftUI
import SwiftData

// MARK: - ActivitySelection
@Observable
class ActivitySelection {
    var reflectionID: UUID
    var selectedActivity: Activity?
    var selectedSubactivity: Subactivity?
    
    init(reflectionID: UUID) {
        self.reflectionID = reflectionID
    }
}

// MARK: - SelectActivityView

struct SelectActivityView: View {
    let reminderID: UUID
    
    let activities: [Activity]
    
    @Environment(\.dismissSheet) private var dismissSheet

    var body: some View {
        NavigationStack {
            List(activities) { activity in
                NavigationLink(
                    destination:
                        SelectSubactivityView(
                            reminderID: reminderID,
                            activity: activity
                        )
                ) {
                    Label(activity.name, systemImage: activity.icon)
                        .symbolVariant(.fill)
                }
            }
            .navigationTitle("Select Activity")
        }
    }
}

// MARK: - SelectSubactivityView

struct SelectSubactivityView: View {
    let reminderID: UUID
    let activity: Activity
    
    @Environment(\.dismissSheet) private var dismissSheet

    var body: some View {
        List(activity.subactivities ?? []) { subactivity in
            Button {
                SystemDelegate.shared.createAndSendReflection(
                    reminderID: reminderID,
                    activity: activity,
                    subactivity: subactivity
                )
                dismissSheet()
            } label: {
                Label(subactivity.name, systemImage: subactivity.icon)
            }
        }
        .navigationTitle(activity.name)
    }
}

#Preview {
    SelectActivityView(
        reminderID: UUID(),
        activities: DefaultActivityData.allActivities
    )
}

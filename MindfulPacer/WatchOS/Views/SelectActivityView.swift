import SwiftUI
import SwiftData

struct SelectActivityView: View {
    let reminderID: UUID
    let alertID: UUID
    let activities: [Activity]
    
    @Environment(\.dismissSheet) private var dismissSheet

    var body: some View {
        NavigationStack {
            List(activities) { activity in
                NavigationLink(destination: SelectSubactivityView(reminderID: reminderID, alertID: alertID, activity: activity)) {
                    Label(activity.name, systemImage: activity.icon)
                }
            }
            .navigationTitle("Select Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        Task {
                            Services.shared.systemDelegate.createAndSendReflection(
                                reminderID: reminderID,
                                alertID: alertID,
                                activity: nil,
                                subactivity: nil
                            )
                            dismissSheet()
                        }
                    }
                }
            }
        }
    }
}

struct SelectSubactivityView: View {
    let reminderID: UUID
    let alertID: UUID
    let activity: Activity
    
    @Environment(\.dismissSheet) private var dismissSheet

    var body: some View {
        List(activity.subactivities ?? []) { subactivity in
            Button {
                Task {
                    Services.shared.systemDelegate.createAndSendReflection(
                        reminderID: reminderID,
                        alertID: alertID,
                        activity: activity,
                        subactivity: subactivity
                    )
                    dismissSheet()
                }
            } label: {
                Label(subactivity.name, systemImage: subactivity.icon)
            }
        }
        .navigationTitle(activity.name)
    }
}

#Preview("Activity List") {
    SelectActivityView(
        reminderID: UUID(),
        alertID: UUID(),
        activities: DefaultActivityData.allActivities
    )
}

#Preview("Subactivity List") {
    NavigationStack {
        SelectSubactivityView(
            reminderID: UUID(),
            alertID: UUID(),
            activity: DefaultActivityData.allActivities.first!
        )
    }
}

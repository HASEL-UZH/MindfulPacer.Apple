import SwiftUI
import SwiftData

struct SelectActivityView: View {
    let reminderID: UUID
    let alertID: UUID

    @Query(sort: \Activity.name) private var activities: [Activity]
    @Environment(\.dismissSheet) private var dismissSheet

    var body: some View {
        NavigationStack {
            List {
                if activities.isEmpty {
                    WatchEmptyState(title: "Activities Not Synced", symbol: "iphone",
                                    message: "Open MindfulPacer on your iPhone to sync activities. You can add details later.")
                } else {
                    Section {
                        ForEach(activities) { activity in
                            NavigationLink {
                                SelectSubactivityView(reminderID: reminderID, alertID: alertID, activity: activity)
                            } label: {
                                WatchActivityLabel(name: activity.name, symbol: activity.icon)
                            }
                        }
                    } header: {
                        Text("What were you doing?")
                    }
                }
            }
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { save(activity: nil, subactivity: nil) }
                        .accessibilityIdentifier("watch.activity.later")
                }
            }
        }
    }

    private func save(activity: Activity?, subactivity: Subactivity?) {
        Services.shared.systemDelegate.createAndSendReflection(
            reminderID: reminderID, alertID: alertID, activity: activity, subactivity: subactivity)
        dismissSheet()
    }
}

struct SelectSubactivityView: View {
    let reminderID: UUID
    let alertID: UUID
    let activity: Activity
    @Environment(\.dismissSheet) private var dismissSheet

    var body: some View {
        List {
            Section {
                Button {
                    save(nil)
                } label: {
                    Label("Use \(activity.name)", systemImage: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
                ForEach((activity.subactivities ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) { subactivity in
                    Button { save(subactivity) } label: {
                        WatchActivityLabel(name: subactivity.name, symbol: subactivity.icon)
                    }
                }
            } header: {
                Text("Choose an activity")
            }
        }
        .navigationTitle(activity.name)
    }

    private func save(_ subactivity: Subactivity?) {
        Services.shared.systemDelegate.createAndSendReflection(
            reminderID: reminderID, alertID: alertID, activity: activity, subactivity: subactivity)
        dismissSheet()
    }
}

private struct WatchActivityLabel: View {
    let name: String
    let symbol: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 24)
                .accessibilityHidden(true)
            Text(name).font(.body).foregroundStyle(Color.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SelectActivityView(reminderID: UUID(), alertID: UUID()).modelContainer(.preview)
}

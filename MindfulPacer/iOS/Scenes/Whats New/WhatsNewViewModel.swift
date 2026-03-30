//
//  WhatsNewViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2025.
//

import Foundation
import SwiftUI

// MARK: - ReleaseNote

struct ReleaseNote: Identifiable {
    let id = UUID()
    let version: String
    let notes: [String]
}

// MARK: - WhatsNewViewModel

@Observable
final class WhatsNewViewModel {

    // MARK: - Storage Keys

    private let whatsNewDefaultsKey = "lastSeenWhatsNewVersion"

    // MARK: - Data Source

    /// Ordered newest-first.
    let releaseNotes: [ReleaseNote] = [
        ReleaseNote(
            version: "1.8.4",
            notes: [
                String(localized: "Live data syncing — reflections now show up reliably across devices."),
                String(localized: "Missed reflections count is consistent between the watch badge and the phone widget."),
                String(localized: "Missing sub-activities added."),
                String(localized: "Fixed an issue where the 1-day step reminder could trigger incorrectly.")
            ]
        ),
        ReleaseNote(
            version: "1.8.3",
            notes: [
                String(localized: "Steps tracking now accurately reflects today's activity, fixing a midnight miscounting issue."),
                String(localized: "The analytics view now shows the selected date in the label for clearer context."),
                String(localized: "Added \"Toilet\" as a new option under Self-care activities."),
                String(localized: "Fixed threshold lines not appearing in the steps chart (1-week view)."),
                String(localized: "Fixed the watch complication sometimes showing the wrong monitoring status."),
                String(localized: "Minor UI cleanup.")
            ]
        ),
        ReleaseNote(
            version: "1.8.2",
            notes: [
                String(localized: "Updated Analytics text to show a simpler summary."),
                String(localized: "Improved onboarding for Return to Clock with updated steps and troubleshooting info."),
                String(localized: "1-day step reminders no longer send repeated notifications after you interact with the first one."),
                String(localized: "Added a confirmation prompt before pausing monitoring."),
                String(localized: "1-day step reminders now show a chart in missed reflections."),
                String(localized: "Apple Watch section in Settings is now hidden.")
            ]
        ),
        ReleaseNote(
            version: "1.8.1",
            notes: [
                String(localized: "Added 2-minute time interval for heart rate reminders."),
                String(localized: "Added missing German translations."),
                String(localized: "Charts are no longer shown for the 1-day step interval."),
                String(localized: "Intervals larger than the chosen period are no longer shown in analytics.")
            ]
        ),
        ReleaseNote(
            version: "1.5",
            notes: [
                String(localized: "New Apple Watch app for continuous heart rate and step monitoring."),
                String(localized: "Enhanced reflections — visualize the data that triggered a reminder."),
                String(localized: "Apple Watch complication to view monitoring status at a glance.")
            ]
        )
    ]

    // MARK: - Computed

    private var currentVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }

    /// True when the current app version has release notes the user hasn't seen.
    var isCurrentVersionNew: Bool {
        releaseNotes.contains { $0.version == currentVersion }
    }

    // MARK: - API

    func shouldPresentWhatsNew() -> Bool {
        let lastSeen = UserDefaults.standard.string(forKey: whatsNewDefaultsKey)
        return isCurrentVersionNew && lastSeen != currentVersion
    }

    func markWhatsNewSeen() {
        UserDefaults.standard.set(currentVersion, forKey: whatsNewDefaultsKey)
    }
}

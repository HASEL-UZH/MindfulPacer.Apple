//
//  ReleaseNotesViewModel.swift
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

// MARK: - ReleaseNotesViewModel

@Observable
final class ReleaseNotesViewModel {

    // MARK: - Storage Keys

    private let whatsNewDefaultsKey = "lastSeenWhatsNewVersion"

    // MARK: - Data Source

    /// Ordered newest-first. One entry per public release with a short summary.
    let releaseNotes: [ReleaseNote] = [
        ReleaseNote(
            version: "1.8",
            notes: [
                String(localized: "Live data syncing across devices."),
                String(localized: "Improved step tracking accuracy and notifications."),
                String(localized: "New activities and missing sub-activities added."),
                String(localized: "Various bug fixes and UI improvements.")
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

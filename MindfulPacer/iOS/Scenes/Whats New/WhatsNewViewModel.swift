//
//  WhatsNewViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2025.
//

import Foundation
import SwiftUI

// MARK: - NewFeature

struct NewFeature: Identifiable {
    var id: String { title }
    
    var title: String
    var description: String
    var icon: String
    var color: Color = .brandPrimary
}

// MARK: - WhatsNewViewModel

@Observable
final class WhatsNewViewModel {
    
    // MARK: - Storage Keys
    
    private let whatsNewDefaultsKey = "lastSeenWhatsNewVersion"
    
    // MARK: - Data Source
    
    // Version → Features
    private let allWhatsNew: [String: [NewFeature]] = [
        "1.5": [
            NewFeature(
                title: String(localized: "Apple Watch Support"),
                description: String(localized: "New WatchOS app to continuously monitor your heart rate and step reminders."),
                icon: "applewatch"
            ),
            NewFeature(
                title: String(localized: "Enhanced Reflections"),
                description: String(localized: "Visualize the data that led to a triggered reminder."),
                icon: "chart.xyaxis.line"
            ),
            NewFeature(
                title: String(localized: "Apple Watch Complication"),
                description: String(localized: "View the status of the continuous monitoring at a glance."),
                icon: "platter.filled.top.applewatch.case"
            )
        ]
    ]
    
    // MARK: - Computed
    
    private var currentVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }
    
    var whatsNewFeatures: [NewFeature] {
        allWhatsNew[currentVersion] ?? []
    }
    
    // MARK: - API
    
    /// Returns true if there are features for the current version that the user hasn't seen yet.
    func shouldPresentWhatsNew() -> Bool {
        let lastSeen = UserDefaults.standard.string(forKey: whatsNewDefaultsKey)
        return !(allWhatsNew[currentVersion]?.isEmpty ?? true) && lastSeen != currentVersion
    }
    
    /// Mark the current version’s “What’s New” as seen.
    func markWhatsNewSeen() {
        UserDefaults.standard.set(currentVersion, forKey: whatsNewDefaultsKey)
    }
}

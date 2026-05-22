//
//  WatchOSApp.swift
//  WatchOSApp
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI
import SwiftData
import UserNotifications
import WatchConnectivity
import WatchKit

final class WatchApplicationDelegate: NSObject, WKApplicationDelegate {
    func handleActiveWorkoutRecovery() {
        Task { @MainActor in
            Services.shared.monitorService.handleActiveWorkoutRecovery()
        }
    }
}

@main
struct WatchOSApp: App {
    
    @WKApplicationDelegateAdaptor(WatchApplicationDelegate.self) private var applicationDelegate
    @StateObject private var navigationManager = Services.shared.navigationManager
    private let systemDelegate = Services.shared.systemDelegate

    init() {
        Services.shared.configure()
        
        UNUserNotificationCenter.current().delegate = systemDelegate
        WCSession.default.delegate = systemDelegate
        
        if WCSession.isSupported() {
            WCSession.default.activate()
        }
        
        registerNotificationCategories()
        
        Task {
            Services.shared.monitorService.checkForRecoveredWorkoutSessionOnLaunch()
            Services.shared.monitorService.verifyComplicationStateOnLaunch()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navigationManager)
        }
        .modelContainer(.prod)
    }
    
    private func registerNotificationCategories() {
        let acceptAddDetailsAction = UNNotificationAction(
            identifier: "ACCEPT_ADD_DETAILS_ACTION",
            title: String(localized: "Accept & Add Details"),
            options: .foreground
        )
        
        let acceptLaterAction = UNNotificationAction(
            identifier: "ACCEPT_LATER_ACTION",
            title: String(localized: "Accept & Add Later"),
            options: []
        )
        
        let heartRateAlertCategory = UNNotificationCategory(
            identifier: "HEART_RATE_ALERT",
            actions: [acceptAddDetailsAction, acceptLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([heartRateAlertCategory])
    }
}

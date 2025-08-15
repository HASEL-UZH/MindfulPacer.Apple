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

@main
struct WatchOSApp: App {
    
    private let systemDelegate = SystemDelegate()
    
    init() {
        UNUserNotificationCenter.current().delegate = systemDelegate
        WCSession.default.delegate = systemDelegate
        
        if WCSession.isSupported() {
            WCSession.default.activate()
        }
        
        registerNotificationCategories()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
    
    private func registerNotificationCategories() {
        let acceptAddDetailsAction = UNNotificationAction(
            identifier: "ACCEPT_ADD_DETAILS_ACTION",
            title: "Accept & Add Details",
            options: .foreground
        )
        
        let acceptLaterAction = UNNotificationAction(
            identifier: "ACCEPT_LATER_ACTION",
            title: "Accept & Add Later",
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

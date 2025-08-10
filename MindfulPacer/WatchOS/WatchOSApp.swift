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
        let viewDetailsAction = UNNotificationAction(
            identifier: "VIEW_DETAILS_ACTION",
            title: "View Details",
            options: .foreground
        )
        
        let createReflectionAction = UNNotificationAction(
            identifier: "CREATE_REFLECTION_ACTION",
            title: "Create Reflection",
            options: .foreground
        )
        
        let heartRateAlertCategory = UNNotificationCategory(
            identifier: "HEART_RATE_ALERT",
            actions: [viewDetailsAction, createReflectionAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([heartRateAlertCategory])
    }
}

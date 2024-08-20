//
//  WatchOSApp.swift
//  WatchOSApp
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI
import SwiftData

@main
struct WatchOSApp: App {
    @WKApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, WKApplicationDelegate {
    func applicationDidFinishLaunching() {
        NotificationService.shared.setDelegate()
    }
}

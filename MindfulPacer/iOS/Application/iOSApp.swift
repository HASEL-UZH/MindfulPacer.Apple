//
//  iOSApp.swift
//

import SwiftUI
import BackgroundTasks

@main
struct IOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color("BrandPrimary"))
        }
        // iOS 17+ SwiftUI-managed registration (no classic register anywhere)
        .backgroundTask(.appRefresh(HelloBGService.identifier)) {
            await HelloBGService.shared.handleTask()
        }
    }
}

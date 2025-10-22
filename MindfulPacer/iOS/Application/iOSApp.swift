//
//  iOSApp.swift
//

import SwiftUI

@main
struct IOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color("BrandPrimary"))
        }
        .backgroundTask(.appRefresh(MissedReflectionsMonitorService.identifier)) {
            await MissedReflectionsMonitorService.shared.handleTask()
        }
    }
}

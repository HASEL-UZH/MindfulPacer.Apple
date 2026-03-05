//
//  iOSApp.swift
//

import SwiftUI
import SwiftData

@main
struct IOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color("BrandPrimary"))
        }
        .modelContainer(ModelContainer.prod)
        .backgroundTask(.appRefresh(MissedReflectionsMonitorService.identifier)) {
            await MissedReflectionsMonitorService.shared.handleTask()
        }
    }
}

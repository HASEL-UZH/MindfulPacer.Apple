//
//  iOSApp.swift
//

import SwiftUI
import SwiftData

@main
struct IOSApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
#if DEBUG && targetEnvironment(simulator)
        RedesignCaptureSupport.configure()
#endif
    }

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

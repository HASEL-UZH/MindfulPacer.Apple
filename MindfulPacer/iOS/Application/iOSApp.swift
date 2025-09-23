//
//  iOSApp.swift
//  iOSApp
//
//  Created by Grigor Dochev on 27.06.2024.
//

import SwiftUI
import SwiftData

@main
struct IOSApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "BrandPrimary")
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .brandPrimary
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color("BrandPrimary"))
        }
        .modelContainer(.prod)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                MissedReflectionsMonitorService.shared.scheduleAppRefresh()
            }
        }
    }
}

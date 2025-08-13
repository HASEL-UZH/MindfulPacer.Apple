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
    }
}

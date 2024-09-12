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
    init() {
        // FIXME: This is a temporary workaround due to the bug that causes alert items to not have the tint color provided upstream
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(named: "BrandPrimary")
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color("BrandPrimary"))
                .addKeyboardVisibilityToEnvironment()
        }
        .modelContainer(.prod)
    }
}

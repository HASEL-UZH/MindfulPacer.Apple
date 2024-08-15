//
//  iOSApp.swift
//  iOSApp
//
//  Created by Grigor Dochev on 27.06.2024.
//

import SwiftUI
import SwiftData

@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .tint(Color("PrimaryGreen"))
                .addKeyboardVisibilityToEnvironment()
        }
        .modelContainer(.prod)
    }
}

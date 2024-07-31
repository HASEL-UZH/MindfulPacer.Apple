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
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: HeartRateSample.self)
        } catch {
            fatalError("Failed to create ModelContainer for HeartRateSample.")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(DataProviderService.shared.sharedModelContainer)
    }
}

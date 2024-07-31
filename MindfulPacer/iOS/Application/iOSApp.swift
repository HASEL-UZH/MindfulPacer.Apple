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
//            MainView()
//                .tint(Color("PrimaryGreen"))
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                
                DragAndDropTest()
                    .tabItem {
                        Label("Test", systemImage: "rectangle.grid.2x2")
                    }
            }
            .tint(Color("PrimaryGreen"))
        }
        .modelContainer(DataProviderService.shared.sharedModelContainer)
    }
}


struct MainView: View {
    var body: some View {
        Text("OK")
            .sheet(isPresented: .constant(true)) {
                OnboardingView()
                    .presentationDragIndicator(.visible)
            }
    }
}

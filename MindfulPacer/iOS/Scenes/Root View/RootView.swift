//
//  RootView.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            EmptyView()
                .tabItem { Label("Home", systemImage: "house.fill") }
        }
    }
}

#Preview {
    RootView()
}

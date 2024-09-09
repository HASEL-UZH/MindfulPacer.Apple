//
//  RootView.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI

// MARK: - RootView

struct RootView: View {
    // MARK: Properties
    
    @State var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    
    // MARK: Body
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
        }
        .onViewFirstAppear {
            viewModel.onViewFirstAppear()
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
}

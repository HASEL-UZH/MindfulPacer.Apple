//
//  RootView.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI

// MARK: - Presentation Enums

enum RootSheet: Identifiable {
    case onboardingView
    
    var id: Int {
        hashValue
    }
}

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
        .sheet(item: $viewModel.activeSheet) { sheet in
            sheetContent(for: sheet)
        }
        .onViewFirstAppear {
            viewModel.onViewFirstAppear()
        }
    }
    
    
    // MARK: Sheets
    
    @ViewBuilder
    private func sheetContent(for sheet: RootSheet) -> some View {
        switch sheet {
        case .onboardingView:
            OnboardingView()
                .presentationCornerRadius(16)
                .presentationDragIndicator(.hidden) // TODO: Remove this and disable interactive dismissal for prod
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
}

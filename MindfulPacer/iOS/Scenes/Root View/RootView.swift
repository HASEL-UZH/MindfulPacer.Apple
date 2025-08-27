//
//  RootView.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI

// MARK: - Tab

enum Tab: String {
    case home
    case analytics
    case outreach
    case settings
}

// MARK: - Presentation Enums

enum RootSheet: Identifiable {
    case onboardingView
    case whatsNewView
    
    var id: Int {
        hashValue
    }
}

// MARK: - RootView

struct RootView: View {
    
    // MARK: Properties
    
    @AppStorage(Theme.appStorageKey) private var theme: Theme = .system
    @State var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    
    // MARK: Body
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            // TODO: Change to new `Tab` init
            HomeView {
                viewModel.onWidgetTapped()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            
            .tag(Tab.home)
            
            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar")
                }
                .tag(Tab.analytics)
            
            OutreachView()
                .tabItem {
                    Label("Outreach", systemImage: "person.2.wave.2.fill")
                }
                .tag(Tab.outreach)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(Tab.settings)
        }
        .preferredColorScheme(theme.colorScheme)
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
                .interactiveDismissDisabled()
        case .whatsNewView:
            WhatsNewView(viewModel: viewModel) {
                viewModel.markWhatsNewSeen()
                viewModel.activeSheet = nil
            }
            .presentationCornerRadius(16)
            .interactiveDismissDisabled()
        }
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .tint(Color("BrandPrimary"))
}

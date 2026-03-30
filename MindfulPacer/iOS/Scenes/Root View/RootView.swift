//
//  RootView.swift
//  MindfulPacer
//

import SwiftUI
import Foundation
import BackgroundTasks
import UserNotifications

// MARK: - Tab

enum Tab: String { case home, analytics, outreach, settings, debug }

// MARK: - Presentation Enums

enum RootSheet: Identifiable {
    case onboardingView, releaseNotesView
    var id: Int { hashValue }
}

// MARK: - RootView

struct RootView: View {
    @AppStorage(Theme.appStorageKey) private var theme: Theme = .system
    @State var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            HomeView { viewModel.onWidgetTapped() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

            AnalyticsView()
                .tabItem { Label("Analytics", systemImage: "chart.bar") }
                .tag(Tab.analytics)

            OutreachView()
                .tabItem { Label("Outreach", systemImage: "person.2.wave.2.fill") }
                .tag(Tab.outreach)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
        .preferredColorScheme(theme.colorScheme)
        .sheet(item: $viewModel.activeSheet, content: sheetContent)
        .onViewFirstAppear {
            viewModel.onViewFirstAppear()
        }
    }

    @ViewBuilder
    private func sheetContent(for sheet: RootSheet) -> some View {
        switch sheet {
        case .onboardingView:
            OnboardingView()
                .presentationCornerRadius(16)
                .interactiveDismissDisabled()
        case .releaseNotesView:
            ReleaseNotesView()
                .presentationCornerRadius(16)
                .interactiveDismissDisabled()
        }
    }
}

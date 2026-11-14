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
    @State private var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            SwiftUI.Tab("Home", systemImage: "house", value: Tab.home) {
                HomeView { viewModel.onWidgetTapped() }
            }
            SwiftUI.Tab("Analytics", systemImage: "chart.xyaxis.line", value: Tab.analytics) {
                AnalyticsView()
            }
            SwiftUI.Tab("Outreach", systemImage: "person.2.wave.2.fill", value: Tab.outreach) {
                OutreachView()
            }
            SwiftUI.Tab("Settings", systemImage: "gearshape", value: Tab.settings) {
                SettingsView()
            }
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
                .interactiveDismissDisabled()
        case .releaseNotesView:
            ReleaseNotesView()
                .interactiveDismissDisabled()
        }
    }
}

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
    case onboardingView, whatsNewView
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
        case .whatsNewView:
            WhatsNewView()
                .presentationCornerRadius(16)
                .interactiveDismissDisabled()
        }
    }
}

//struct RootView: View {
//    var body: some View {
//        TabView {
//            Text("Home").tabItem { Label("Home", systemImage: "house") }
//            Text("Settings").tabItem { Label("Settings", systemImage: "gearshape") }
//            DebugVerificationView().tabItem { Label("Debug", systemImage: "ant.fill") }
//        }
//    }
//}
//
//struct DebugVerificationView: View {
//    @State private var notifStatus: String = "(unknown)"
//
//    var body: some View {
//        ScrollView {
//            VStack(alignment: .leading, spacing: 12) {
//                Text("🧪 HelloBG Verification").font(.headline)
//
//                Button("1️⃣ Dump Info.plist & Schedule Hello (~1m)") {
//                    verifySetup()
//                }.buttonStyle(.borderedProminent)
//
//                Button("2️⃣ Foreground Test Notification (2s)") {
//                    sendTestNotification()
//                }.buttonStyle(.bordered)
//
//                Button("3️⃣ Dump Pending BG Tasks") {
//                    dumpPendingTasks()
//                }.buttonStyle(.bordered)
//
//                Button("4️⃣ Schedule Hello in 10s") {
//                    Task { await HelloBGService.shared.schedule(in: 10) }
//                }.buttonStyle(.bordered)
//
//                Text("Notification settings: \(notifStatus)")
//                    .font(.footnote).foregroundStyle(.secondary).padding(.top, 6)
//            }
//            .padding()
//            .onAppear { dumpNotifSettings() }
//        }
//    }
//
//    private func verifySetup() {
//        let info = Bundle.main.infoDictionary ?? [:]
//        let ids = info["BGTaskSchedulerPermittedIdentifiers"] as? [String] ?? []
//        let modes = info["UIBackgroundModes"] as? [String] ?? []
//        let notif = info["NSUserNotificationUsageDescription"] as? String ?? "(missing)"
//
//        print("📜 Info.plist (runtime):")
//        print("   BGTaskSchedulerPermittedIdentifiers =", ids)
//        print("   UIBackgroundModes =", modes)
//        print("   NSUserNotificationUsageDescription =", notif)
//
//        Task { await HelloBGService.shared.schedule(in: 60) }
//    }
//
//    private func sendTestNotification() {
//        let content = UNMutableNotificationContent()
//        content.title = "🔔 Foreground Test Notification"
//        content.body  = "If you see this banner, notifications are configured."
//        content.sound = .default
//
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
//        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//        UNUserNotificationCenter.current().add(request) { error in
//            if let error { print("❌ Failed to schedule test notification:", error.localizedDescription) }
//            else { print("✅ Test notification scheduled for 2s") }
//        }
//    }
//
//    private func dumpPendingTasks() {
//        if #available(iOS 17.0, *) {
//            BGTaskScheduler.shared.getPendingTaskRequests { requests in
//                let list = requests.map { req -> String in
//                    if let r = req as? BGAppRefreshTaskRequest {
//                        return "\(r.identifier) @ \(String(describing: r.earliestBeginDate))"
//                    } else { return req.identifier }
//                }.joined(separator: ", ")
//                print("🧾 Pending BG tasks: [\(list)]")
//            }
//        } else {
//            print("ℹ️ getPendingTaskRequests not available on this iOS.")
//        }
//    }
//
//    private func dumpNotifSettings() {
//        UNUserNotificationCenter.current().getNotificationSettings { s in
//            let summary = "auth=\(s.authorizationStatus.rawValue) " +
//                          "alert=\(s.alertSetting.rawValue) " +
//                          "sound=\(s.soundSetting.rawValue)"
//            DispatchQueue.main.async { self.notifStatus = summary }
//        }
//    }
//}

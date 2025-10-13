//
//  HomeView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import SwiftUI
import SwiftData

private struct DismissSheetActionKey: EnvironmentKey {
    static let defaultValue: @Sendable () -> Void = {}
}

extension EnvironmentValues {
    var dismissSheet: @Sendable () -> Void {
        get { self[DismissSheetActionKey.self] }
        set { self[DismissSheetActionKey.self] = newValue }
    }
}

enum HomePage {
    case main, heartRateChart, stepsChart, logs
}

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            mainStatusPage.tag(HomePage.main)
            HeartRateChartView(viewModel: viewModel).tag(HomePage.heartRateChart)
            StepsChartView(viewModel: viewModel).tag(HomePage.stepsChart)
            LogsView().tag(HomePage.logs)
        }
        .tabViewStyle(.carousel)
        .onAppear {
            LOGI("UI", "HomeView appeared. Setting isAppInForeground = true.")
            _ = LogPipe.shared   // ensure WC session is up
            Services.shared.monitorService.isAppInForeground = true
            viewModel.onAppear()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                LOGI("UI", "Scene became ACTIVE. Set isAppInForeground = true.")
                Services.shared.monitorService.isAppInForeground = true
            } else {
                LOGI("UI", "Scene became INACTIVE/BACKGROUND. Set isAppInForeground = false.")
                Services.shared.monitorService.isAppInForeground = false
            }
        }
        .sheet(item: $navigationManager.pendingActivitySelection) { selectionInfo in
            SelectActivityView(
                reminderID: selectionInfo.reminderID,
                alertID: selectionInfo.id,
                activities: viewModel.defaultActivities
            )
            .environment(\.dismissSheet) {
                Task { @MainActor in
                    navigationManager.pendingActivitySelection = nil
                }
            }
        }
        .overlay {
            if case .showing(let rule, let alertID) = viewModel.alertState {
                notificationOverlay(for: rule, with: alertID)
            }
        }
    }

    private func notificationOverlay(for rule: AlertRule, with alertID: UUID) -> some View {
        ZStack {
            Rectangle().foregroundStyle(.ultraThickMaterial).ignoresSafeArea()
            rule.reminderType.color.opacity(0.7).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Label {
                            Text("\(rule.reminderType.rawValue) Reminder").font(.headline.weight(.bold))
                        } icon: {
                            Image(systemName: "circle.fill").foregroundStyle(rule.reminderType.color)
                        }
                        .foregroundColor(.white)

                        Text(rule.alertMessage)
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .layoutPriority(1)
                    }

                    VStack {
                        Button { viewModel.handleStrongAlertAction(shouldAddDetails: true, alertID: alertID) } label: {
                            Text("Accept & Add Details").fontWeight(.semibold)
                        }
                        Button { viewModel.handleStrongAlertAction(shouldAddDetails: false, alertID: alertID) } label: {
                            Text("Accept & Add Details Later")
                        }
                        Button { viewModel.dismissAlertOverlay() } label: {
                            Text("Delete")
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(rule.reminderType.color)
                    .foregroundColor(.white)

                    Spacer()
                }
                .padding()
            }
        }
        .transition(.opacity.animation(.easeInOut))
    }

    private var mainStatusPage: some View {
        VStack(alignment: .leading) {
            HStack {
                Button { viewModel.selectedTab = .heartRateChart } label: { currentHeartRateWidget }.buttonStyle(.plain)
                Button { viewModel.selectedTab = .stepsChart }     label: { currentStepsWidget    }.buttonStyle(.plain)
            }

            VStack {
                HStack {
                    Button {
                        viewModel.togglePauseResume()
                    } label: {
                        Icon(name: viewModel.isManuallyPaused ? "play" : "pause",
                             color: viewModel.isManuallyPaused ? .green : .yellow,
                             background: true)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!viewModel.isMonitoring)

                    Spacer(); Divider(); Spacer()

                    Button { viewModel.showBatteryInfo.toggle() } label: {
                        Icon(name: viewModel.batteryImageName, color: viewModel.batteryTintColor, background: true)
                    }
                    .buttonStyle(.borderless)
                    .alert("Battery Info", isPresented: $viewModel.showBatteryInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("""
                        Percentage: \(Int(viewModel.batteryLevel * 100))%
                        ⚠️ Note: Using the app in foreground mode significantly decreases battery life.
                        """)
                    }

                    Spacer(); Divider(); Spacer()

                    if viewModel.missedReflectionsCount == 0 {
                        Button { viewModel.showAppInfo.toggle() } label: {
                            Icon(image: "MindfulPacer Icon", background: true)
                        }
                        .buttonStyle(.borderless)
                        .alert("App Info", isPresented: $viewModel.showAppInfo) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("""
                            App Version: \(AppInfoService.appVersion)
                            Build Number: \(AppInfoService.buildNumber)
                            """)
                        }
                    } else {
                        Button { viewModel.showMissedReflectionsInfo.toggle() } label: {
                            Icon(name: "\(viewModel.missedReflectionsCount).circle.fill", color: .red, background: true)
                        }
                        .buttonStyle(.borderless)
                        .alert("Missed Reflections", isPresented: $viewModel.showMissedReflectionsInfo) {
                            Button("OK", role: .cancel) {}
                        } message: {
                            Text("You have missed reflection(s). Open the MindfulPacer app on your iPhone to view more details.")
                        }
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16).foregroundStyle(.primary.opacity(0.1))
                }

                Button { viewModel.showStatusInfo.toggle() } label: {
                    Label(viewModel.statusMessage.rawValue, systemImage: viewModel.statusMessage.symbolName)
                        .foregroundStyle(viewModel.statusMessage.color)
                        .font(.footnote)
                }
                .alert("Status Info", isPresented: $viewModel.showStatusInfo) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("""
                    \(viewModel.statusMessage.rawValue)
                    \(viewModel.statusMessage.description)
                    """)
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    private var currentHeartRateWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Icon(name: "heart.fill", color: .pink, background: true)
            VStack(alignment: .leading) {
                if viewModel.isMonitoring {
                    Text(viewModel.isMonitoring ? "\(Int(viewModel.heartRate))" : "--")
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(Color.primary)
                } else {
                    Text("--").font(.system(.title3, weight: .bold))
                }
                Text("bpm").font(.system(.footnote)).foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background { RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.1)) }
        .animation(.easeInOut(duration: 0.3), value: viewModel.alertState)
    }

    private var currentStepsWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            Icon(name: "figure.walk", color: .teal, background: true)
            VStack(alignment: .leading) {
                Text(viewModel.todaysSteps, format: .number)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(Color.primary)
                Text("steps").font(.system(.footnote)).foregroundStyle(Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background { RoundedRectangle(cornerRadius: 16).fill(Color.primary.opacity(0.1)) }
        .animation(.easeInOut(duration: 0.3), value: viewModel.alertState)
    }
}

struct LogsView: View {
    @ObservedObject private var log = AppLog.shared
    @State private var filter = ""
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Logs").font(.headline)
                Spacer()
                Button("Clear") { log.clear() }
                    .buttonStyle(.bordered)
                    .tint(.red)
            }
            TextField("Filter…", text: $filter)
            ScrollViewReader { proxy in
                List(filteredEntries) { e in
                    Text(e.line)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .id(e.id)
                }
                .listStyle(.plain)
                .onChange(of: log.entries.count) { _, _ in
                    if let last = filteredEntries.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
        .padding(.horizontal, 8)
    }
    private var filteredEntries: [LogEntry] {
        guard !filter.isEmpty else { return log.entries }
        return log.entries.filter { $0.line.localizedCaseInsensitiveContains(filter) }
    }
}

#Preview {
    HomeView(viewModel: .mock)
        .environmentObject(Services.shared.navigationManager)
}

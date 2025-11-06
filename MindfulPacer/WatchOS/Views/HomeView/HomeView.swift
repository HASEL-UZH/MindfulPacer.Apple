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

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            mainStatusPage.tag(HomePage.main)
            HeartRateChartView(viewModel: viewModel).tag(HomePage.heartRateChart)
            StepsChartView(viewModel: viewModel).tag(HomePage.stepsChart)
        }
        .tabViewStyle(.carousel)
        .onAppear {
            viewModel.onAppear()
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
                            Text(rule.measurementType.localized + " " + rule.alertMessage.lowercased())
                                .multilineTextAlignment(.center)
                                .font(.footnote.weight(.bold))
                                .layoutPriority(1)
                        } icon: {
                            Image(systemName: rule.measurementType.icon)
                                .foregroundStyle(rule.measurementType.color)
                        }
                        .foregroundColor(.white)
                        
                        Text("(\(rule.reminderType.rawValue) Reminder)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        Button {
                            viewModel.handleStrongAlertAction(shouldAddDetails: true, alertID: alertID)
                        } label: {
                            Text("Accept & Add Details")
                                .fontWeight(.semibold)
                        }
                        
                        Button {
                            viewModel.handleStrongAlertAction(shouldAddDetails: false, alertID: alertID)
                        } label: {
                            Text("Accept & Add Details Later")
                        }
                        
                        Button {
                            viewModel.dismissAlertOverlay()
                        } label: {
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
                Button {
                    viewModel.selectedTab = .heartRateChart
                } label: {
                    currentHeartRateWidget
                }
                .buttonStyle(.plain)
                
                Button {
                    viewModel.selectedTab = .stepsChart
                } label: {
                    currentStepsWidget
                }
                .buttonStyle(.plain)
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
                    
                    Button {
                        viewModel.showBatteryInfo.toggle()
                    } label: {
                        BatteryBarView(level: Double(viewModel.batteryLevel))
                    }
                    .buttonStyle(.borderless)
                    .alert("Battery Info", isPresented: $viewModel.showBatteryInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("""
                        Percentage: \(viewModel.batteryLevel >= 0 ? "\(Int(viewModel.batteryLevel * 100))%" : "Unknown")
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

struct BatteryBarView: View {
    let level: Double
    private let minFill: CGFloat = 0.02

    private var clampedLevel: Double {
        guard level >= 0 else { return -1 }
        return min(max(level, 0), 1)
    }

    private var tint: Color {
        guard clampedLevel >= 0 else { return .secondary }
        switch clampedLevel {
        case ..<0.2: return .red
        case ..<0.5: return .yellow
        default: return .green
        }
    }

    /// Visible bar proportions (kept smaller to avoid looking oversized inside the square)
    private var barWidthRatio: CGFloat { 0.72 }
    private var barHeightRatio: CGFloat { 0.35 }
    private var capWidthRatio: CGFloat { 0.06 }

    private var displayText: String {
        clampedLevel < 0 ? "--%" : "\(Int(clampedLevel * 100))%"
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                let container = min(geo.size.width, geo.size.height)
                let barW = container * barWidthRatio
                let barH = container * barHeightRatio
                let capW = container * capWidthRatio
                let cornerR = barH * 0.4

                RoundedRectangle(cornerRadius: cornerR, style: .continuous)
                    .fill(.primary.opacity(0.12))
                    .frame(width: barW, height: barH)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                if clampedLevel >= 0 {
                    let inset: CGFloat = barH * 0.15
                    let fillAvailable = barW - inset * 2
                    let fillW = max(fillAvailable * CGFloat(max(minFill, clampedLevel)), cornerR)

                    RoundedRectangle(cornerRadius: cornerR * 0.75, style: .continuous)
                        .fill(tint)
                        .frame(width: fillW, height: barH - inset * 2)
                        .position(
                            x: geo.size.width / 2 - (barW - fillW) / 2 + inset,
                            y: geo.size.height / 2
                        )
                        .animation(.easeInOut(duration: 0.3), value: clampedLevel)
                }

                RoundedRectangle(cornerRadius: cornerR * 0.4, style: .continuous)
                    .fill(.primary.opacity(0.25))
                    .frame(width: capW, height: barH * 0.6)
                    .position(
                        x: geo.size.width / 2 + barW / 2 + capW / 2 - 1,
                        y: geo.size.height / 2
                    )
            }
        }
        .frame(width: 24, height: 24)
        .padding(4)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .foregroundStyle(tint.opacity(0.1))
                RoundedRectangle(cornerRadius: 8)
                    .stroke(tint.opacity(0.1), lineWidth: 1.5)
            }
        }
    }
}

#Preview {
    HomeView(viewModel: .mock)
        .environmentObject(Services.shared.navigationManager)
}

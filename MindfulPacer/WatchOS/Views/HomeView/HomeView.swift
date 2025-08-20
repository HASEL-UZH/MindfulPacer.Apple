//
//  HomeView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import SwiftUI
import SwiftData

struct AnimatedNumberModifier: @MainActor AnimatableModifier {
    var value: Double
    var font: Font
    
    var animatableData: Double {
        get { value }
        set { value = newValue }
    }
    
    func body(content: Content) -> some View {
        Text("\(Int(value))")
            .font(font)
    }
}

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
    case main, heartRateChart, stepsChart
}

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    @EnvironmentObject private var navigationManager: NavigationManager
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            mainStatusPage
                .tag(HomePage.main)
            
            HeartRateChartView(viewModel: viewModel)
                .tag(HomePage.heartRateChart)
            
            StepsChartView(viewModel: viewModel)
                .tag(HomePage.stepsChart)
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
            if case .strong(let rule, let alertID) = viewModel.alertState {
                strongReminderOverlay(for: rule, with: alertID)
            }
        }
    }
    
    private func strongReminderOverlay(for rule: AlertRule, with alertID: UUID) -> some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.ultraThinMaterial)
                .ignoresSafeArea()
            
            Color.red.opacity(0.7)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Label {
                            Text("Strong Reminder")
                                .font(.headline.weight(.bold))
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.red)
                        }
                        .foregroundColor(.white)
                        
                        Text(rule.alertMessage)
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .layoutPriority(1)
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
                            viewModel.rejectStrongAlert()
                        } label: {
                            Text("Reject")
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .transition(.opacity.animation(.easeInOut))
    }
    
    private var mainStatusPage: some View {
        ZStack {
            if case .solid(let color) = viewModel.alertState {
                color.opacity(0.3).ignoresSafeArea()
                    .animation(.easeInOut, value: viewModel.alertState)
            }
            
            VStack {
                Button {
                    
                } label: {
                    
                }
                .buttonStyle(.borderless)
            }
                
            
            VStack(alignment: .leading) {
                VStack {
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
                
                HStack {
                    Button {
                        viewModel.showStatusInfo.toggle()
                    } label: {
                        Icon(
                            name: viewModel.statusMessage.symbolName,
                            color: viewModel.statusMessage.color,
                            background: true
                        )
                    }
                    .buttonStyle(.borderless)
                    .alert("Status Info", isPresented: $viewModel.showStatusInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(
                            """
                            \(viewModel.statusMessage.rawValue)
                            \(viewModel.statusMessage.description)
                            """
                        )
                    }
                    
                    Spacer()
                    Divider()
                    Spacer()
                    
                    Button {
                        viewModel.showBatteryInfo.toggle()
                    } label: {
                        Icon(
                            name: viewModel.batteryImageName,
                            color: viewModel.batteryTintColor,
                            background: true
                        )
                    }
                    .buttonStyle(.borderless)
                    .alert("Battery Info", isPresented: $viewModel.showBatteryInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(
                            """
                            Percentage: \(Int(viewModel.batteryLevel * 100))%
                            ⚠️ Note: Using the app in foreground mode significantly decreases battery life.
                            """
                        )
                    }
                    
                    Spacer()
                    Divider()
                    Spacer()
                    
                    Button {
                        viewModel.showAppInfo.toggle()
                    } label: {
                        Icon(image: "MindfulPacer Icon", background: true)
                    }
                    .buttonStyle(.borderless)
                    .alert("App Info", isPresented: $viewModel.showAppInfo) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text(
                            """
                            App Version: \(AppInfoService.appVersion)
                            Build Number: \(AppInfoService.buildNumber)
                            """
                        )
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .foregroundStyle(.primary.opacity(0.1))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var currentHeartRateWidget: some View {
        let isFlashing: Bool
        if case .flashing(_, let type) = viewModel.alertState, type == .heartRate {
            isFlashing = true
        } else {
            isFlashing = false
        }
        
        return HStack(alignment: .top, spacing: 8) {
            Icon(
                name: "heart.fill",
                color: isFlashing ? Color.yellow : Color.pink,
                background: true
            )
            
            VStack(alignment: .leading) {
                if viewModel.isMonitoring {
                    Text(viewModel.isMonitoring ? "\(Int(viewModel.heartRate))" : "--")
                        .font(.system(.title2, weight: .bold))
                        .scaleEffect(isFlashing ? 1.2 : 1.0)
                        .foregroundStyle(isFlashing ? Color.yellow : Color.primary)
                } else {
                    Text("--").font(.system(.title2, weight: .bold))
                }
                
                Text("bpm")
                    .font(.system(.footnote))
                    .foregroundStyle(isFlashing ? Color.yellow.opacity(0.7) : Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(isFlashing ? Color.yellow.opacity(0.1) : Color.primary.opacity(0.1))
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.alertState)
    }
    
    private var currentStepsWidget: some View {
        let isFlashing: Bool
        if case .flashing(_, let type) = viewModel.alertState, type == .steps {
            isFlashing = true
        } else {
            isFlashing = false
        }
        
        return HStack(alignment: .top, spacing: 8) {
            Icon(
                name: "figure.walk",
                color: isFlashing ? Color.yellow : Color.teal,
                background: true
            )

            VStack(alignment: .leading) {
                Text(viewModel.todaysSteps, format: .number)
                    .font(.system(.title2, weight: .bold))
                    .scaleEffect(isFlashing ? 1.2 : 1.0)
                    .foregroundStyle(isFlashing ? Color.yellow : Color.primary)
                
                Text("steps")
                    .font(.system(.footnote))
                    .foregroundStyle(isFlashing ? Color.yellow.opacity(0.7) : Color.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(isFlashing ? Color.yellow.opacity(0.1) : Color.primary.opacity(0.1))
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.alertState)
    }
}

extension HomeViewModel {
    var strongAlertInfo: (rule: AlertRule, alertID: UUID)? {
        if case .strong(let rule, let alertID) = alertState {
            return (rule, alertID)
        }
        return nil
    }
}

#Preview {
    HomeView(viewModel: .mock)
        .environmentObject(Services.shared.navigationManager)
}

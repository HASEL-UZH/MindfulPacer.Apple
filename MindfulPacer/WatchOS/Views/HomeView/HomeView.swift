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
            print("DEBUGY VIEW: HomeView appeared. Current reminderID for sheet is \(String(describing: navigationManager.reminderIDForActivitySelection))")
            viewModel.onAppear()
            
            if navigationManager.reminderIDForActivitySelection != nil {}
        }
        .sheet(item: $navigationManager.reminderIDForActivitySelection) { reminderID in
            SelectActivityView(reminderID: reminderID)
        }
    }
    
    private var mainStatusPage: some View {
        ZStack {
            Circle()
                .fill(viewModel.alertColor.opacity(viewModel.isAlerting ? 0.3 : 0.0))
                .scaleEffect(viewModel.isAlerting ? 3.0 : 0.5)
                .animation(.easeInOut(duration: 0.5), value: viewModel.isAlerting)
            
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
                        Icon(name: viewModel.statusMessage.symbolName, color: viewModel.statusMessage.color, background: true)
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
        HStack(alignment: .top, spacing: 8) {
            Icon(name: "heart.fill", color: .pink, background: true)

            VStack(alignment: .leading) {
                if viewModel.isMonitoring {
                    Text("")
                        .modifier(
                            AnimatedNumberModifier(
                                value: viewModel.heartRate,
                                font: .system(.title2, weight: .bold)
                            )
                        )
                        .scaleEffect(viewModel.isAlerting ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.4), value: viewModel.heartRate)
                } else {
                    Text("--")
                        .font(.system(.title2, weight: .bold))
                }

                Text("bpm")
                    .font(.system(.footnote))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundColor(viewModel.isAlerting ? viewModel.alertColor : .primary)
        .animation(.easeInOut, value: viewModel.isAlerting)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(.primary.opacity(0.1))
        }
    }
    
    private var currentStepsWidget: some View {
        HStack(alignment: .top, spacing: 8) {
            Icon(name: "figure.walk", color: .teal, background: true)

            VStack(alignment: .leading) {
                Text(viewModel.todaysSteps, format: .number)
                    .font(.system(.title2, weight: .bold))
                
                Text("steps")
                    .font(.system(.footnote))
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundColor(viewModel.isAlerting ? viewModel.alertColor : .primary)
        .animation(.easeInOut, value: viewModel.isAlerting)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(.primary.opacity(0.1))
        }
    }
}

#Preview {
    HomeView(viewModel: .mock)
        .environmentObject(NavigationManager.shared)
}

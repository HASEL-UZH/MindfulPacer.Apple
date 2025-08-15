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
    @StateObject private var navigationManager = NavigationManager.shared
    @State private var showActiveAlertsView: Bool = false
    
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
        .sheet(item: $navigationManager.selectedAlertID) { alertID in
            HeartRateDetailView(alertID: alertID)
        }
        .sheet(isPresented: $showActiveAlertsView) {
            ActiveAlertsView(viewModel: viewModel)
        }
    }
    
    private var mainStatusPage: some View {
        ZStack {
            Circle()
                .fill(viewModel.alertColor.opacity(viewModel.isAlerting ? 0.3 : 0.0))
                .scaleEffect(viewModel.isAlerting ? 3.0 : 0.5)
                .animation(.easeInOut(duration: 0.5), value: viewModel.isAlerting)
            
            VStack(alignment: .leading) {
                HStack {
                    VStack {
                        Image(.mindfulPacerIcon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                    BatteryView()
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .foregroundStyle(.primary.opacity(0.1))
                        }
                }
                .frame(maxHeight: .infinity)
                
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
                
                statusWidget
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var statusWidget: some View {
        if viewModel.statusMessage == .monitoring {
            Button {
                showActiveAlertsView = true
            } label: {
                Label(viewModel.statusMessage.rawValue, systemImage:  viewModel.statusMessage.symbolName)
                    .font(.footnote)
                    .foregroundStyle(viewModel.statusMessage.color)
                    .symbolVariant(.fill)
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            Label(viewModel.statusMessage.rawValue, systemImage:  viewModel.statusMessage.symbolName)
                .font(.footnote)
                .foregroundStyle(viewModel.statusMessage.color)
                .symbolVariant(.fill)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    private var currentHeartRateWidget: some View {
        VStack(alignment: .leading, spacing: 16) {
            Icon(name: "heart.fill", color: .pink, background: true)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.isMonitoring ? "\(Int(viewModel.heartRate))" : "--")
                    .font(.system(.title3, weight: .bold))
                    .scaleEffect(viewModel.isAlerting ? 1.2 : 1.0)
                
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
        VStack(alignment: .leading, spacing: 16) {
            Icon(name: "figure.walk", color: .teal, background: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.todaysSteps, format: .number)
                    .font(.system(.title3, weight: .bold))
                
                Text("steps")
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
}

#Preview {
    HomeView(viewModel: .mock)
}

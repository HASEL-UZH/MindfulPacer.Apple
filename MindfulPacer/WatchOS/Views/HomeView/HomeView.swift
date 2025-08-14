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

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel = HomeViewModel()
    @StateObject private var navigationManager = NavigationManager.shared
    
    @State private var animatedHeartRate: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(viewModel.alertColor.opacity(viewModel.isAlerting ? 0.3 : 0.0))
                .scaleEffect(viewModel.isAlerting ? 3.0 : 0.5)
                .animation(.easeInOut(duration: 0.5), value: viewModel.isAlerting)
            
            VStack(alignment: .leading, spacing: 16) {
                Image(.mindfulPacerIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                                
                HStack {
                    heartRate
                    steps
                }
                                
                status
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .sheet(item: $navigationManager.selectedAlertID) { alertID in
            HeartRateDetailView(alertID: alertID)
        }
        .sheet(isPresented: $viewModel.isShowingActiveRules) {
            ActiveRemindersView()
        }
    }
    
    // MARK: Status
    
    @ViewBuilder
    private var status: some View {
        if viewModel.statusMessage == .monitoring {
            Button {
                viewModel.isShowingActiveRules = true
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
    
    // MARK: Heart Rate
    
    private var heartRate: some View {
        VStack(alignment: .leading, spacing: 16) {
            Icon(name: "heart.fill", color: .pink, background: true)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.isMonitoring ? "\(Int(viewModel.heartRate))" : "--")
                    .scaleEffect(viewModel.isAlerting ? 1.2 : 1.0)
                    .modifier(
                        AnimatedNumberModifier(
                            value: animatedHeartRate,
                            font: .system(.title3, weight: .bold)
                        )
                    )
                    .scaleEffect(scale)
                    .onChange(of: viewModel.heartRate) { _, newValue in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            animatedHeartRate = newValue
                            scale = 1.3
                        }
                        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                            scale = 1.0
                        }
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
    
    // MARK: Steps
    
    private var steps: some View {
        VStack(alignment: .leading, spacing: 16) {
            Icon(name: "figure.walk", color: .teal, background: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("10,250")
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
    HomeView()
}

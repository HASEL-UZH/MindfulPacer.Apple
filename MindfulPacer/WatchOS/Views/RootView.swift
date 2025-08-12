//
//  RootView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import Foundation
import SwiftUI
import SwiftData

extension UUID: @retroactive Identifiable {
    public var id: UUID {
        self
    }
}

@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    @Published var selectedAlertID: UUID?
    
    private init() {}
}

struct RootView: View {
    @State private var viewModel = RootViewModel(fetchRemindersUseCase: DefaultFetchRemindersUseCase(modelContext: ModelContainer.prod.mainContext))
    @StateObject private var navigationManager = NavigationManager.shared
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(viewModel.isAlerting ? 0.3 : 0.0))
                .scaleEffect(viewModel.isAlerting ? 3.0 : 0.5)
                .animation(.easeInOut(duration: 0.5), value: viewModel.isAlerting)
            
            VStack(alignment: .leading, spacing: 8) {
                Label(viewModel.statusMessage.rawValue, systemImage:  viewModel.statusMessage.symbolName)
                    .foregroundStyle(viewModel.statusMessage.color)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(viewModel.isMonitoring ? "\(Int(viewModel.heartRate))" : "--")
                        .font(.largeTitle.bold())
                        .scaleEffect(viewModel.isAlerting ? 1.2 : 1.0)
                    Text("BPM")
                        .font(.subheadline)
                }
                .foregroundColor(viewModel.isAlerting ? .red : .primary)
                .animation(.easeInOut, value: viewModel.isAlerting)
                
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Text(String(viewModel.strongAlertCount))
                            .font(.subheadline.weight(.semibold))
                        Icon(name: "alarm.fill", color: .red, background: true)
                    }
                    
                    Spacer()
                    Divider()
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text(String(viewModel.mediumAlertCount))
                            .font(.subheadline.weight(.semibold))
                        Icon(name: "alarm.fill", color: .orange, background: true)
                    }
                    
                    Spacer()
                    Divider()
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Text(String(viewModel.lightAlertCount))
                            .font(.subheadline.weight(.semibold))
                        Icon(name: "alarm.fill", color: .yellow, background: true)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                
                Spacer()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
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
}

#Preview {
    RootView()
}

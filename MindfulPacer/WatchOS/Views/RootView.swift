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
        VStack {
            Image(systemName: viewModel.isMonitoring ? "heart.circle.fill" : "heart.slash.circle.fill")
                .font(.largeTitle)
                .foregroundColor(viewModel.isMonitoring ? .pink : .gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(viewModel.isMonitoring ? "\(Int(viewModel.heartRate))" : "--")
                    .font(.largeTitle.weight(.semibold))
                Text("BPM")
                    .font(.subheadline)
                    .foregroundColor(.pink)
            }
            
            Text(viewModel.statusMessage)
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if viewModel.isMonitoring {
                Button {
                    viewModel.isShowingActiveRules = true
                } label: {
                    Text("View Active Reminders")
                }
                .tint(.brandPrimary)
                .padding(.top)
            }
        }
        .padding()
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

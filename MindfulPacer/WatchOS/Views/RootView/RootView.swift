//
//  RootView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import SwiftUI

struct ActivitySelectionInfo: Identifiable {
    let id: UUID
    let reminderID: UUID
}

@MainActor
class NavigationManager: ObservableObject {
    @Published var selectedAlertID: UUID?
    @Published var pendingActivitySelection: ActivitySelectionInfo?
    init() {}
}

// This is the only extension you need here.
extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

struct RootView: View {
    @State private var viewModel = HomeViewModel()

    var body: some View {
        HomeView(viewModel: viewModel)
    }
}

#Preview {
    RootView()
}

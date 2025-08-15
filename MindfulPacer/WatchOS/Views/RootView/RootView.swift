//
//  RootView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import SwiftUI

@MainActor
class NavigationManager: ObservableObject {
    static let shared = NavigationManager()
    @Published var selectedAlertID: UUID?
    @Published var reminderIDForActivitySelection: UUID? {
        didSet {
            if let id = reminderIDForActivitySelection {
                print("DEBUGY NAV: reminderIDForActivitySelection was SET to \(id)")
            } else {
                print("DEBUGY NAV: reminderIDForActivitySelection was set to NIL")
            }
        }
    }
    private init() {}
}

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

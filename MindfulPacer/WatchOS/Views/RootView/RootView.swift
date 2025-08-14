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
    private init() {}
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

struct RootView: View {
    var body: some View {
        HomeView()
    }
}

#Preview {
    RootView()
}

#Preview {
    RootView()
}

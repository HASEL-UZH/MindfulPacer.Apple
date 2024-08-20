//
//  RootView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 16.07.2024.
//

import SwiftUI

struct RootView: View {
    @State private var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    
    var body: some View {
        Image(systemName: "heart.fill")
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
    }
}

// MARK: - Preview

#Preview {
    RootView()
}

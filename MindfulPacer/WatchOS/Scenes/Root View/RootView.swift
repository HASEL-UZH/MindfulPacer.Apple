//
//  RootView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 16.07.2024.
//

import SwiftUI

// MARK: - RootView

struct RootView: View {
    // MARK: Properties
    
    @State private var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    
    // MARK: Body
    
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

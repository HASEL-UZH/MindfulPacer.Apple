//
//  RootView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 16.07.2024.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    @Query(sort: \HeartRateSample.timestamp, order: .reverse) private var heartRateSamples: [HeartRateSample]
    
    var body: some View {
        Image(systemName: "heart.fill")
            .foregroundStyle(.pink)
            .onAppear {
                viewModel.onViewFirstAppear()
            }
    }
}

#Preview {
    RootView()
}

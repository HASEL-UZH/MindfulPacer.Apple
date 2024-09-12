//
//  AnalyticsView.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import SwiftUI

// MARK: - AnalyticsView

struct AnalyticsView: View {
    // MARK: Properties
    
    @State private var viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()

    // MARK: Body

    var body: some View {
        NavigationStack {
            ScrollView {
                
            }
            .navigationTitle("Analytics")
        }
    }
}

// MARK: - Preview

#Preview {
    AnalyticsView()
}

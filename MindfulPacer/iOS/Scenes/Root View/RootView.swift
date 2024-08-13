//
//  RootView.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 30.06.2024.
//

import SwiftUI

struct RootView: View {
    @State var viewModel: RootViewModel = ScenesContainer.shared.rootViewModel()
    
    var body: some View {
        VStack {
            List {
                
            }
            .onViewFirstAppear {
                viewModel.onViewFirstAppear()
            }
        }
    }
}

#Preview {
    RootView()
}

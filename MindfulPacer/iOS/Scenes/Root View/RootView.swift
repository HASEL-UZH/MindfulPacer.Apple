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
            Text("Hi")
        }
        .onAppear {
            let healthKitService = HealthKitService.shared
            
            healthKitService.fetchHeartRateData(for: .day) { result in
                switch result {
                case .success(let samples):
                    for sample in samples {
                        print("Heart Rate: \(sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))) BPM at \(sample.startDate)")
                    }
                case .failure(let error):
                    print("Error fetching heart rate data: \(error)")
                }
            }
        }
    }
}

#Preview {
    RootView()
}

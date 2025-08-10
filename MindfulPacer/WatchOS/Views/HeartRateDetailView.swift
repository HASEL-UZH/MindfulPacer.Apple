//
//  HeartRateDetailView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 09.08.2025.
//

import SwiftUI

struct HeartRateDetailView: View {
    let alertID: UUID
    @State private var heartRateData: [(value: Double, date: Date)] = []

    var body: some View {
        VStack {
            Text("Alert Data")
                .font(.headline)
                .padding()
            
            if heartRateData.isEmpty {
                Text("No data found for this alert.")
                    .foregroundColor(.secondary)
            } else {
                List(heartRateData, id: \.date) { dataPoint in
                    HStack {
                        Text("\(Int(dataPoint.value)) bpm")
                            .font(.title3)
                            .foregroundColor(.red)
                        Spacer()
                        Text(dataPoint.date.formatted(date: .omitted, time: .standard))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear(perform: loadData)
    }

    private func loadData() {
        self.heartRateData = HeartRateMonitorService.shared.data(for: alertID) ?? []
    }
}

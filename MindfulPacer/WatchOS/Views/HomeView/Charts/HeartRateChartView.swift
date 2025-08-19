//
//  HeartRateChartView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import SwiftUI
import Charts

struct HeartRateChartView: View {
    @Bindable var viewModel: HomeViewModel
    @State private var showInfo = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Heart Rate", systemImage: "heart.fill")
                    .foregroundColor(.pink)
                    .font(.headline)
                
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .alert("Heart Rate Info", isPresented: $showInfo) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("This chart displays heart rate data from the last hour.")
                }
            }
            
            if viewModel.isMonitoring && !viewModel.heartRateSamples.isEmpty {
                Chart {
                    ForEach(viewModel.downsampledHeartRateSamples, id: \.date) { sample in
                        LineMark(
                            x: .value("Time", sample.date),
                            y: .value("BPM", sample.value)
                        )
                        .foregroundStyle(.pink)
                    }
                    
                    ForEach(viewModel.activeRules.filter { $0.measurementType == .heartRate }) { rule in
                        if case .heartRate(let threshold) = rule.ruleType {
                            RuleMark(y: .value("Threshold", threshold))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(rule.reminderType.color)
                                .annotation(position: .top, alignment: .leading) {
                                    Text("\(Int(threshold))")
                                        .font(.caption2)
                                        .foregroundColor(rule.reminderType.color)
                                        .padding(.leading, 4)
                                }
                        }
                    }
                }
                .chartYScale(domain: viewModel.heartRateChartYDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                }
                .frame(maxHeight: .infinity)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(viewModel.avgHeartRate)")
                            .font(.title3)
                            .fontWeight(.semibold)
                        +
                        Text(" avg bpm")
                            .font(.footnote)
                            .foregroundStyle(.pink)
                        
                        Text("Range: \(viewModel.minHeartRate) - \(viewModel.maxHeartRate) bpm")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            } else {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "chart.xyaxis.line",
                    description: Text("Please check the monitoring status.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

#Preview {
    //    HeartRateChartView(viewModel: .mock)
    HeartRateChartView(viewModel: HomeViewModel())
}

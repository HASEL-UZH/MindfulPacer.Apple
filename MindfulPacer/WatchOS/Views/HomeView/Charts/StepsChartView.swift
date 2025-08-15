//
//  StepsChartView.swift
//  WatchOS
//
//  Created by Grigor Dochev on 14.08.2025.
//

import SwiftUI
import Charts

struct StepsChartView: View {
    @Bindable var viewModel: HomeViewModel
    @State private var showInfo: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Label("Steps", systemImage: "figure.walk")
                    .foregroundColor(.teal)
                    .font(.headline)
                Button {
                    showInfo.toggle()
                } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .alert("Step Count Info", isPresented: $showInfo) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("This chart displays step data from the last hour.")
                }
            }
            
            if !viewModel.hourlyStepData.isEmpty {
                Chart {
                    ForEach(viewModel.hourlyStepData, id: \.date) { dataPoint in
                        LineMark(
                            x: .value("Time", dataPoint.date),
                            y: .value("Steps", dataPoint.steps)
                        )
                        .foregroundStyle(.teal)
                    }
                    
                    
                    ForEach(viewModel.activeRules.filter { $0.measurementType == .steps }) { rule in
                        if case .steps(let threshold) = rule.ruleType {
                            RuleMark(y: .value("Threshold", threshold))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                                .foregroundStyle(rule.color)
                                .annotation(position: .top, alignment: .leading) {
                                    Text("\(Int(threshold))")
                                        .font(.caption2)
                                        .foregroundColor(rule.color)
                                        .padding(.leading, 4)
                                }
                        }
                    }
                }
                .chartYScale(domain: viewModel.stepsChartYDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.hour().minute())
                    }
                }
                
                HStack {
                    let totalSteps = viewModel.hourlyStepData.last?.steps ?? 0
                    Text("\(totalSteps.toInt())")
                        .font(.title3)
                        .fontWeight(.semibold)
                    +
                    Text(" total steps")
                        .font(.footnote)
                        .foregroundStyle(.teal)
                    
                    Spacer()
                }
            } else {
                Spacer()
                Text("Step data from the last hour will be shown here.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding()
    }
}

#Preview {
    StepsChartView(viewModel: .mock)
}

//
//  StepsChartView.swift
//  iOS
//
//  Created by Grigor Dochev on 09.02.2025.
//

import SwiftUI
import Charts

// MARK: - StepsChartView

struct StepsChartView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: AnalyticsViewModel
    
    // MARK: Body
    
    var body: some View {
        ZStack {
            if viewModel.chartData.isEmpty {
                EmptyStateView(
                    image: viewModel.chartEmptyStateImage,
                    title: viewModel.chartEmptyStateTitle,
                    description: String(localized: "Synchronize your smartwatch")
                )
            } else {
                Chart {
                    ForEach(viewModel.chartThresholds, id: \.threshold) { threshold in
                        RuleMark(y: .value("Goal", threshold.threshold))
                            .foregroundStyle(threshold.reminderType.color)
                            .lineStyle(.init(lineWidth: 1, dash: [5]))
                    }
                    
                    if viewModel.selectedPeriod == .week {
                        ForEach(viewModel.chartData) { data in
                            BarMark(
                                x: .value("Time", viewModel.midDate(for: data)),
                                y: .value("Steps", data.value)
                            )
                            .foregroundStyle(viewModel.selectedMeasurementType.color)
                            .opacity((viewModel.selectedDate == viewModel.midDate(for: data) || viewModel.selectedDate == nil) ? 1.0 : 0.3)
                        }
                    } else {
                        ForEach(viewModel.downsampledChartData) { data in
                            let midDate = viewModel.midDate(for: data)
                            
                            AreaMark(
                                x: .value("Time", midDate),
                                yStart: .value("Value", data.value),
                                yEnd: .value("Min Value", 0)
                            )
                            .foregroundStyle(Gradient(colors: [viewModel.selectedMeasurementType.color.opacity(0.5), .clear]))
                            .interpolationMethod(.catmullRom)
                            
                            LineMark(
                                x: .value("Time", midDate),
                                y: .value("Steps", data.value)
                            )
                            .foregroundStyle(viewModel.selectedMeasurementType.color)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    
                    if let selectedDate = viewModel.selectedDate {
                        RuleMark(x: .value("Time", selectedDate))
                            .foregroundStyle(viewModel.selectedMeasurementType.color.opacity(0.3))
                    }
                }
                .chartXScale(domain: viewModel.xDomain)
                .chartXSelection(value: viewModel.snappedSelectedDate)
                .chartXAxis {
                    if viewModel.selectedPeriod == .week {
                        AxisMarks(values: .automatic(desiredCount: 5)) {
                            AxisValueLabel(format: .dateTime.weekday())
                        }
                    } else {
                        AxisMarks(values: .automatic(desiredCount: 5))
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .inset) {
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        ForEach(viewModel.reflectionsInPeriod, id: \.startDate) { bucket in
                            if let point = proxy.position(for: (x: bucket.startDate, y: 0.0)) {
                                Group {
                                    if bucket.reflections.count == 1 {
                                        let reflection = bucket.reflections.first!
                                        
                                        Button {
                                            viewModel.presentSheet(.editReflectionView(reflection))
                                        } label: {
                                            if let subactivity = reflection.subactivity {
                                                Icon(name: subactivity.icon, color: .primary)
                                            } else if let activity = reflection.activity {
                                                Icon(name: activity.icon, color: .primary)
                                            }
                                        }
                                    } else {
                                        Button {
                                            viewModel.selectedReflectionBucket = bucket
                                        } label: {
                                            Text("\(bucket.reflections.count)")
                                                .font(.caption.bold())
                                                .foregroundStyle(Color.primary)
                                                .frame(width: 24, height: 24)
                                                .background {
                                                    Circle()
                                                        .foregroundStyle(Color.secondary.opacity(0.3))
                                                }
                                        }
                                    }
                                }
                                .position(x: point.x, y: geometry.size.height - 10)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    
    StepsChartView(viewModel: viewModel)
}

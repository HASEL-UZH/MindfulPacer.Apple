//
//  HeartRateChartView.swift
//  iOS
//
//  Created by Grigor Dochev on 10.02.2025.
//

import SwiftUI
import Charts

// MARK: - HeartRateChartView

struct HeartRateChartView: View {
    
    // MARK: Properties
    
    @Bindable var viewModel: AnalyticsViewModel
    
    // MARK: Body
    
    var body: some View {
        ZStack {
            if viewModel.downsampledChartData.isEmpty {
                EmptyStateView(
                    image: viewModel.chartEmptyStateImage,
                    title: viewModel.chartEmptyStateTitle,
                    description: "Synchronize your smartwatch"
                )
            } else {
                Chart {
                    ForEach(Array(viewModel.chartThresholds.enumerated()), id: \.offset) { _, threshold in
                        RuleMark(y: .value("Goal", threshold.threshold))
                            .foregroundStyle(threshold.reminderType.color)
                            .lineStyle(.init(lineWidth: 1, dash: [5]))
                    }
                    
                    ForEach(viewModel.downsampledChartData) { data in
                        AreaMark(
                            x: .value("Time", data.startDate),
                            yStart: .value("Value", data.value),
                            yEnd: .value("Min Value", viewModel.minValue)
                        )
                        .foregroundStyle(Gradient(colors: [viewModel.selectedMeasurementType.color.opacity(0.5), .clear]))
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Time", data.startDate),
                            y: .value("Value", data.value)
                        )
                        .foregroundStyle(viewModel.selectedMeasurementType.color)
                        .interpolationMethod(.catmullRom)
                    }
                    
                    if let selectedDate = viewModel.selectedDate {
                        RuleMark(x: .value("Time", selectedDate))
                            .foregroundStyle(viewModel.selectedMeasurementType.color.opacity(0.3))
                    }
                }
                .chartXScale(domain: viewModel.xDomain)
                .chartXSelection(value: viewModel.snappedSelectedDate)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
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
    
    // MARK: X-Axis Label
    
    @ViewBuilder
    func xAxisLabel(for value: AxisValue) -> some View {
        if let date = value.as(Date.self) {
            let style: Date.FormatStyle = {
                switch viewModel.granularity {
                case .day:
                    return .dateTime.weekday(.abbreviated)
                case .hour:
                    return .dateTime.hour()
                case .minute:
                    return .dateTime.hour().minute()
                }
            }()
            Text(date.formatted(style))
        } else {
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    
    HeartRateChartView(viewModel: viewModel)
}


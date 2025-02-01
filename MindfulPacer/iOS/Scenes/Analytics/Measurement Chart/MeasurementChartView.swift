//
//  MeasurementChartView.swift
//  iOS
//
//  Created by Grigor Dochev on 14.10.2024.
//

import SwiftUI
import Charts

// MARK: - ChartDataItem

struct ChartDataItem: Identifiable, Equatable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let value: Double
}

// MARK: - MeasurementChartView

extension AnalyticsView {
    struct MeasurementChartView: View {
        
        // MARK: Properties
        
        @Bindable var viewModel: AnalyticsViewModel
        var onReflectionSelected: (SchemaV1.Reflection) -> Void
        
        // MARK: Body
        
        var body: some View {
            ZStack {
                if viewModel.chartData.isEmpty {
                    EmptyStateView(
                        image: viewModel.chartEmptyStateImage,
                        title: viewModel.chartEmptyStateTitle,
                        description: "Synchronize your smartwatch"
                    )
                } else {
                    Chart {
                        if let selectedData = viewModel.selectedData {
                            annotationView(data: selectedData)
                        }
                        
                        ForEach(viewModel.chartThresholds, id: \.threshold) { chartThreshold in
                            RuleMark(y: .value("Goal", chartThreshold.threshold))
                                .foregroundStyle(chartThreshold.reminderType.color)
                                .lineStyle(.init(lineWidth: 1, dash: [5]))
                        }
                        
                        ForEach(viewModel.chartData) { dataPoint in
                            switch viewModel.selectedMeasurementType {
                            case .heartRate:
                                AreaMark(
                                    x: .value("Time", dataPoint.startDate),
                                    yStart: .value("Value", dataPoint.value),
                                    yEnd: .value("Min Value", viewModel.minValue)
                                )
                                .foregroundStyle(Gradient(colors: [viewModel.chartColor.opacity(0.5), .clear]))
                                .interpolationMethod(.catmullRom)
                                
                                LineMark(
                                    x: .value("Time", dataPoint.startDate),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(viewModel.chartColor)
                                .interpolationMethod(.catmullRom)
                                    
                            case .steps:
                                let opacityValue: Double = {
                                    if viewModel.rawSelectedDate == nil || (dataPoint.startDate == viewModel.selectedData?.startDate) {
                                        return 1.0
                                    } else {
                                        return 0.3
                                    }
                                }()
                                
                                BarMark(
                                    x: .value("Time", dataPoint.startDate),
                                    yStart: .value("Start", 0),
                                    yEnd: .value("Steps", max(0, dataPoint.value)),
                                    width: .fixed(10)
                                )
                                .foregroundStyle(viewModel.chartColor)
                                .opacity(opacityValue)
                            }
                        }
                    }
                    .chartXSelection(value: $viewModel.rawSelectedDate) // Keep drag-to-select functionality
                    .chartXScale(domain: viewModel.calculateXDomain()) // Dynamically calculated x-axis domain
                    .chartYScale(domain: 0...(viewModel.maxValue * 1.1))
                    .chartXAxis {
                        let axisDates = viewModel.generateAxisMarkDates(for: viewModel.calculateXDomain())
                        AxisMarks(values: axisDates) { date in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let dateValue = date.as(Date.self) {
                                    switch viewModel.selectedPeriod {
                                    case .oneHour, .twoHours:
                                        Text(dateValue, format: .dateTime.hour().minute())
                                    case .day:
                                        Text(dateValue, format: .dateTime.hour(.twoDigits(amPM: .omitted)))
                                    case .week:
                                        Text(dateValue, format: .dateTime.weekday(.abbreviated))
                                    }
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(preset: .inset) {
                            AxisGridLine()
                            AxisValueLabel()
                        }
                    }
                    reviewsOverlay
                }
            }
        }
        
        // MARK: Reflections Overlay
        
        private var reviewsOverlay: some View {
            GeometryReader { proxy in
                ForEach(viewModel.filteredReflectionsForChartDomain()) { reflection in
                    if let xPosition = viewModel.xPositionForReflection(reflection, in: proxy.size) {
                        Button {
                            onReflectionSelected(reflection)
                        } label: {
                            if let subactivity = reflection.subactivity {
                                Icon(
                                    name: subactivity.icon,
                                    color: .primary,
                                    background: false
                                )
                            } else if let activity = reflection.activity {
                                Icon(
                                    name: activity.icon,
                                    color: .primary,
                                    background: false
                                )
                            }
                        }
                        .position(x: xPosition, y: proxy.size.height - 20)
                    }
                }
            }
        }
        
        // MARK: Annotation View
        
        private func annotationView(data: ChartDataItem) -> some ChartContent {
            RuleMark(x: .value("Measurement Type", data.startDate))
                .foregroundStyle(viewModel.chartColor.opacity(0.3))
                .annotation(
                    position: .top,
                    spacing: 0,
                    overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        if viewModel.selectedMeasurementType == .steps {
                            if viewModel.selectedPeriod == .week {
                                Text("\(data.startDate, format: viewModel.annotationViewFormat)")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(data.startDate, format: viewModel.annotationViewFormat) - \(data.endDate, format: viewModel.annotationViewFormat)")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text(
                                data.startDate,
                                format: viewModel.annotationViewFormat
                            )
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        }
                        
                        Text(
                            data.value,
                            format: .number.precision(.fractionLength(viewModel.selectedMeasurementType == .steps ? 0 : 1))
                        )
                        .bold()
                        .foregroundStyle(viewModel.chartColor)
                    }
                    .padding(8)
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(Color(.tertiarySystemGroupedBackground))
                            
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.tertiarySystemGroupedBackground).opacity(0.1), lineWidth: 1.5)
                        }
                    }
                }
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    
    AnalyticsView.MeasurementChartView(viewModel: viewModel) { _ in }
}

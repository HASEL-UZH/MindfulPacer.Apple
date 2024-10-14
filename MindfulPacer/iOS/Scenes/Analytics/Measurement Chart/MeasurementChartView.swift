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
    let date: Date
    let value: Double
}

// MARK: - MeasurementChartView

extension AnalyticsView {
    struct MeasurementChartView: View {
        // MARK: Properties
        
        @Bindable var viewModel: AnalyticsViewModel
        var onReviewSelected: (SchemaV1.Review) -> Void
        
        // MARK: Body
        
        var body: some View {
            ZStack {
                Chart {
                    if let selectedData = viewModel.selectedData {
                        annotationView(data: selectedData)
                    }
                    
                    ForEach(viewModel.chartThresholds, id: \.threshold) { chartThreshold in
                        RuleMark(y: .value("Goal", chartThreshold.threshold))
                            .foregroundStyle(chartThreshold.reviewReminderType.color)
                            .lineStyle(.init(lineWidth: 1, dash: [5]))
                    }
                    
                    ForEach(viewModel.chartData) { dataPoint in
                        switch viewModel.selectedMeasurementType {
                        case .heartRate:
                            Plot {
                                AreaMark(
                                    x: .value("Time", dataPoint.date),
                                    yStart: .value("Value", dataPoint.value),
                                    yEnd: .value("Min Value", viewModel.minValue)
                                )
                                .foregroundStyle(Gradient(colors: [viewModel.chartColor.opacity(0.5), .clear]))
                                .interpolationMethod(.catmullRom)
                                
                                LineMark(
                                    x: .value("Time", dataPoint.date),
                                    y: .value("Value", dataPoint.value)
                                )
                                .foregroundStyle(viewModel.chartColor)
                                .interpolationMethod(.catmullRom)
                                .symbol(.circle)
                            }
                        case .steps:
                            BarMark(
                                x: .value("Time", dataPoint.date),
                                yStart: .value("Start", 0),
                                yEnd: .value("Steps", max(0, dataPoint.value)),
                                width: .automatic
                            )
                            .foregroundStyle(viewModel.chartColor)
                            .opacity(viewModel.rawSelectedDate == nil || dataPoint.date == viewModel.selectedData?.date ? 1.0 : 0.3)
                        }
                    }
                }
                .chartXSelection(value: $viewModel.rawSelectedDate)
                .chartYScale(domain: 0...(viewModel.maxValue * 1.1))
                .chartXAxis {
                    switch viewModel.selectedPeriod {
                    case .oneHour:
                        AxisMarks(values: .stride(by: .minute, count: 5)) {
                            AxisValueLabel(format: .dateTime.hour().minute())
                            AxisTick()
                            AxisGridLine()
                        }
                    case .twoHours:
                        AxisMarks(values: .stride(by: .minute, count: 15)) {
                            AxisValueLabel(format: .dateTime.hour().minute())
                            AxisTick()
                            AxisGridLine()
                        }
                    case .day:
                        AxisMarks(values: .stride(by: .hour, count: 3)) {
                            AxisValueLabel(format: .dateTime.hour(.twoDigits(amPM: .omitted)))
                            AxisTick()
                            AxisGridLine()
                        }
                    case .week:
                        AxisMarks(values: .stride(by: .day)) {
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            AxisTick()
                            AxisGridLine()
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(preset: .inset) {
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .chartXScale(range: .plotDimension)
                .overlay {
                    if viewModel.chartData.isEmpty {
                        EmptyStateView(
                            image: viewModel.selectedMeasurementType == .heartRate ? "chart.xyaxis.line" : "chart.bar.xaxis",
                            title: "No Data",
                            description: viewModel.selectedMeasurementType == .heartRate ? "There is no heart rate data." : "There is no step count data."
                        )
                    }
                }
                
                reviewsOverlay
            }
        }
        
        // MARK: Reviews Overlay
        
        private var reviewsOverlay: some View {
            GeometryReader { proxy in
                ForEach(viewModel.reviewsInPeriod) { review in
                    if let xPosition = viewModel.xPositionForReview(review, in: proxy.size) {
                        Button {
                            onReviewSelected(review)
                        } label: {
                            if let subcategory = review.subcategory {
                                Icon(
                                    name: subcategory.icon,
                                    color: .primary,
                                    background: false
                                )
                            } else if let category = review.category {
                                Icon(
                                    name: category.icon,
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
            RuleMark(x: .value("Measurement Type", data.date))
                .foregroundStyle(viewModel.chartColor.opacity(0.3))
                .annotation(position: .top,
                            spacing: 0,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(data.date, format: viewModel.selectedPeriod == .week ? .dateTime.weekday(.abbreviated).month(.abbreviated).day() : .dateTime.weekday(.abbreviated).hour().minute())
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                        
                        Text(data.value, format: .number.precision(.fractionLength(viewModel.selectedMeasurementType == .steps ? 0 : 1)))
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

#Preview {
    let viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    
    AnalyticsView.MeasurementChartView(viewModel: viewModel) { _ in
        
    }
}

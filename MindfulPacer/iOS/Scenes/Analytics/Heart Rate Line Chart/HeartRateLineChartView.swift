//
//  LineChartView.swift
//  iOS
//
//  Created by Grigor Dochev on 30.09.2024.
//

import Algorithms
import SwiftUI
import Charts

// MARK: - ChartDataItem

struct ChartDataItem: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - LineChartView

extension AnalyticsView {
    struct HeartRateLineChartView: View {
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
                    }
                }
                .frame(height: 256)
                .chartXSelection(value: $viewModel.rawSelectedDate)
                .chartYScale(domain: (viewModel.minValue - abs(viewModel.minValue * 0.15))...(viewModel.maxValue * 1.1))
                .chartXAxis {
                    // Customize the x-axis based on the selected period
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
                            image: "chart.xyaxis.line",
                            title: "No Data",
                            description: "There is no heart rate data."
                        )
                    }
                }
                
                GeometryReader { proxy in
                    ForEach(viewModel.reviewsInPeriod) { review in
                        if let xPosition = xPositionForReview(review, in: proxy.size) {
                            Button {
                                onReviewSelected(review)
                            } label: {
                                if let subcategory = review.subcategory {
                                    Icon(name: subcategory.icon, background: false)
                                } else if let category = review.category {
                                    Icon(name: category.icon, background: false)
                                }
                            }
                            .position(x: xPosition, y: proxy.size.height - 20)
                        }
                    }
                }
            }
        }
        
        private func xPositionForReview(_ review: SchemaV1.Review, in chartSize: CGSize) -> CGFloat? {
            guard let firstDate = viewModel.chartData.first?.date,
                  let lastDate = viewModel.chartData.last?.date else {
                return nil
            }
            
            // Calculate the total time interval of the chart and the review's time offset.
            let totalTimeInterval = lastDate.timeIntervalSince(firstDate)
            let reviewTimeInterval = review.date.timeIntervalSince(firstDate)
            
            // Ensure the total time interval is positive.
            guard totalTimeInterval > 0 else { return nil }
            
            // Calculate the x position as a percentage of the total chart width.
            let xPercentage = reviewTimeInterval / totalTimeInterval
            let xPosition = chartSize.width * CGFloat(xPercentage)
            
            // Clamp the value to ensure it remains within the x-axis bounds of the chart.
            return min(max(0, xPosition), chartSize.width)
        }
        
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

// MARK: - Preview

#Preview {
    let viewModel: AnalyticsViewModel = ScenesContainer.shared.analyticsViewModel()
    
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        IconLabelGroupBox(
            label:
                IconLabel(
                    icon: "chart.xyaxis.line",
                    title: "Line Chart",
                    labelColor: Color("BrandPrimary"),
                    background: true
                )
        ) {
            AnalyticsView.HeartRateLineChartView(
                viewModel: viewModel,
                onReviewSelected: { review in
                    print("Selected review: \(review)")
                }
            )
        }
        .padding()
    }
}

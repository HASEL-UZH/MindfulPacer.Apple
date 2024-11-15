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
        var onReviewSelected: (SchemaV1.Review) -> Void
        
        // MARK: Body
        
        var body: some View {
            ZStack {
                if viewModel.chartData.isEmpty {
                    EmptyStateView(
                        image: viewModel.emptyStateImage,
                        title: "No Data",
                        description: viewModel.emptyStateDescription
                    )
                } else {
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
                                
                                if viewModel.selectedPeriod == .week {
                                    // Bars span the full day in week view
                                    BarMark(
                                        xStart: .value("Start", dataPoint.startDate),
                                        xEnd: .value("End", dataPoint.endDate),
                                        y: .value("Steps", max(0, dataPoint.value))
                                    )
                                    .foregroundStyle(viewModel.chartColor)
                                    .opacity(opacityValue)
                                } else {
                                    // Use x for other periods
                                    BarMark(
                                        x: .value("Time", dataPoint.startDate),
                                        yStart: .value("Start", 0),
                                        yEnd: .value("Steps", max(0, dataPoint.value)),
                                        width: .automatic
                                    )
                                    .foregroundStyle(viewModel.chartColor)
                                    .opacity(opacityValue)
                                }
                            }
                        }
                    }
                    .chartXSelection(value: $viewModel.rawSelectedDate)
                    .chartYScale(domain: 0...(viewModel.maxValue * 1.1))
                    .chartXAxis {
                        let axisDates = generateAxisMarkDates()
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
                    .chartXScale(domain: viewModel.chartStartDate...viewModel.chartEndDate)
                    reviewsOverlay
                }
            }
        }
        
        // MARK: Generate Axis Mark Dates
        
        func generateAxisMarkDates() -> [Date] {
            var dates: [Date] = []
            let calendar = Calendar.current
            var currentDate = viewModel.chartStartDate

            let intervalComponents: DateComponents
            switch viewModel.selectedPeriod {
            case .oneHour:
                intervalComponents = DateComponents(minute: 10)
            case .twoHours:
                intervalComponents = DateComponents(minute: 15)
            case .day:
                intervalComponents = DateComponents(hour: 2)
            case .week:
                intervalComponents = DateComponents(day: 1)
            }

            while currentDate <= viewModel.chartEndDate {
                dates.append(currentDate)
                if let nextDate = calendar.date(byAdding: intervalComponents, to: currentDate) {
                    currentDate = nextDate
                } else {
                    break
                }
            }

            return dates
        }
        
        // MARK: Reviews Overlay
        
        private var reviewsOverlay: some View {
            GeometryReader { proxy in
                ForEach(viewModel.reviewsInPeriod) { review in
                    if let xPosition = viewModel.xPositionForReview(review, in: proxy.size) {
                        Button {
                            onReviewSelected(review)
                        } label: {
                            if let subactivity = review.subactivity {
                                Icon(
                                    name: subactivity.icon,
                                    color: .primary,
                                    background: false
                                )
                            } else if let activity = review.activity {
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
                .annotation(position: .top,
                            spacing: 0,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                ) {
                    VStack(alignment: .leading, spacing: 4) {
                        if viewModel.selectedMeasurementType == .steps {
                            Text("\(data.startDate, format: viewModel.annotationViewFormat) - \(data.endDate, format: viewModel.annotationViewFormat)")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        } else {
                            Text(data.startDate, format: viewModel.annotationViewFormat)
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        
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
    
    AnalyticsView.MeasurementChartView(viewModel: viewModel) { _ in }
}


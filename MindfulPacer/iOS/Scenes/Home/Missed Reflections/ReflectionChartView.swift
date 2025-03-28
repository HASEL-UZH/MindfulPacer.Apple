//
//  ReflectionChartView.swift
//  iOS
//
//  Created by Grigor Dochev on 26.03.2025.
//

import SwiftUI
import Charts

// MARK: - Data Point Structs for Charting

struct StepDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let stepCount: Double
}

struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let heartRate: Double
}

// MARK: - ReflectionChartView

struct ReflectionChartView: View {
    // MARK: Properties
    
    let reflection: MissedReflection
    let stepData: [(startDate: Date, endDate: Date, stepCount: Double)]
    let heartRateData: [(startDate: Date, endDate: Date, stepCount: Double)]
    
    // MARK: Body
    
    var body: some View {
        let chartOverlay = VStack {}
        let (yMin, yMax) = yAxisRange()
        
        Group {
            if reflection.measurementType == .steps {
                stepsChart(yMin: yMin, yMax: yMax)
            } else {
                heartRateChart(yMin: yMin, yMax: yMax)
            }
        }
        .chartXAxis {
            // Determine the stride based on the interval and measurement type
            let (strideUnit, strideCount) = xAxisStride()
            AxisMarks(values: .stride(by: strideUnit, count: strideCount)) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)).minute(.twoDigits))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartXScale(domain: plotStart()...plotEnd())
        .chartYScale(domain: yMin...yMax)
        .padding(.horizontal)
        .frame(maxHeight: 300)
        .overlay(chartOverlay, alignment: .top)
    }
    
    // MARK: - Chart Views
    
    @ViewBuilder
    private func stepsChart(yMin: Int, yMax: Int) -> some View {
        Chart {
            // Step chart for steps
            ForEach(stepPoints()) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Steps", point.stepCount)
                )
                .interpolationMethod(.stepCenter)
                .foregroundStyle(.teal)
            }
            
            // Trigger window, aligned with the actual reflection window
            if reflection.interval != .oneDay {
                RectangleMark(
                    xStart: .value("Window Start", windowStart()),
                    xEnd: .value("Window End", reflection.date),
                    yStart: .value("Y Start", yMin),
                    yEnd: .value("Y End", yMax)
                )
                .foregroundStyle(.teal.opacity(0.1))
            }
        }
    }
    
    @ViewBuilder
    private func heartRateChart(yMin: Int, yMax: Int) -> some View {
        Chart {
            // Line chart for heart rate
            ForEach(heartRatePoints()) { point in
                LineMark(
                    x: .value("Time", point.date),
                    y: .value("Heart Rate", point.heartRate)
                )
                .foregroundStyle(.pink)
            }
            
            // Threshold line
            RuleMark(y: .value("Threshold", reflection.threshold))
                .foregroundStyle(Color.primary)
                .lineStyle(StrokeStyle(dash: [5, 5]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Threshold (\(reflection.threshold) bpm)")
                        .font(.caption)
                        .foregroundColor(Color.primary)
                }
            
            // Trigger window, aligned with the actual reflection window
            if reflection.interval != .immediately {
                RectangleMark(
                    xStart: .value("Window Start", windowStart()),
                    xEnd: .value("Window End", reflection.date),
                    yStart: .value("Y Start", yMin),
                    yEnd: .value("Y End", yMax)
                )
                .foregroundStyle(.pink.opacity(0.3))
            }
        }
    }
    
    // MARK: - Chart Data Helpers
    
    private func windowStart() -> Date {
        if reflection.interval == .oneDay && reflection.measurementType == .steps {
            return stepData.min(by: { $0.startDate < $1.startDate })?.startDate ?? reflection.date
        } else if reflection.interval == .immediately && reflection.measurementType == .heartRate {
            return reflection.date
        }
        return reflection.date.addingTimeInterval(-Interval.timeInterval(reflection.interval))
    }
    
    private func plotStart() -> Date {
        let baseStart = windowStart().addingTimeInterval(-Interval.buffer(reflection.interval))
        let extensionDuration = xAxisLabelFrequencyDuration()
        return baseStart.addingTimeInterval(-extensionDuration)
    }
    
    private func plotEnd() -> Date {
        let baseEnd = reflection.date.addingTimeInterval(Interval.buffer(reflection.interval))
        let extensionDuration = xAxisLabelFrequencyDuration()
        return baseEnd.addingTimeInterval(extensionDuration)
    }
    
    private func stepPoints() -> [StepDataPoint] {
        stepData
            .filter { $0.startDate >= plotStart() && $0.startDate <= plotEnd() }
            .map { StepDataPoint(date: $0.startDate, stepCount: $0.stepCount) }
    }
    
    private func heartRatePoints() -> [HeartRateDataPoint] {
        heartRateData
            .filter { $0.startDate >= plotStart() && $0.startDate <= plotEnd() }
            .map { HeartRateDataPoint(date: $0.startDate, heartRate: $0.stepCount) }
    }
    
    // MARK: - Y-Axis Helper
    
    private func yAxisRange() -> (min: Int, max: Int) {
        if reflection.measurementType == .steps {
            // For steps, keep the range starting at 0
            let maxSteps = stepPoints().map { Int($0.stepCount) }.max() ?? reflection.threshold
            return (0, maxSteps)
        } else {
            // For heart rate, set the range based on the data with a 5-unit buffer
            let heartRates = heartRatePoints().map { Int($0.heartRate) }
            let minHeartRate = heartRates.min() ?? reflection.threshold
            let maxHeartRate = max(heartRates.max() ?? reflection.threshold, reflection.threshold)
            
            // Ensure the y-axis minimum is not above the threshold
            let yMin = min(max(0, minHeartRate - 5), reflection.threshold - 5)
            let yMax = maxHeartRate + 5
            return (yMin, yMax)
        }
    }
    
    // MARK: - X-Axis Helpers
    
    private func xAxisStride() -> (unit: Calendar.Component, count: Int) {
        switch (reflection.measurementType, reflection.interval) {
        // Heart Rate Intervals
        case (.heartRate, .immediately):
            return (.minute, 1) // Labels every 1 minute
        case (.heartRate, .fiveMinutes):
            return (.minute, 1) // Labels every 1 minute
        case (.heartRate, .tenMinutes):
            return (.minute, 2) // Labels every 2 minutes
        case (.heartRate, .fifteenMinutes):
            return (.minute, 3) // Labels every 3 minutes
        case (.heartRate, .thirtyMinutes):
            return (.minute, 5) // Labels every 5 minutes
        case (.heartRate, .oneHour):
            return (.minute, 5) // Labels every 5 minutes
            
        // Steps Intervals
        case (.steps, .oneHour):
            return (.minute, 10) // Labels every 10 minutes
        case (.steps, .twoHours):
            return (.minute, 20) // Labels every 15 minutes
        case (.steps, .fourHours):
            return (.minute, 30) // Labels every 30 minutes
        case (.steps, .oneDay):
            return (.hour, 6) // Labels every 3 hours
            
        default:
            return (.minute, 15)
        }
    }
    
    private func xAxisLabelFrequencyDuration() -> TimeInterval {
        let (unit, count) = xAxisStride()
        switch unit {
        case .minute:
            return TimeInterval(count * 60) // Convert minutes to seconds
        case .hour:
            return TimeInterval(count * 3600) // Convert hours to seconds
        default:
            return TimeInterval(15 * 60) // Fallback to 15 minutes in seconds
        }
    }
}

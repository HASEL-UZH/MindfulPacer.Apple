//
//  LineChart.swift
//  iOS
//
//  Created by Grigor Dochev on 17.09.2024.
//

import Algorithms
import SwiftUI
import Charts

// MARK: - DateValueChartData

struct DateValueChartData: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - LineChart

struct LineChart: View {
    // MARK: Properties
    
    @State private var rawSelectedDate: Date?
    @State private var selectedDay: Date?
    
    var chartData: [DateValueChartData]
    var color: Color
    var measurementType: MeasurementType
    
    var selectedData: DateValueChartData? {
        ChartHelper.parseSelectedData(from: chartData, in: rawSelectedDate)
    }
    
    var minValue: Double {
        chartData.map { $0.value }.min() ?? 0
    }
    
    var average: Double {
        chartData.map { $0.value }.average
    }
    
    // MARK: Body
    
    var body: some View {
        Chart {
            if let selectedData {
                ChartAnnotationView(
                    data: selectedData,
                    measurementType: measurementType,
                    color: color
                )
            }
            
            RuleMark(y: .value("Goal", 120))
                .foregroundStyle(.red)
                .lineStyle(.init(lineWidth: 1, dash: [5]))
            
            RuleMark(y: .value("Goal", 100))
                .foregroundStyle(.yellow)
                .lineStyle(.init(lineWidth: 1, dash: [5]))
            
            ForEach(chartData) { weight in
                Plot {
                    AreaMark(
                        x: .value("Day", weight.date, unit: .day),
                        yStart: .value("Value", weight.value),
                        yEnd: .value("Min Value", minValue)
                    )
                    .foregroundStyle(Gradient(colors: [color.opacity(0.5), .clear]))
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Day", weight.date, unit: .day),
                        y: .value("Value", weight.value)
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    .symbol(.circle)
                }
            }
        }
        .frame(height: 256)
        .chartXSelection(value: $rawSelectedDate)
        .chartYScale(domain: .automatic(includesZero: false))
        .chartXAxis {
            AxisMarks {
                AxisValueLabel(format: .dateTime.month(.defaultDigits).day())
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(Color.secondary.opacity(0.3))
                AxisValueLabel()
            }
        }
        .overlay {
            if chartData.isEmpty {
                EmptyStateView(
                    image: "chart.line.downtrend.xyaxis",
                    title: "No Data",
                    description: "There is no weight data from the Health App."
                )
            }
        }
        .onChange(of: rawSelectedDate) { oldValue, newValue in
            if oldValue?.weekdayInt != newValue?.weekdayInt {
                selectedDay = newValue
            }
        }
    }
}

// MARK: - ChartAnnotationView

struct ChartAnnotationView: ChartContent {
    let data: DateValueChartData
    let measurementType: MeasurementType
    let color: Color
    
    var body: some ChartContent {
        RuleMark(x: .value("Measurement Type", data.date, unit: .day))
            .foregroundStyle(color.opacity(0.3))
            .annotation(position: .top,
                        spacing: 0,
                        overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
            ) {
                annotationView
            }
    }
    
    var annotationView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(data.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Text(data.value, format: .number.precision(.fractionLength(measurementType == .steps ? 0 : 1)))
                .bold()
                .foregroundStyle(color)
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

// MARK: - ChartHelper

struct ChartHelper {
    static func convert(data: [HealthMetric]) -> [DateValueChartData] {
        data.map { .init(date: $0.date, value: $0.value)}
    }
    
    static func parseSelectedData(from data: [DateValueChartData], in selectedDate: Date?) -> DateValueChartData? {
        guard let selectedDate else { return nil }
        return data.first {
            Calendar.current.isDate(selectedDate, inSameDayAs: $0.date)
        }
    }
}

// MARK: - HealthMetric

struct HealthMetric: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

// MARK: - MockData

struct MockData {
    static var heartRate: [HealthMetric] {
        var array: [HealthMetric] = []
        
        for index in 0..<28 {
            let metric = HealthMetric(
                date: Calendar.current.date(byAdding: .day, value: -index, to: .now)!,
                value: .random(in: (80 + Double(index/3)...165 + Double(index/3)))
            )
            array.append(metric)
        }
        
        return array
    }
}

// MARK: - Preview

#Preview {
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
            LineChart(
                chartData: ChartHelper.convert(data: MockData.heartRate),
                color: .accent,
                measurementType: .heartRate
            )
        }
        .padding()
    }
}

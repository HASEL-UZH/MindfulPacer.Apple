//
//  AnalyticsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import Charts
import Foundation
import SwiftData
import SwiftUI

// MARK: - ChartDataItem

struct ChartDataItem: Identifiable, Equatable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let value: Double
}

// MARK: - ReflectionBucket

struct ReflectionBucket: Identifiable {
    let id: UUID = UUID()
    let startDate: Date
    let endDate: Date
    let reflections: [Reflection]
}

// MARK: - ChartGranularity

enum ChartGranularity {
    case day
    case hour
    case minute
}

// MARK: - AnalyticsViewModel

@Observable
@MainActor
class AnalyticsViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let fetchHeartRateUseCase: FetchHeartRateUseCase
    private let fetchStepsUseCase: FetchStepsUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: AnalyticsViewSheet?
    
    var reflectionsInPeriod: [ReflectionBucket] = []
    var reminders: [Reminder] = []
    
    var selectedDateForPeriod: Date = Date.now
    
    var selectedPeriod: Period = .oneHour {
        didSet { refreshChart() }
    }
    var selectedMeasurementType: MeasurementType = .steps {
        didSet { refreshChart() }
    }
    
    var heartRateChartData: [ChartDataItem] = []
    var stepsChartData: [ChartDataItem] = []
    var cumulativeStepsChartData: [ChartDataItem] = []
    
    var downsampledChartData: [ChartDataItem] {
        let maxDataPoints = 100
        
        guard chartData.count > maxDataPoints else {
            return chartData
        }
        
        var downsampledData: [ChartDataItem] = []
        let bucketSize = Double(chartData.count) / Double(maxDataPoints)
        
        for i in 0..<maxDataPoints {
            let bucketStart = Int(Double(i) * bucketSize)
            let bucketEnd = Int(Double(i + 1) * bucketSize)
            
            guard let bucketSlice = chartData[safe: bucketStart..<bucketEnd] else { continue }
            let bucket = Array(bucketSlice)
            guard !bucket.isEmpty else { continue }
            
            if let significantPoint = bucket.max(by: { $0.value < $1.value }) {
                downsampledData.append(significantPoint)
            }
        }
        
        return downsampledData
    }
    
    var selectedDate: Date? {
        didSet {
            selectedChartDataItem = chartData.first(where: { midDate(for: $0) == selectedDate })
        }
    }
    
    var selectedChartDataItem: ChartDataItem?
    var selectedReflectionBucket: ReflectionBucket?
    
    var chartThresholds: [(reminderType: Reminder.ReminderType, threshold: Int)] = []
    
    var weeklyStepsChartData: [ChartDataItem] = []
    
    var chartData: [ChartDataItem] {
        if selectedMeasurementType == .steps && selectedPeriod == .week {
            return weeklyStepsChartData
        } else if selectedMeasurementType == .steps {
            return stepsChartData
        } else {
            return heartRateChartData
        }
    }
    
    var minValue: Double {
        chartData.map { $0.value }.min() ?? 0
    }
    
    var xAxisMarkDates: [Date] {
        guard let firstDataPoint = chartData.first,
              let lastDataPoint = chartData.last else {
            return []
        }
        let domain = firstDataPoint.startDate...lastDataPoint.endDate
        
        var dates: [Date] = []
        let calendar = Calendar.current
        var currentDate = domain.lowerBound
        
        let intervalComponents: DateComponents
        switch selectedPeriod {
        case .oneHour:
            intervalComponents = DateComponents(minute: 10)
        case .twoHours:
            intervalComponents = DateComponents(minute: 15)
        case .day:
            intervalComponents = DateComponents(hour: 2)
        case .week:
            intervalComponents = DateComponents(day: 1)
        }
        
        while currentDate <= domain.upperBound {
            dates.append(currentDate)
            if let nextDate = calendar.date(byAdding: intervalComponents, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return dates
    }
    
    var snappedSelectedDate: Binding<Date?> {
        Binding<Date?>(
            get: { self.selectedDate },
            set: { newDate in
                guard let newDate = newDate else {
                    self.selectedDate = nil
                    return
                }
                
                if let nearest = self.chartData.min(by: {
                    abs(self.midDate(for: $0).timeIntervalSince(newDate)) < abs(self.midDate(for: $1).timeIntervalSince(newDate))
                }) {
                    let difference = abs(self.midDate(for: nearest).timeIntervalSince(newDate))
                    let threshold: TimeInterval
                    switch self.granularity {
                    case .day:
                        threshold = 0.5 * 24 * 3600
                    case .hour:
                        threshold = 0.5 * 3600
                    case .minute:
                        threshold = 7.5 * 60
                    }
                    
                    if difference <= threshold {
                        self.selectedDate = self.midDate(for: nearest)
                    } else {
                        self.selectedDate = nil
                    }
                }
            }
        )
    }
    
    var xDomain: ClosedRange<Date> {
        let dates = chartData.map { midDate(for: $0) }
        guard let minDate = dates.min(), let maxDate = dates.max() else {
            return Date()...Date()
        }
        return minDate...maxDate
    }
    
    var chartEmptyStateImage: String {
        selectedMeasurementType == .heartRate ? "chart.xyaxis.line" : "chart.bar.xaxis"
    }
    
    var chartEmptyStateTitle: String {
        selectedMeasurementType == .heartRate ? String(localized: "No heart rate data") : String(localized: "No steps data")
    }
    
    var annotationViewFormat: Date.FormatStyle {
        selectedPeriod == .week ? .dateTime.weekday(.abbreviated).month(.abbreviated).day() : .dateTime.weekday(.abbreviated).hour().minute()
    }
    
    var chartDescriptionText: String {
        if Calendar.current.isDateInToday(selectedDateForPeriod) {
            return selectedMeasurementType.localized + " " + String(localized: "data within") + " " + String(localized: "the last") + " " + "\(selectedPeriod.description)."
        } else {
            if selectedPeriod == .week {
                return selectedMeasurementType.localized + " " + String(localized: "data for last 7 days from ") + selectedDateForPeriod.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + "."
            } else if selectedPeriod == .day {
                return selectedMeasurementType.localized + " " + String(localized: "data on ") + selectedDateForPeriod.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) + "."
            }
        }
        return ""
    }
    
    var navigationSubtitle: String {
        let dayPart: String = {
            if Calendar.current.isDateInToday(selectedDateForPeriod) {
                return String(localized: "Today")
            } else {
                return selectedDateForPeriod.formatted(.dateTime.day().month())
            }
        }()
        
        return String(localized: "\(dayPart)")
    }
    
    var granularity: ChartGranularity {
        switch selectedPeriod {
        case .oneHour: .hour
        case .twoHours: .hour
        case .day: .hour
        case .week: .day
        }
    }
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        fetchHeartRateUseCase: FetchHeartRateUseCase,
        fetchStepsUseCase: FetchStepsUseCase
    ) {
        self.modelContext = modelContext
        self.fetchHeartRateUseCase = fetchHeartRateUseCase
        self.fetchStepsUseCase = fetchStepsUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchHeartRateChartData()
        fetchStepsChartData()
        updateReflectionsInPeriod()
    }

    func onViewAppear() {
        refreshChart()
    }
    
    func updateReminders(_ newReminders: [Reminder]) {
        reminders = newReminders
        updateChartThresholds()
    }
    
    // MARK: - User Actions
    
    func onTodayTapped() {
        selectedDateForPeriod = Date.now
        onSelectedDateForPeriodChanged()
    }

    func onSelectedDateForPeriodChanged() {
        selectedDate = nil
        selectedChartDataItem = nil
        refreshChart()
        selectedPeriod = .day
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: AnalyticsViewSheet) {
        activeSheet = sheet
    }
    
    func onSheetDismissed() {
        refreshChart()
    }
    
    // MARK: - Chart Related
    
    func getXUnitForPeriod(_ period: Period) -> Calendar.Component {
        switch period {
        case .oneHour, .twoHours:
            return .minute
        case .day:
            return .hour
        case .week:
            return .day
        }
    }
    
    func midDate(for data: ChartDataItem) -> Date {
        return data.startDate.addingTimeInterval(data.endDate.timeIntervalSince(data.startDate) / 2)
    }
    
    // MARK: - Private Methods
    
    private func fetchHeartRateChartData() {
        fetchHeartRateUseCase.execute(for: selectedPeriod, endDate: selectedDateForPeriod) { result in
            switch result {
            case .success(let success):
                Task { @MainActor in
                    self.heartRateChartData = success
                    self.updateChartThresholds()
                }
            case .failure:
                print("Could not fetch heart data")
            }
        }
    }
    
    private func fetchStepsChartData() {
        // Base (non-bucketed) data
        fetchStepsUseCase.execute(for: selectedPeriod, endDate: selectedDateForPeriod) { result in
            switch result {
            case .success(let success):
                Task { @MainActor in
                    self.stepsChartData = success
                    if self.selectedPeriod != .week {
                        // For non-week periods, chartData uses stepsChartData
                        self.updateChartThresholds()
                    }
                }
            case .failure:
                print("Could not fetch cumulative steps data")
            }
        }
        
        // Bucketed weekly data
        if selectedPeriod == .week {
            fetchStepsUseCase.executeBucketed(for: selectedPeriod, endDate: selectedDateForPeriod) { result in
                switch result {
                case .success(let success):
                    Task { @MainActor in
                        self.weeklyStepsChartData = success
                        self.updateChartThresholds()
                    }
                case .failure:
                    print("Could not fetch bucketed weekly steps data")
                }
            }
        } else {
            self.weeklyStepsChartData = []
        }
    }
    
    private func refreshChart() {
        chartThresholds = []
        selectedReflectionBucket = nil
        
        switch selectedMeasurementType {
        case .heartRate:
            fetchHeartRateChartData()
        case .steps:
            fetchStepsChartData()
        }
        
        updateReflectionsInPeriod()
    }
    
    private func fetchCumulativeStepsChartData() {
        fetchStepsUseCase.execute(for: selectedPeriod, endDate: selectedDateForPeriod) { result in
            switch result {
            case .success(let chartDataItems):
                Task { @MainActor in
                    self.cumulativeStepsChartData = chartDataItems
                }
            case .failure(let error):
                print("Could not fetch cumulative steps data: \(error.localizedDescription)")
            }
        }
    }
    
    func updateReflectionsInPeriod() {
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\Reflection.date, order: .reverse)]
            )
            let allReflections = try modelContext.fetch(descriptor)
            
            let start = selectedPeriod.startDate(relativeTo: selectedDateForPeriod)
            let filteredReflections = allReflections.filter { reflection in
                reflection.date >= start && reflection.date <= selectedDateForPeriod
            }
            
            let groupingInterval: TimeInterval
            switch selectedPeriod {
            case .oneHour, .twoHours:
                groupingInterval = 5 * 60
            case .day:
                groupingInterval = 15 * 60
            case .week:
                groupingInterval = 4 * 3600
            }
            
            let sortedReflections = filteredReflections
                .sorted { $0.date < $1.date }
                .filter { !$0.isMissedReflection && !$0.isRejected }
            
            var buckets: [ReflectionBucket] = []
            
            if let firstReflection = sortedReflections.first {
                var currentBucket: [Reflection] = [firstReflection]
                var bucketStartDate = firstReflection.date
                
                for reflection in sortedReflections.dropFirst() {
                    if reflection.date.timeIntervalSince(bucketStartDate) <= groupingInterval {
                        currentBucket.append(reflection)
                    } else {
                        let bucketEndDate = currentBucket.last!.date
                        buckets.append(ReflectionBucket(
                            startDate: bucketStartDate,
                            endDate: bucketEndDate,
                            reflections: currentBucket
                        ))
                        
                        bucketStartDate = reflection.date
                        currentBucket = [reflection]
                    }
                }
                
                if !currentBucket.isEmpty {
                    let bucketEndDate = currentBucket.last!.date
                    buckets.append(ReflectionBucket(
                        startDate: bucketStartDate,
                        endDate: bucketEndDate,
                        reflections: currentBucket
                    ))
                }
            }
            
            reflectionsInPeriod = buckets
        } catch {
            print("DEBUG: Could not fetch reflections: \(error.localizedDescription)")
            reflectionsInPeriod = []
        }
    }
    
    private func updateChartThresholds() {
        guard selectedMeasurementType == .steps else {
            let maxValue = chartData.map { $0.value }.max() ?? 0
            let multiplier: Double = (selectedPeriod == .week) ? 1.0 : 1.5

            chartThresholds = reminders
                .filter { $0.measurementType == selectedMeasurementType }
                .map { ($0.reminderType, $0.threshold) }
                .filter { Double($0.threshold) <= maxValue * multiplier || selectedPeriod == .week }

            return
        }

        let allowedIntervals: Set<Reminder.Interval> = {
            switch selectedPeriod {
            case .oneHour:
                return [.thirtyMinutes, .oneHour]
            case .twoHours:
                return [.thirtyMinutes, .oneHour, .twoHours]
            case .day:
                return [.thirtyMinutes, .oneHour, .twoHours, .fourHours, .oneDay]
            case .week:
                return [.oneDay]
            }
        }()

        chartThresholds = reminders
            .filter { $0.measurementType == .steps }
            .filter { allowedIntervals.contains($0.interval) }
            .map { ($0.reminderType, $0.threshold) }
    }
}

fileprivate extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element>? {
        if range.startIndex >= self.startIndex && range.endIndex <= self.endIndex {
            return self[range]
        }
        return nil
    }
}

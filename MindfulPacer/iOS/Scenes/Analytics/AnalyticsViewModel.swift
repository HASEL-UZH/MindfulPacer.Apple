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
    private let fetchReflectionsInPeriodUseCase: FetchReflectionsInPeriodUseCase
    private let fetchRemindersUseCase: FetchRemindersUseCase
    private let fetchStepsUseCase: FetchStepsUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: AnalyticsViewSheet?

    var reflectionsInPeriod: [ReflectionBucket] = []
    var reminders: [Reminder] = []
    
    var selectedPeriod: Period = .oneHour {
        didSet { refreshChart() }
    }
    var selectedMeasurementType: MeasurementType = .steps {
        didSet { refreshChart() }
    }
    
    var heartRateChartData: [ChartDataItem] = []
    var stepsChartData: [ChartDataItem] = []
    
    var selectedDate: Date? {
        didSet {
            selectedChartDataItem = chartData.first(where: { midDate(for: $0) == selectedDate })
        }
    }
    
    var selectedChartDataItem: ChartDataItem?
    var selectedReflectionBucket: ReflectionBucket?
    
    var chartThresholds: [(reminderType: Reminder.ReminderType, threshold: Int)] = []
    
    var chartData: [ChartDataItem] {
        selectedMeasurementType == .heartRate ? heartRateChartData : stepsChartData
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
        selectedMeasurementType.localized + " " + String(localized: "data within") + " " + String(localized: "the last") + " " + "\(selectedPeriod.description)."
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
        fetchReflectionsInPeriodUseCase: FetchReflectionsInPeriodUseCase,
        fetchRemindersUseCase: FetchRemindersUseCase,
        fetchStepsUseCase: FetchStepsUseCase
    ) {
        self.modelContext = modelContext
        self.fetchHeartRateUseCase = fetchHeartRateUseCase
        self.fetchReflectionsInPeriodUseCase = fetchReflectionsInPeriodUseCase
        self.fetchRemindersUseCase = fetchRemindersUseCase
        self.fetchStepsUseCase = fetchStepsUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchReminders()
        fetchHeartRateChartData()
        fetchStepsChartData()
        updateReflectionsInPeriod()
    }
    
    func onViewAppear() {
        refreshChart()
    }
    
    // MARK: - User Actions
    
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
    
    private func fetchReminders() {
        reminders = fetchRemindersUseCase.execute() ?? []
    }
    
    private func fetchHeartRateChartData() {
        fetchHeartRateUseCase.execute(for: selectedPeriod) { result in
            switch result {
            case .success(let success):
                Task { @MainActor in
                    self.heartRateChartData = success
                }
            case .failure:
                print("Could not fetch heart data")
            }
        }
    }
    
    private func fetchStepsChartData() {
        fetchStepsUseCase.execute(for: selectedPeriod) { result in
            switch result {
            case .success(let success):
                Task { @MainActor in
                    self.stepsChartData = success
                }
            case .failure:
                print("Could not fetch heart data")
            }
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.updateChartThresholds() // FIXME: Not updating when you do Home -> Create Review Reminder -> Analytics, the newly added threshold doesn't show
        }
    }
    
    private func updateReflectionsInPeriod() {
        reflectionsInPeriod = fetchReflectionsInPeriodUseCase.execute(period: selectedPeriod)
    }
    
    private func updateChartThresholds() {
        let maxValue = chartData.map { $0.value }.max() ?? 0
        
        let multiplier: Double = (selectedPeriod == .week) ? 1.0 : 1.5
        
        chartThresholds = reminders
            .filter { $0.measurementType == selectedMeasurementType }
            .map { reminder in
                (reminder.reminderType, reminder.threshold)
            }
            .filter { Double($0.threshold) <= maxValue * multiplier || selectedPeriod == .week }
    }
}

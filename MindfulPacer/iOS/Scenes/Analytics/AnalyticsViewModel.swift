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

@Observable
@MainActor
class AnalyticsViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let fetchHeartRateUseCase: FetchHeartRateUseCase
    private let fetchReviewsInPeriodUseCase: FetchReviewsInPeriodUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    private let fetchStepsUseCase: FetchStepsUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: AnalyticsViewSheet?

    var reviewsInPeriod: [Review] = []
    var reviewReminders: [ReviewReminder] = []
    
    var selectedPeriod: Period = .oneHour {
        didSet { refreshChart() }
    }
    var selectedMeasurementType: MeasurementType = .heartRate {
        didSet { refreshChart() }
    }
    
    var heartRateChartData: [ChartDataItem] = []
    var stepsChartData: [ChartDataItem] = []
    var rawSelectedDate: Date?
    
    var chartThresholds: [(reviewReminderType: ReviewReminder.ReviewReminderType, threshold: Int)] = []
    
    var chartData: [ChartDataItem] {
        selectedMeasurementType == .heartRate ? heartRateChartData : stepsChartData
    }
    
    var chartColor: Color {
        selectedMeasurementType == .heartRate ? .pink : .teal
    }
    
    var selectedData: ChartDataItem? {
        parseSelectedData(from: chartData, in: rawSelectedDate, for: selectedPeriod)
    }
    
    var minValue: Double {
        chartData.map { $0.value }.min() ?? 0
    }
    
    var maxValue: Double {
        chartData.map { $0.value }.max() ?? 0
    }
    
    var average: Double {
        chartData.map { $0.value }.average
    }
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        fetchHeartRateUseCase: FetchHeartRateUseCase,
        fetchReviewsInPeriodUseCase: FetchReviewsInPeriodUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase,
        fetchStepsUseCase: FetchStepsUseCase
    ) {
        self.modelContext = modelContext
        self.fetchHeartRateUseCase = fetchHeartRateUseCase
        self.fetchReviewsInPeriodUseCase = fetchReviewsInPeriodUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
        self.fetchStepsUseCase = fetchStepsUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchReviewReminders()
        fetchHeartRateChartData()
        fetchStepsChartData()
        updateReviewsInPeriod()
    }
    
    func onViewAppear() {
        refreshChart()
    }
    
    // MARK: - User Actions
    
    func selectedDateChanged(oldValue: Date?, newValue: Date?) {
        guard let selectedDate = newValue else { return }
        if let selectedData = parseSelectedData(from: chartData, in: selectedDate, for: selectedPeriod) {
            print("Selected data: \(selectedData)")
        }
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: AnalyticsViewSheet) {
        activeSheet = sheet
    }
    
    func onSheetDismissed() {
        refreshChart()
    }
    
    // MARK: - Chart Related
    
    func chartValueForReview(_ review: SchemaV1.Review) -> Double {
        return minValue - 10
    }
    
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
    
    func xPositionForReview(_ review: SchemaV1.Review, in chartSize: CGSize) -> CGFloat? {
        guard let firstDate = chartData.first?.date,
              let lastDate = chartData.last?.date else {
            return nil
        }
        
        let totalTimeInterval = lastDate.timeIntervalSince(firstDate)
        let reviewTimeInterval = review.date.timeIntervalSince(firstDate)
        
        guard totalTimeInterval > 0 else { return nil }
        
        let xPercentage = reviewTimeInterval / totalTimeInterval
        return chartSize.width * CGFloat(xPercentage)
    }
    
    // MARK: - Private Methods
    
    private func fetchReviewReminders() {
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
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
        
        switch selectedMeasurementType {
        case .heartRate:
            fetchHeartRateChartData()
        case .steps:
            fetchStepsChartData()
        }
        
        updateReviewsInPeriod()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.updateChartThresholds()
        }
    }
    
    private func updateReviewsInPeriod() {
        reviewsInPeriod = fetchReviewsInPeriodUseCase.execute(period: selectedPeriod)
    }
    
    private func parseSelectedData(from data: [ChartDataItem], in selectedDate: Date?, for period: Period) -> ChartDataItem? {
        guard let selectedDate else { return nil }
        return data.first {
            Calendar.current.isDate($0.date, equalTo: selectedDate, toGranularity: getGranularity(for: period))
        }
    }
    
    private func getGranularity(for period: Period) -> Calendar.Component {
        switch period {
        case .oneHour, .twoHours:
            return .minute
        case .day:
            return .hour
        case .week:
            return .day
        }
    }
    
    private func updateChartThresholds() {
        let maxValue = chartData.map { $0.value }.max() ?? 0
        
        // Adjust logic to display thresholds based on more reasonable conditions
        // We use a different multiplier or add a base threshold to ensure visibility when it makes sense
        let multiplier: Double = (selectedPeriod == .week) ? 1.0 : 1.5
        
        chartThresholds = reviewReminders
            .filter { $0.measurementType == selectedMeasurementType }
            .map { reviewReminder in
                (reviewReminder.reviewReminderType, reviewReminder.threshold)
            }
            .filter { Double($0.threshold) <= maxValue * multiplier || selectedPeriod == .week }
    }
}

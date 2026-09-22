//
//  AnalyticsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

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

extension ChartDataItem: StatChartEntry {
    var date: Date {
        startDate.addingTimeInterval(endDate.timeIntervalSince(startDate) / 2)
    }
}

// MARK: - ReflectionBucket

struct ReflectionBucket: Identifiable {
    let id: UUID = UUID()
    let startDate: Date
    let endDate: Date
    let reflections: [Reflection]
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
    
    var selectedDateForPeriod: Date = Date.now

    /// Returns the effective end date for data queries.
    /// For today, uses the current time. For past dates, uses end of day (23:59:59)
    var effectiveEndDate: Date {
        if Calendar.current.isDateInToday(selectedDateForPeriod) {
            return selectedDateForPeriod
        } else {
            let startOfNextDay = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: selectedDateForPeriod))!
            return startOfNextDay.addingTimeInterval(-1)
        }
    }

    var selectedPeriod: Period = .oneHour {
        didSet { refreshChart() }
    }
    var selectedMeasurementType: MeasurementType = .steps {
        didSet { refreshChart() }
    }
    
    var heartRateChartData: [ChartDataItem] = []
    var stepsChartData: [ChartDataItem] = []
    
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
    
    var activeReflectionChipID: String? {
        didSet {
            clearStaleReflectionChipSelection()
        }
    }

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

    var statChartData: [ChartDataItem] {
        if selectedMeasurementType == .steps && selectedPeriod == .week {
            return chartData
        }
        return downsampledChartData
    }

    var statChartPeriod: StatChartPeriod {
        get { selectedPeriod.statChartPeriod }
        set {
            let period = Period(statChartPeriod: newValue)
            guard selectedPeriod != period else { return }
            selectedPeriod = period
        }
    }

    var statChartPeriodBinding: Binding<StatChartPeriod> {
        Binding(
            get: { self.statChartPeriod },
            set: { self.statChartPeriod = $0 }
        )
    }

    var activeStatChartPeriods: [StatChartPeriod] {
        Period.activeCases(for: selectedDateForPeriod).map(\.statChartPeriod)
    }

    var statChartDomainMapping: [StatChartPeriod: TimeInterval] {
        [
            .oneHour: 3_600,
            .twoHours: 7_200,
            .day: 86_400,
            .week: 7 * 86_400
        ]
    }

    var statChartXAxisDateFormat: String {
        switch selectedPeriod {
        case .oneHour, .twoHours:
            "HH:mm"
        case .day:
            "HH"
        case .week:
            "EEE"
        }
    }

    var statChartMarkStyle: StatChartMarkStyle {
        if selectedMeasurementType == .steps && selectedPeriod == .week {
            return .bar()
        }
        return .area(lineWidth: 2, opacity: 0.18)
    }

    var statChartSummaryMode: StatChartSummaryMode {
        selectedMeasurementType == .heartRate ? .average : .latest
    }

    var reflectionChips: [StatChartChip] {
        reflectionsInPeriod.map { bucket in
            StatChartChip(
                id: reflectionChipID(for: bucket),
                label: reflectionChipLabel(for: bucket),
                valueText: reflectionChipValueText(for: bucket),
                unitText: reflectionChipUnitText(for: bucket),
                overlay: .focusDate(bucket.startDate)
            )
        }
    }
    
    var chartEmptyStateImage: String {
        selectedMeasurementType == .heartRate ? "chart.xyaxis.line" : "chart.bar.xaxis"
    }
    
    var chartEmptyStateTitle: String {
        selectedMeasurementType == .heartRate ? String(localized: "No heart rate data") : String(localized: "No steps data")
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
        refreshChart()
    }
    
    // MARK: - User Actions
    
    func onTodayTapped() {
        selectedDateForPeriod = Date.now
        onSelectedDateForPeriodChanged()
    }

    func onSelectedDateForPeriodChanged() {
        if selectedPeriod == .day {
            refreshChart()
        } else {
            selectedPeriod = .day
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
    
    // MARK: - Private Methods
    
    private func fetchHeartRateChartData() {
        fetchHeartRateUseCase.execute(for: selectedPeriod, endDate: effectiveEndDate) { result in
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
        // Base (non-bucketed) data
        fetchStepsUseCase.execute(for: selectedPeriod, endDate: effectiveEndDate) { result in
            switch result {
            case .success(let success):
                Task { @MainActor in
                    self.stepsChartData = success
                }
            case .failure:
                print("Could not fetch cumulative steps data")
            }
        }
        
        // Bucketed weekly data
        if selectedPeriod == .week {
            fetchStepsUseCase.executeBucketed(for: selectedPeriod, endDate: effectiveEndDate) { result in
                switch result {
                case .success(let success):
                    Task { @MainActor in
                        self.weeklyStepsChartData = success
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
        activeReflectionChipID = nil
        
        switch selectedMeasurementType {
        case .heartRate:
            fetchHeartRateChartData()
        case .steps:
            fetchStepsChartData()
        }
        
        updateReflectionsInPeriod()
    }
    
    func updateReflectionsInPeriod() {
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\Reflection.date, order: .reverse)]
            )
            let allReflections = try modelContext.fetch(descriptor)
            
            let endDate = effectiveEndDate
            let start = selectedPeriod.startDate(relativeTo: endDate)
            let filteredReflections = allReflections.filter { reflection in
                reflection.date >= start && reflection.date <= endDate
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
            clearStaleReflectionChipSelection()
        } catch {
            print("DEBUG: Could not fetch reflections: \(error.localizedDescription)")
            reflectionsInPeriod = []
            activeReflectionChipID = nil
        }
    }
    
    private func clearStaleReflectionChipSelection() {
        guard let activeReflectionChipID else { return }
        let selectionStillExists = reflectionsInPeriod.contains {
            reflectionChipID(for: $0) == activeReflectionChipID
        }
        if !selectionStillExists {
            self.activeReflectionChipID = nil
        }
    }

    private func reflectionChipID(for bucket: ReflectionBucket) -> String {
        let reflectionIDs = bucket.reflections
            .map(\.id.uuidString)
            .joined(separator: "-")
        return "\(Int(bucket.startDate.timeIntervalSince1970))-\(reflectionIDs)"
    }

    private func reflectionChipLabel(for bucket: ReflectionBucket) -> String {
        guard bucket.reflections.count == 1,
              let reflection = bucket.reflections.first else {
            return String(localized: "\(bucket.reflections.count) Reflections")
        }

        if let subactivity = reflection.subactivity {
            return subactivity.name
        }

        if let activity = reflection.activity {
            return activity.name
        }

        return String(localized: "Reflection")
    }

    private func reflectionChipValueText(for bucket: ReflectionBucket) -> String {
        guard bucket.reflections.count == 1,
              let reflection = bucket.reflections.first else {
            return bucket.startDate.formatted(.dateTime.hour().minute())
        }

        return reflection.date.formatted(.dateTime.hour().minute())
    }

    private func reflectionChipUnitText(for bucket: ReflectionBucket) -> String {
        guard bucket.reflections.count == 1,
              let reflection = bucket.reflections.first else {
            return ""
        }

        if let mood = reflection.mood {
            return mood.emoji
        }

        if let wellBeing = reflection.wellBeing {
            return Symptom.wellBeing(wellBeing).description
        }

        return ""
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

private extension Period {
    var statChartPeriod: StatChartPeriod {
        switch self {
        case .oneHour:
            .oneHour
        case .twoHours:
            .twoHours
        case .day:
            .day
        case .week:
            .week
        }
    }

    init(statChartPeriod: StatChartPeriod) {
        switch statChartPeriod {
        case .oneHour:
            self = .oneHour
        case .twoHours:
            self = .twoHours
        case .day, .month, .sixMonths, .year:
            self = .day
        case .week:
            self = .week
        }
    }
}

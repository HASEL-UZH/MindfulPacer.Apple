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
    var id = UUID()
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
    var id: String { reflections.map(\.id.uuidString).joined(separator: "-") }
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
    
    var selectedDateForPeriod: Date = .now
    private(set) var isLoading = false
    private(set) var loadFailed = false
    private var requestID = UUID()
    private var referenceNow = Date.now
    private var cachedReflections: [Reflection] = []
    var chartRevision = UUID()
    var visibleWindow: StatChartVisibleWindow? {
        didSet {
            guard visibleWindow != oldValue else { return }
            updateReflectionsInPeriod(reload: false)
        }
    }

    var effectiveEndDate: Date {
        min(referenceNow, Calendar.current.date(byAdding: .day, value: 1,
            to: Calendar.current.startOfDay(for: selectedDateForPeriod))!)
    }

    var initialVisibleWindow: StatChartVisibleWindow {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: selectedDateForPeriod)
        let start: Date
        let end: Date
        switch selectedPeriod {
        case .oneHour, .twoHours:
            end = effectiveEndDate
            start = selectedPeriod.startDate(relativeTo: end)
        case .day:
            start = day
            end = calendar.date(byAdding: .day, value: 1, to: day)!
        case .week:
            start = calendar.date(byAdding: .day, value: -6, to: day)!
            end = calendar.date(byAdding: .day, value: 1, to: day)!
        }
        return .init(startDate: start, endDate: end, period: statChartPeriod)
    }

    /// A fixed, fully fetched range. The chart cannot drift into unqueried dates.
    var chartDateDomain: ClosedRange<Date> {
        let calendar = Calendar.current
        let days = selectedPeriod == .week ? 28 : 7
        let start = calendar.date(byAdding: .day, value: -days,
            to: calendar.startOfDay(for: selectedDateForPeriod))!
        return start...initialVisibleWindow.endDate
    }

    var selectedPeriod: Period = .oneHour {
        didSet { refreshChart() }
    }
    var selectedMeasurementType: MeasurementType = .heartRate {
        didSet { refreshChart() }
    }
    
    var heartRateChartData: [ChartDataItem] = []
    var stepsChartData: [ChartDataItem] = []
    
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
        guard selectedMeasurementType == .steps, selectedPeriod != .week else { return chartData }
        let window = visibleWindow ?? initialVisibleWindow
        var total = 0.0
        return stepsChartData.filter { $0.date >= window.startDate && $0.date < window.endDate }.map { entry in
            total += entry.value
            return ChartDataItem(id: entry.id, startDate: entry.startDate, endDate: entry.endDate, value: total)
        }
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
        var durations: [StatChartPeriod: TimeInterval] = [
            .oneHour: 3_600, .twoHours: 7_200, .day: 86_400, .week: 7 * 86_400
        ]
        durations[statChartPeriod] = initialVisibleWindow.endDate.timeIntervalSince(initialVisibleWindow.startDate)
        return durations
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
        if selectedMeasurementType == .steps {
            return selectedPeriod == .week ? .bar() : .line(lineWidth: 2, showPoints: false)
        }
        return .area(lineWidth: 2, opacity: 0.18)
    }

    var statChartSummaryMode: StatChartSummaryMode {
        selectedMeasurementType == .heartRate ? .average : (selectedPeriod == .week ? .total : .latest)
    }

    var reflectionChips: [StatChartChip] {
        reflectionsInPeriod.map { bucket in
            StatChartChip(
                id: reflectionChipID(for: bucket),
                label: reflectionChipLabel(for: bucket),
                valueText: reflectionChipValueText(for: bucket),
                unitText: reflectionChipUnitText(for: bucket),
                overlay: .focusDate(bucket.startDate),
                systemImage: bucket.reflections.first?.subactivity?.icon ?? bucket.reflections.first?.activity?.icon ?? "book.closed.fill"
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
        // Keep a browsed historical window in place. If the chart was following
        // the present, advance it so a reflection just created at "now" is visible.
        if Calendar.current.isDateInToday(selectedDateForPeriod),
           selectedPeriod == .oneHour || selectedPeriod == .twoHours,
           let visibleWindow,
           abs(visibleWindow.endDate.timeIntervalSince(referenceNow)) < 1 {
            refreshChart()
        } else {
            updateReflectionsInPeriod()
        }
    }
    
    // MARK: - Chart Related
    
    func getXUnitForPeriod(_ period: Period) -> Calendar.Component {
        if selectedMeasurementType == .heartRate { return .second }
        switch period {
        case .oneHour, .twoHours, .day:
            return .minute
        case .week:
            return .day
        }
    }
    
    // MARK: - Private Methods
    
    func refreshChart() {
        referenceNow = .now
        let token = UUID()
        requestID = token
        activeReflectionChipID = nil
        visibleWindow = initialVisibleWindow
        chartRevision = UUID()
        isLoading = true
        loadFailed = false
        heartRateChartData = []
        stepsChartData = []
        weeklyStepsChartData = []
        let measurement = selectedMeasurementType
        let period = selectedPeriod
        let completion: @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void = { [weak self] result in
            Task { @MainActor in
                guard let self, self.requestID == token else { return }
                self.isLoading = false
                switch result {
                case .success(let entries):
                    let sorted = entries.sorted { $0.startDate < $1.startDate }
                    if measurement == .heartRate {
                        self.heartRateChartData = sorted
                    } else if period == .week {
                        self.weeklyStepsChartData = sorted
                    } else {
                        self.stepsChartData = sorted
                    }
                case .failure:
                    self.loadFailed = true
                }
            }
        }
        if measurement == .heartRate {
            fetchHeartRateUseCase.executeHistory(for: period, startDate: chartDateDomain.lowerBound,
                                                endDate: effectiveEndDate, completion: completion)
        } else {
            fetchStepsUseCase.executeHistory(for: period, startDate: chartDateDomain.lowerBound,
                                            endDate: effectiveEndDate, completion: completion)
        }
        updateReflectionsInPeriod()
    }

    func updateReflectionsInPeriod(reload: Bool = true) {
        do {
            let descriptor = FetchDescriptor<Reflection>(
                sortBy: [SortDescriptor(\Reflection.date, order: .reverse)]
            )
            if reload { cachedReflections = try modelContext.fetch(descriptor) }
            let allReflections = cachedReflections
            
            let window = visibleWindow ?? initialVisibleWindow
            let endDate = window.endDate
            let start = window.startDate
            let filteredReflections = allReflections.filter { reflection in
                reflection.date >= start && reflection.date < endDate
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

    func reflectionChipID(for bucket: ReflectionBucket) -> String {
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

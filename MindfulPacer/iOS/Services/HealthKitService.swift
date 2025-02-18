//
//  HealthKitService.swift
//  iOS
//
//  Created by Grigor Dochev on 29.07.2024.
//

import Foundation
import HealthKit

// MARK: - Period

enum Period: String, CaseIterable {
    case oneHour = "1H"
    case twoHours = "2H"
    case day = "D"
    case week = "W"
    
    var startDate: Date {
        switch self {
        case .oneHour:
            return Calendar.current
                .date(byAdding: .hour, value: -1, to: Date())!
        case .twoHours:
            return Calendar.current
                .date(byAdding: .hour, value: -2, to: Date())!
        case .day:
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        case .week:
            return Calendar.current
                .date(byAdding: .weekOfYear, value: -1, to: Date())!
        }
    }
    
    var displayName: String {
        switch self {
        case .oneHour:
            "1 Hour"
        case .twoHours:
            "2 Hours"
        case .day:
            "Day"
        case .week:
            "Week"
        }
    }
    
    var description: String {
        switch self {
        case .oneHour:
            return "one hour"
        case .twoHours:
            return "two hours"
        case .day:
            return "day"
        case .week:
            return "week"
        }
    }
    
    var granularity: ChartGranularity {
        switch self {
        case .oneHour: .minute
        case .twoHours: .minute
        case .day: .hour
        case .week: .day
        }
    }
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol {
    func requestAuthorization(
        completion: @escaping @Sendable (
            Bool,
            HealthKitError?
        ) -> Void
    )
    func fetchMeasurementData(
        for period: Period,
        measurementType: MeasurementType,
        completion: @escaping @Sendable (
            Result<[HKQuantitySample], HealthKitError>
        ) -> Void
    )
    func fetchCurrentMeasurement(
        for measurementType: MeasurementType,
        completion: @escaping @Sendable (
            Result<(value: Double, timestamp: Date), HealthKitError>
        ) -> Void
    )
}

// MARK: - HealthKitService

class HealthKitService: HealthKitServiceProtocol, @unchecked Sendable {
    static let shared = HealthKitService()
    private var healthStore: HKHealthStore?
    
    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }
    
    // MARK: - Request HealthKit Authorization
    
    func requestAuthorization(
        completion: @escaping @Sendable (Bool, HealthKitError?) -> Void
    ) {
        guard let heartRateType = HKObjectType.quantityType(
            forIdentifier: .heartRate
        ),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            let error = HealthKitError(type: .healthDataUnavailable)
            
            DispatchQueue.main.async {
                completion(false, error)
            }
            return
        }
        
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [heartRateType, stepType]
        
        healthStore?
            .requestAuthorization(
                toShare: typesToShare,
                read: typesToRead
            ) { success, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let customError = HealthKitError(
                            type: .unknownError,
                            underlyingError: error
                        )
                        completion(false, customError)
                    } else if !success {
                        let deniedError = HealthKitError(
                            type: .permissionDenied
                        )
                        completion(false, deniedError)
                    } else {
                        completion(true, nil)
                    }
                }
            }
    }
    
    // MARK: - Fetch Measurement Data (Heart Rate or Steps)
    
    func fetchMeasurementData(
        for period: Period,
        measurementType: MeasurementType,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(
            forIdentifier: measurementType == .steps ? .stepCount : .heartRate
        ) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: period.startDate,
            end: Date(),
            options: .strictEndDate
        )
        
        if measurementType == .steps {
            fetchStepBuckets(
                using: quantityType,
                predicate: predicate,
                period: period,
                completion: completion
            )
        } else if measurementType == .heartRate {
            fetchHeartRateData(
                using: quantityType,
                predicate: predicate,
                completion: completion
            )
        }
    }
    
    // MARK: - Fetch Steps Data with Buckets
    
    private func fetchStepBuckets(
        using quantityType: HKQuantityType,
        predicate: NSPredicate,
        period: Period,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    ) {
        // Define the interval dynamically based on the period
        let interval: DateComponents
        switch period {
        case .oneHour, .twoHours:
            interval = DateComponents(minute: 15) // 15-minute buckets for 1 hour and 2 hours
        case .day:
            interval = DateComponents(hour: 1) // 1-hour buckets for 1 day
        case .week:
            interval = DateComponents(day: 1) // 1-day buckets for 1 week
        }
        
        // Define the anchor date (start of the day)
        let anchorDate = Calendar.current.startOfDay(for: Date())
        
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { _, statisticsCollection, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }
            
            guard let statisticsCollection = statisticsCollection else {
                DispatchQueue.main.async {
                    completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                }
                return
            }
            
            var samples: [HKQuantitySample] = []
            
            // Process statistics into appropriate buckets
            statisticsCollection.enumerateStatistics(
                from: period.startDate,
                to: Date()
            ) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let sample = HKQuantitySample(
                        type: quantityType,
                        quantity: sum,
                        start: statistics.startDate,
                        end: statistics.endDate
                    )
                    samples.append(sample)
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(samples))
            }
        }
        
        healthStore?.execute(query)
    }
    
    // MARK: - Fetch Heart Rate Data
    
    private func fetchHeartRateData(
        using quantityType: HKQuantityType,
        predicate: NSPredicate,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    ) {
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )
        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [sortDescriptor]
        ) { _, results, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(
                        .failure(
                            HealthKitError(
                                type: .unknownError,
                                underlyingError: error
                            )
                        )
                    )
                }
                return
            }
            
            guard let samples = results as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                }
                return
            }
            
            DispatchQueue.main.async {
                completion(.success(samples))
            }
        }
        
        healthStore?.execute(query)
    }
    
    // MARK: - Fetch Current Measurement Value
    
    func fetchCurrentMeasurement(
        for measurementType: MeasurementType,
        completion: @escaping @Sendable (
            Result<(value: Double, timestamp: Date), HealthKitError>
        ) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: measurementType == .steps ? .stepCount : .heartRate) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Date()
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictEndDate
        )
        
        if measurementType == .steps {
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(
                            .failure(
                                HealthKitError(
                                    type: .unknownError,
                                    underlyingError: error
                                )
                            )
                        )
                    }
                    return
                }
                
                guard let result = result,
                      let sum = result.sumQuantity() else {
                    DispatchQueue.main.async {
                        completion(
                            .failure(
                                HealthKitError(type: .failedToFetchSamples)
                            )
                        )
                    }
                    return
                }
                
                let totalSteps = sum.doubleValue(for: HKUnit.count())
                let timestamp = Date()
                
                DispatchQueue.main.async {
                    completion(.success((totalSteps, timestamp)))
                }
            }
            
            healthStore?.execute(query)
        } else {
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(
                            .failure(
                                HealthKitError(
                                    type: .unknownError,
                                    underlyingError: error
                                )
                            )
                        )
                    }
                    return
                }
                
                guard let sample = results?.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(
                            .failure(
                                HealthKitError(type: .failedToFetchSamples)
                            )
                        )
                    }
                    return
                }
                
                let latestHeartRate = sample.quantity.doubleValue(
                    for: HKUnit(from: "count/min")
                )
                let timestamp = sample.endDate
                
                DispatchQueue.main.async {
                    completion(.success((latestHeartRate, timestamp)))
                }
            }
            
            healthStore?.execute(query)
        }
    }
    
    // MARK: - Check Missed Reflections
    
    /// Checks for all "missed reflections" in the last 24 hours for a set of `Reminder`s.
    ///
    /// - For `.steps` reminders:
    ///   - Fetches step data in the last 24 hours and applies a sliding window sum of step samples over the reminder's interval.
    ///   - Whenever the cumulative sum of steps in that window is ≥ the reminder’s threshold, it appends a `(reminder, Date)` to the results,
    ///     using the rightmost sample's end date as the trigger time.
    ///
    /// - For `.heartRate` reminders:
    ///   - Fetches heart rate data in the last 24 hours.
    ///   - Filters all samples to those with a heart rate ≥ threshold.
    ///   - Merges consecutive (or overlapping) time ranges where heart rate is above threshold.
    ///   - If any merged interval meets or exceeds the reminder's interval duration, the end date is recorded as a trigger time.
    ///
    /// - Parameters:
    ///   - reminders: A collection of `Reminder` objects specifying thresholds and intervals for either steps or heart rate.
    ///   - completion: A closure returning either:
    ///       - `.success([(Reminder, Date)])`: Each matched reminder with the time it was met or exceeded.
    ///       - `.failure(HealthKitError)`: If there's an error during data fetching.
    ///
    func checkMissedReflections(
        reminders: [Reminder],
        actionedMissedReflectionIDs: [String],
        completion: @escaping @Sendable (Result<[MissedReflection], HealthKitError>) -> Void
    ) {
        let stepReminders = reminders.filter { $0.measurementType == .steps }
        let heartRateReminders = reminders.filter { $0.measurementType == .heartRate }
        
        if stepReminders.isEmpty && heartRateReminders.isEmpty {
            completion(.success([]))
            return
        }
        
        fetchStepDataLast24Hours { stepSamples in
            self.fetchHeartRateDataLast24Hours { hrSamples in
                let sortedStepSamples = stepSamples.sorted { $0.endDate < $1.endDate }
                let sortedHrSamples = hrSamples.sorted { $0.endDate < $1.endDate }
                
                var rawResults: [MissedReflection] = []
                
                // Process each reminder.
                for reminder in reminders {
                    let threshold = Double(reminder.threshold)
                    switch reminder.measurementType {
                    case .steps:
                        var leftIndex = 0
                        var currentSum = 0.0
                        for rightIndex in 0..<sortedStepSamples.count {
                            let right = sortedStepSamples[rightIndex]
                            currentSum += right.stepCount
                            
                            while leftIndex <= rightIndex &&
                                    sortedStepSamples[leftIndex].endDate < right.endDate.addingTimeInterval(-reminder.interval.timeInterval) {
                                currentSum -= sortedStepSamples[leftIndex].stepCount
                                leftIndex += 1
                            }
                            
                            if currentSum >= threshold {
                                rawResults.append(MissedReflection(reminder, date: right.endDate))
                            }
                        }
                        
                    case .heartRate:
                        let aboveThreshold = sortedHrSamples.filter { $0.stepCount >= threshold }
                        var intervals: [(start: Date, end: Date)] = []
                        for sample in aboveThreshold {
                            intervals.append((sample.startDate, sample.endDate))
                        }
                        
                        let merged = self.mergeIntervals(intervals)
                        for intervalRange in merged {
                            let duration = intervalRange.end.timeIntervalSince(intervalRange.start)
                            if duration >= reminder.interval.timeInterval {
                                rawResults.append(MissedReflection(reminder, date: intervalRange.end))
                            }
                        }
                    }
                }
                
                // --- Filtering Logic Starts Here ---
                // Partition raw results by measurement type.
                let hrResults = rawResults.filter { $0.measurementType == .heartRate }
                let stepsResults = rawResults.filter { $0.measurementType == .steps }
                
                // Inline helper to filter non-strong reflections:
                // For non-strong (orange/yellow) reflections, if two occur within 1/4 of the interval,
                // keep only the one with the higher "seriousness score" (threshold * interval.timeInterval).
                func filterResults(_ reflections: [MissedReflection]) -> [MissedReflection] {
                    // Always include strong ones.
                    let strong = reflections.filter { $0.reminderType == .strong }
                    
                    // For non-strong ones, sort by date.
                    let nonStrong = reflections.filter { $0.reminderType != .strong }
                        .sorted { $0.date < $1.date }
                    var filteredNonStrong: [MissedReflection] = []
                    for reflection in nonStrong {
                        if let last = filteredNonStrong.last {
                            let quarterInterval = reflection.interval.timeInterval / 4.0
                            if reflection.date.timeIntervalSince(last.date) < quarterInterval {
                                let lastScore = Double(last.threshold) * last.interval.timeInterval
                                let currentScore = Double(reflection.threshold) * reflection.interval.timeInterval
                                if currentScore > lastScore {
                                    filteredNonStrong[filteredNonStrong.count - 1] = reflection
                                }
                            } else {
                                filteredNonStrong.append(reflection)
                            }
                        } else {
                            filteredNonStrong.append(reflection)
                        }
                    }
                    return strong + filteredNonStrong
                }
                
                let filteredHR = filterResults(hrResults).sorted { $0.date < $1.date }
                let filteredSteps = filterResults(stepsResults).sorted { $0.date < $1.date }
                
                // Limit each to at most 5 reflections, but if there are fewer, just return them.
                let finalHR = filteredHR.count <= 5 ? filteredHR : Array(filteredHR.suffix(5))
                let finalSteps = filteredSteps.count <= 5 ? filteredSteps : Array(filteredSteps.suffix(5))
                
                let combinedResults = (finalHR + finalSteps).sorted { $0.date < $1.date }
                
                let actionedIDs = Set(actionedMissedReflectionIDs)
                let finalResultsWithoutActioned = combinedResults.filter { !actionedIDs.contains($0.id) }
                
                completion(.success(finalResultsWithoutActioned))
            }
        }
    }
    
    /// Fetches all step data from the last 24 hours using `HKSampleQuery`.
    ///
    /// - Retrieves all `.stepCount` samples within the 24-hour window preceding the current time.
    /// - Returns an array of tuples `(startDate, endDate, stepCount)`.
    /// - Each tuple corresponds to one `HKQuantitySample`.
    ///
    /// - Parameters:
    ///   - completion: A closure called with an array of `(Date, Date, Double)` representing all samples.
    ///     If there's an error or if no health store is available, returns an empty array.
    ///
    func fetchStepDataLast24Hours(
        completion: @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void
    ) {
        guard let healthStore = healthStore else {
            completion([])
            return
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([])
            return
        }
        
        let now = Date()
        guard let last24Hours = Calendar.current.date(byAdding: .hour, value: -24, to: now) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: last24Hours,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKSampleQuery(
            sampleType: stepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if error != nil {
                completion([])
                return
            }
            
            guard let quantitySamples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            var results: [(Date, Date, Double)] = []
            for sample in quantitySamples {
                let val = sample.quantity.doubleValue(for: HKUnit.count())
                results.append((sample.startDate, sample.endDate, val))
            }
            
            completion(results)
        }
        
        healthStore.execute(query)
    }
    
    /// Fetches all heart rate data from the last 24 hours using `HKSampleQuery`.
    ///
    /// - Retrieves all `.heartRate` samples within the 24-hour window preceding the current time.
    /// - Returns an array of tuples `(startDate, endDate, heartRateValue)`.
    /// - Each tuple corresponds to one `HKQuantitySample` representing beats per minute (bpm).
    ///
    /// - Parameters:
    ///   - completion: A closure called with an array of `(Date, Date, Double)` representing all samples.
    ///     If there's an error or if no health store is available, returns an empty array.
    ///
    func fetchHeartRateDataLast24Hours(
        completion: @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void
    ) {
        guard let healthStore = healthStore else {
            completion([])
            return
        }
        
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion([])
            return
        }
        
        let now = Date()
        guard let last24Hours = Calendar.current.date(byAdding: .hour, value: -24, to: now) else {
            completion([])
            return
        }
        
        let predicate = HKQuery.predicateForSamples(
            withStart: last24Hours,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKSampleQuery(
            sampleType: hrType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, error in
            if error != nil {
                completion([])
                return
            }
            
            guard let quantitySamples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            var results: [(Date, Date, Double)] = []
            for sample in quantitySamples {
                let val = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                results.append((sample.startDate, sample.endDate, val))
            }
            
            completion(results)
        }
        
        healthStore.execute(query)
    }
    
    /// Merges overlapping or contiguous time intervals where a condition is met (e.g., heart rate above a threshold).
    ///
    /// - Accepts a list of `(start, end)` intervals.
    /// - Sorts them by start time.
    /// - Iterates through the sorted list to merge any intervals that overlap or touch.
    /// - Returns a condensed list of non-overlapping intervals covering all the same time ranges.
    ///
    /// - Parameter intervals: A list of `(start: Date, end: Date)` tuples.
    /// - Returns: A list of merged intervals covering the same time span.
    ///
    private func mergeIntervals(_ intervals: [(start: Date, end: Date)]) -> [(start: Date, end: Date)] {
        if intervals.isEmpty { return [] }
        let sorted = intervals.sorted { $0.start < $1.start }
        var merged: [(Date, Date)] = []
        var current = sorted[0]
        for index in 1..<sorted.count {
            let next = sorted[index]
            if next.start <= current.end {
                if next.end > current.end {
                    current = (current.start, next.end)
                }
            } else {
                merged.append(current)
                current = next
            }
        }
        merged.append(current)
        return merged
    }
    
    private func filterResults(_ reflections: [MissedReflection]) -> [MissedReflection] {
        // Always include strong ones.
        let strong = reflections.filter { $0.reminderType == .strong }
        
        // For non-strong ones, sort by date.
        let nonStrong = reflections.filter { $0.reminderType != .strong }
            .sorted { $0.date < $1.date }
        var filteredNonStrong: [MissedReflection] = []
        for reflection in nonStrong {
            if let last = filteredNonStrong.last {
                let quarterInterval = reflection.interval.timeInterval / 4.0
                if reflection.date.timeIntervalSince(last.date) < quarterInterval {
                    let lastScore = Double(last.threshold) * last.interval.timeInterval
                    let currentScore = Double(reflection.threshold) * reflection.interval.timeInterval
                    if currentScore > lastScore {
                        filteredNonStrong[filteredNonStrong.count - 1] = reflection
                    }
                } else {
                    filteredNonStrong.append(reflection)
                }
            } else {
                filteredNonStrong.append(reflection)
            }
        }
        return strong + filteredNonStrong
    }
}

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
            String(localized: "1 Hour")
        case .twoHours:
            String(localized: "2 Hours")
        case .day:
            String(localized: "Day")
        case .week:
            String(localized: "Week")
        }
    }
    
    var description: String {
        switch self {
        case .oneHour:
            return String(localized: "one hour")
        case .twoHours:
            return String(localized: "two hours")
        case .day:
            return String(localized: "day")
        case .week:
            return String(localized: "week")
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
    func fetchStepDataLast24Hours(
        completion: @escaping @Sendable ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void
    )
    func fetchHeartRateDataLast24Hours(
        completion: @Sendable @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void
    )
    func fetchCumulativeStepData(
        for period: Period,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
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
    
    func requestAuthorization(completion: @escaping @Sendable (Bool, HealthKitError?) -> Void) {
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
    
    // MARK: - Fetch Cumulative Steps Data
    
    func fetchCumulativeStepData(
        for period: Period,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let startDate: Date
        if period == .day {
            startDate = Calendar.current.startOfDay(for: Date())
        } else {
            startDate = period.startDate
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        
        let interval = DateComponents(minute: 15)
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
                DispatchQueue.main.async { completion(.failure(HealthKitError(type: .unknownError, underlyingError: error))) }
                return
            }
            guard let statisticsCollection = statisticsCollection else {
                DispatchQueue.main.async { completion(.failure(HealthKitError(type: .failedToFetchSamples))) }
                return
            }
            
            var runningTotalSamples: [HKQuantitySample] = []
            var currentRunningTotal: Double = 0.0
            
            statisticsCollection.enumerateStatistics(from: startDate, to: Date()) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let stepsInBucket = sum.doubleValue(for: .count())
                    currentRunningTotal += stepsInBucket
                    
                    let runningTotalQuantity = HKQuantity(unit: .count(), doubleValue: currentRunningTotal)
                    let runningTotalSample = HKQuantitySample(
                        type: quantityType,
                        quantity: runningTotalQuantity,
                        start: statistics.startDate,
                        end: statistics.endDate
                    )
                    runningTotalSamples.append(runningTotalSample)
                }
            }
            
            DispatchQueue.main.async {
                completion(.success(runningTotalSamples))
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
        guard let healthStore = healthStore else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
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
            // Define the HKStatisticsQuery closure
            let statsQueryHandler: (HKStatisticsQuery, HKStatistics?, Error?) -> Void = { _, result, error in
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
                
                // Define the HKSampleQuery to get the timestamp
                let sortDescriptor = NSSortDescriptor(
                    key: HKSampleSortIdentifierStartDate,
                    ascending: false
                )
                let sampleQuery = HKSampleQuery(
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
                    
                    let timestamp = sample.endDate
                    
                    DispatchQueue.main.async {
                        completion(.success((totalSteps, timestamp)))
                    }
                }
                
                healthStore.execute(sampleQuery)
            }
            
            // Create and execute the HKStatisticsQuery
            let statsQuery = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                completionHandler: statsQueryHandler
            )
            
            healthStore.execute(statsQuery)
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
            ) { query, results, error in
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
                        return
                    }
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
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Check Missed Reflections

    func checkMissedReflections(
        reminders: [Reminder],
        isDeveloperMode: Bool = false,
        completion: @escaping @Sendable (Result<[MissedReflection], HealthKitError>) -> Void
    ) {
        self.fetchHeartRateDataLast24Hours { heartRateSamples in
            let fetchStepsAndProcess: (@escaping @Sendable ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void) -> Void = { stepCompletion in
                let hasDayPeriodStepsReminder = reminders.contains { $0.measurementType == .steps && $0.interval == .oneDay }
                if hasDayPeriodStepsReminder {
                    self.fetchStepDataCurrentDay(completion: stepCompletion)
                } else {
                    self.fetchStepDataLast24Hours(completion: stepCompletion)
                }
            }
            
            fetchStepsAndProcess { stepSamples in
                var triggeredReflections: [MissedReflection] = []
                var lastTriggerTimes: [String: Date?] = [:]
                for reminder in reminders {
                    lastTriggerTimes[reminder.id.uuidString] = nil
                }
                
                for reminder in reminders {
                    let context: IntervalContext = reminder.measurementType == .steps ? .steps : .heartRate
                    
                    if reminder.measurementType == .steps {
                        if reminder.interval == .oneDay {
                            let totalSteps = stepSamples.reduce(0.0) { $0 + $1.stepCount }
                            if totalSteps > Double(reminder.threshold) {
                                let windowEnd = stepSamples.max(by: { $0.endDate < $1.endDate })?.endDate ?? Date()
                                triggeredReflections.append(MissedReflection(reminder, date: windowEnd))
                            }
                        } else {
                            for currentIndex in 0..<stepSamples.count {
                                let currentSample = stepSamples[currentIndex]
                                let windowEnd = currentSample.endDate
                                let windowStart = windowEnd.addingTimeInterval(-reminder.interval.timeInterval)
                                var totalSteps: Double = 0
                                
                                for previousIndex in stride(from: currentIndex, through: 0, by: -1) {
                                    let sample = stepSamples[previousIndex]
                                    let sampleStart = sample.startDate
                                    let sampleEnd = sample.endDate
                                    if sampleEnd <= windowEnd && sampleStart >= windowStart {
                                        totalSteps += sample.stepCount
                                    }
                                    if sampleStart < windowStart {
                                        break
                                    }
                                }
                                
                                if totalSteps > Double(reminder.threshold) {
                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString] ?? nil
                                    let delay = reminder.interval.buffer(for: context) // Context-aware
                                    if lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= delay {
                                        triggeredReflections.append(MissedReflection(reminder, date: windowEnd))
                                        lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                    }
                                }
                            }
                        }
                    } else if reminder.measurementType == .heartRate {
                        if reminder.interval == .immediately {
                            for sample in heartRateSamples {
                                if sample.stepCount > Double(reminder.threshold) {
                                    let windowEnd = sample.startDate
                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString] ?? nil
                                    let delay = reminder.interval.buffer(for: context) // Context-aware
                                    
                                    if lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= delay {
                                        triggeredReflections.append(MissedReflection(reminder, date: windowEnd))
                                        lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                    }
                                }
                            }
                        } else {
                            for currentIndex in 0..<heartRateSamples.count {
                                let currentSample = heartRateSamples[currentIndex]
                                let windowEnd = currentSample.startDate
                                let windowStart = windowEnd.addingTimeInterval(-reminder.interval.timeInterval)
                                
                                var windowSamples: [(startDate: Date, endDate: Date, stepCount: Double)] = []
                                for previousIndex in stride(from: currentIndex, through: 0, by: -1) {
                                    let sample = heartRateSamples[previousIndex]
                                    let sampleTime = sample.startDate
                                    if sampleTime < windowStart {
                                        break
                                    }
                                    windowSamples.append(sample)
                                }
                                
                                let exceedsThreshold = windowSamples.allSatisfy { $0.stepCount > Double(reminder.threshold) }
                                if exceedsThreshold {
                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString] ?? nil
                                    let delay = reminder.interval.buffer(for: context) // Context-aware
                                    if lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= delay {
                                        triggeredReflections.append(MissedReflection(reminder, date: windowEnd))
                                        lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Step 3: Additional Filtering Before Post-Processing
                struct ReflectionKey: Hashable {
                    let measurementType: MeasurementType
                    let date: Date
                }
                
                var filteredReflections: [MissedReflection] = []
                let groupedByTypeAndTime = Dictionary(grouping: triggeredReflections) { reflection in
                    ReflectionKey(measurementType: reflection.measurementType, date: reflection.date)
                }
                
                for (key, reflections) in groupedByTypeAndTime {
                    let strongReflections = reflections.filter { $0.reminderType == .strong }
                    let nonStrongReflections = reflections.filter { $0.reminderType != .strong }
                    
                    if strongReflections.count > 1 {
                        let largestIntervalReflection = strongReflections.max { r1, r2 in
                            let context1 = r1.measurementType == .steps ? IntervalContext.steps : IntervalContext.heartRate
                            let context2 = r2.measurementType == .steps ? IntervalContext.steps : IntervalContext.heartRate
                            return r1.interval.timeInterval < r2.interval.timeInterval
                        }
                        if let largest = largestIntervalReflection {
                            filteredReflections.append(largest)
                        }
                        filteredReflections.append(contentsOf: nonStrongReflections)
                    } else {
                        filteredReflections.append(contentsOf: reflections)
                    }
                }
                
                // HR-specific filter
                var finalFilteredReflections: [MissedReflection] = []
                let hrReflections = filteredReflections.filter { $0.measurementType == .heartRate }
                let nonHrReflections = filteredReflections.filter { $0.measurementType != .heartRate }
                let groupedHrByTime = Dictionary(grouping: hrReflections) { $0.date }
                
                for (timestamp, reflections) in groupedHrByTime {
                    if reflections.count > 1 {
                        let reflectionWithCounts = reflections.map { reflection -> (MissedReflection, Int) in
                            let context = reflection.measurementType == .steps ? IntervalContext.steps : IntervalContext.heartRate
                            let windowStart = reflection.interval == .immediately ? reflection.date : reflection.date.addingTimeInterval(-reflection.interval.timeInterval)
                            let windowEnd = reflection.date
                            let dataPointsInWindow = heartRateSamples.filter { sample in
                                sample.startDate >= windowStart && sample.startDate <= windowEnd
                            }.count
                            return (reflection, dataPointsInWindow)
                        }
                        let reflectionWithMostPoints = reflectionWithCounts.max { $0.1 < $1.1 }?.0
                        if let bestReflection = reflectionWithMostPoints {
                            finalFilteredReflections.append(bestReflection)
                        }
                    } else {
                        finalFilteredReflections.append(contentsOf: reflections)
                    }
                }
                finalFilteredReflections.append(contentsOf: nonHrReflections)
                
                // Step 4: Post-Processing and Filtering
                let finalReflections: [MissedReflection]
                if isDeveloperMode {
                    finalReflections = finalFilteredReflections.sorted { $0.date < $1.date }
                } else {
                    let stepsReflections = finalFilteredReflections.filter { $0.measurementType == .steps }
                    let heartRateReflections = finalFilteredReflections.filter { $0.measurementType == .heartRate }
                    
                    var filteredSteps = stepsReflections.sorted { $0.date < $1.date }
                    let strongSteps = filteredSteps.filter { $0.reminderType == .strong }
                    let nonStrongSteps = filteredSteps.filter { $0.reminderType != .strong }
                    var filteredNonStrongSteps: [MissedReflection] = []
                    var lastTriggerTimeSteps: Date?
                    
                    for reflection in nonStrongSteps {
                        let context = IntervalContext.steps
                        let buffer = reflection.interval.buffer(for: context) // Context-aware
                        if lastTriggerTimeSteps == nil || reflection.date.timeIntervalSince(lastTriggerTimeSteps!) >= buffer {
                            filteredNonStrongSteps.append(reflection)
                            lastTriggerTimeSteps = reflection.date
                        }
                    }
                    filteredSteps = (strongSteps + filteredNonStrongSteps).sorted { $0.date < $1.date }
                    
                    var filteredHeartRate = heartRateReflections.sorted { $0.date < $1.date }
                    let strongHeartRate = filteredHeartRate.filter { $0.reminderType == .strong }
                    let nonStrongHeartRate = filteredHeartRate.filter { $0.reminderType != .strong }
                    var filteredNonStrongHeartRate: [MissedReflection] = []
                    var lastTriggerTimeHeartRate: Date?
                    
                    for reflection in nonStrongHeartRate {
                        let context = IntervalContext.heartRate
                        let buffer = reflection.interval.buffer(for: context) // Context-aware
                        if lastTriggerTimeHeartRate == nil || reflection.date.timeIntervalSince(lastTriggerTimeHeartRate!) >= buffer {
                            filteredNonStrongHeartRate.append(reflection)
                            lastTriggerTimeHeartRate = reflection.date
                        }
                    }
                    filteredHeartRate = (strongHeartRate + filteredNonStrongHeartRate).sorted { $0.date < $1.date }
                    
                    let finalSteps = filteredSteps.suffix(5)
                    let finalHeartRate = filteredHeartRate.suffix(5)
                    
                    let combinedReflections = (finalSteps + finalHeartRate).sorted { $0.date < $1.date }
                    finalReflections = combinedReflections.filter { !$0.isActioned }
                }
                
                DispatchQueue.main.async {
                    completion(.success(finalReflections))
                }
            }
        }
    }

    /// Fetches step data from the start of the current day (midnight) to now using `HKStatisticsCollectionQuery`.
    ///
    /// - Aggregates `.stepCount` samples into 1-minute intervals from midnight of the current day to the current time.
    /// - Returns an array of tuples `(startDate, endDate, stepCount)` for each interval with non-zero steps.
    /// - HealthKit handles merging of data from multiple sources (e.g., iPhone and Apple Watch).
    ///
    /// - Parameters:
    ///   - completion: A closure called with an array of `(Date, Date, Double)` representing aggregated samples.
    ///     If there's an error or if no health store is available, returns an empty array.
    ///
    func fetchStepDataCurrentDay(completion: @escaping @Sendable ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void) {
        guard let healthStore = healthStore else {
            completion([])
            return
        }
        
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion([])
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        
        // Use 1-minute intervals for aggregation
        let interval = DateComponents(minute: 1)
        let anchorDate = startOfDay
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
            if error != nil {
                completion([])
                return
            }
            
            guard let statsCollection = results else {
                completion([])
                return
            }
            
            var results: [(startDate: Date, endDate: Date, stepCount: Double)] = []
            statsCollection.enumerateStatistics(from: startOfDay, to: now) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let stepCount = sum.doubleValue(for: HKUnit.count())
                    if stepCount > 0 { // Only include intervals with non-zero steps
                        results.append((statistics.startDate, statistics.endDate, stepCount))
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }
        
        healthStore.execute(query)
    }

    /// Fetches all step data from the last 24 hours using `HKStatisticsCollectionQuery`.
    ///
    /// - Aggregates `.stepCount` samples into 1-minute intervals within the 24-hour window preceding the current time.
    /// - Returns an array of tuples `(startDate, endDate, stepCount)` for each interval with non-zero steps.
    /// - HealthKit handles merging of data from multiple sources (e.g., iPhone and Apple Watch).
    ///
    /// - Parameters:
    ///   - completion: A closure called with an array of `(Date, Date, Double)` representing aggregated samples.
    ///     If there's an error or if no health store is available, returns an empty array.
    ///
    func fetchStepDataLast24Hours(completion: @escaping @Sendable ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void) {
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
        
        // Use 1-minute intervals for aggregation
        let interval = DateComponents(minute: 1)
        let anchorDate = last24Hours
        
        let predicate = HKQuery.predicateForSamples(
            withStart: last24Hours,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum],
            anchorDate: anchorDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
            if error != nil {
                completion([])
                return
            }
            
            guard let statsCollection = results else {
                completion([])
                return
            }
            
            var results: [(startDate: Date, endDate: Date, stepCount: Double)] = []
            statsCollection.enumerateStatistics(from: last24Hours, to: now) { statistics, stop in
                if let sum = statistics.sumQuantity() {
                    let stepCount = sum.doubleValue(for: HKUnit.count())
                    if stepCount > 0 { // Only include intervals with non-zero steps
                        results.append((statistics.startDate, statistics.endDate, stepCount))
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(results)
            }
        }
        
        healthStore.execute(query)
    }

    /// Fetches all heart rate data from the last 24 hours using `HKSampleQuery`.
    ///
    /// - Retrieves all `.heartRate` samples within the 24-hour window preceding the current time.
    /// - Returns an array of tuples `(startDate, endDate, heartRateValue)`.
    /// - Each tuple corresponds to one `HKQuantitySample` representing beats per minute (bpm).
    /// - Saves results to a JSON file named "heartRateDataLast24Hours.json" in the document directory.
    ///
    /// - Parameters:
    ///   - completion: A closure called with an array of `(Date, Date, Double)` representing all samples.
    ///     If there's an error or if no health store is available, returns an empty array.
    ///
    func fetchHeartRateDataLast24Hours(completion: @Sendable @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void) {
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
}

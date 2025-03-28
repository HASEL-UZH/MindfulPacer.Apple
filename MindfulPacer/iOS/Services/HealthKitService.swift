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
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func checkMissedReflections(
        reminders: [Reminder],
        isDeveloperMode: Bool = false,
        completion: @escaping @Sendable (Result<[MissedReflection], HealthKitError>) -> Void
    ) {
        self.fetchStepDataLast24Hours { stepSamples in
            self.fetchHeartRateDataLast24Hours { heartRateSamples in
                // Step 1: Initialize storage for reflections and delay tracking
                var triggeredReflections: [MissedReflection] = []
                var lastTriggerTimes: [String: Date?] = [:]
                for reminder in reminders {
                    lastTriggerTimes[reminder.id.uuidString] = nil
                }
                
                // Create debug directory
                let debugDir = FileManager.default.temporaryDirectory.appendingPathComponent("debug")
                do {
                    try FileManager.default.createDirectory(at: debugDir, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print("Failed to create debug directory: \(error)")
                }
                
                // Step 2: Generate raw candidate reflections
                for reminder in reminders {
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
                                let windowStart = windowEnd.addingTimeInterval(-Interval.timeInterval(reminder.interval))
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
                                    let delay = Interval.buffer(reminder.interval)
                                    if lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= delay {
                                        triggeredReflections.append(MissedReflection(reminder, date: windowEnd))
                                        lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                    }
                                }
                            }
                        }
                    } else if reminder.measurementType == .heartRate {
                        // Create a debug file for this reminder based on its interval
                        let debugFileName = "heart_rate_\(reminder.interval.rawValue.lowercased().replacingOccurrences(of: " ", with: "_")).txt"
                        let debugFilePath = debugDir.appendingPathComponent(debugFileName)
                        var debugLog = "Heart Rate Missed Reflections Debug Log - Interval: \(reminder.interval.rawValue)\n"
                        debugLog += "=====================================\n\n"
                        debugLog += "Reminder Details:\n"
                        debugLog += "  Interval: \(reminder.interval.rawValue)\n"
                        debugLog += "  Threshold: \(reminder.threshold) bpm\n"
                        debugLog += "--------------------------------------------------\n\n"
                        
                        if reminder.interval == .immediately {
                            debugLog += "Processing in Immediate Mode\n\n"
                            for sample in heartRateSamples {
                                debugLog += "Sample Evaluation:\n"
                                debugLog += "  Timestamp: \(sample.startDate)\n"
                                debugLog += "  Heart Rate: \(sample.stepCount) bpm\n"
                                debugLog += "  Exceeds Threshold: \(sample.stepCount > Double(reminder.threshold)) (Threshold: \(reminder.threshold) bpm)\n"
                                
                                if sample.stepCount > Double(reminder.threshold) {
                                    let windowEnd = sample.startDate
                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString] ?? nil
                                    let delay = Interval.buffer(reminder.interval)
                                    
                                    debugLog += "  Delay Check:\n"
                                    debugLog += "    Last Trigger: \(lastTrigger?.description ?? "None")\n"
                                    debugLog += "    Delay: \(delay)\n"
                                    let delayPassed = lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= delay
                                    debugLog += "    Delay Passed: \(delayPassed)\n"
                                    
                                    if delayPassed {
                                        debugLog += "  Outcome: Reflection Triggered\n"
                                        triggeredReflections.append(MissedReflection(reminder, date: windowEnd))
                                        lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                    } else {
                                        debugLog += "  Outcome: Skipped (Delay Not Passed)\n"
                                    }
                                } else {
                                    debugLog += "  Outcome: Skipped (Threshold Not Met)\n"
                                }
                                debugLog += "\n"
                            }
                        } else {
                            debugLog += "Processing in Windowed Mode\n\n"
                            for currentIndex in 0..<heartRateSamples.count {
                                let currentSample = heartRateSamples[currentIndex]
                                let windowEnd = currentSample.startDate
                                let windowStart = windowEnd.addingTimeInterval(-Interval.timeInterval(reminder.interval))
                                
                                debugLog += "Window \(currentIndex + 1):\n"
                                debugLog += "  Start: \(windowStart)\n"
                                debugLog += "  End: \(windowEnd)\n"
                                let windowDuration = windowEnd.timeIntervalSince(windowStart)
                                debugLog += "  Duration: \(windowDuration) seconds\n"
                                
                                var windowSamples: [(startDate: Date, endDate: Date, stepCount: Double)] = []
                                for previousIndex in stride(from: currentIndex, through: 0, by: -1) {
                                    let sample = heartRateSamples[previousIndex]
                                    let sampleTime = sample.startDate
                                    if sampleTime < windowStart {
                                        break
                                    }
                                    windowSamples.append(sample)
                                }
                                
                                debugLog += "  Number of Samples: \(windowSamples.count)\n"
                                debugLog += "  Samples:\n"
                                for sample in windowSamples {
                                    debugLog += "    \(sample.startDate): \(sample.stepCount) bpm\n"
                                }
                                
                                let exceedsThreshold = windowSamples.allSatisfy { $0.stepCount > Double(reminder.threshold) }
                                debugLog += "  Exceeds Threshold: \(exceedsThreshold) (Threshold: \(reminder.threshold) bpm)\n"
                                if !exceedsThreshold {
                                    let failingSamples = windowSamples.filter { $0.stepCount <= Double(reminder.threshold) }
                                    debugLog += "  Failing Samples (below threshold):\n"
                                    for sample in failingSamples {
                                        debugLog += "    \(sample.startDate): \(sample.stepCount) bpm\n"
                                    }
                                }
                                
                                if exceedsThreshold {
                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString] ?? nil
                                    let delay = Interval.buffer(reminder.interval)
                                    debugLog += "  Delay Check:\n"
                                    debugLog += "    Last Trigger: \(lastTrigger?.description ?? "None")\n"
                                    debugLog += "    Delay: \(delay)\n"
                                    let delayPassed = lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= delay
                                    debugLog += "    Delay Passed: \(delayPassed)\n"
                                    
                                    if delayPassed {
                                        debugLog += "  Outcome: Reflection Triggered\n"
                                        triggeredReflections.append(MissedReflection(reminder, date: windowEnd))
                                        lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                    } else {
                                        debugLog += "  Outcome: Skipped (Delay Not Passed)\n"
                                    }
                                } else {
                                    debugLog += "  Outcome: Skipped (Threshold Not Met)\n"
                                }
                                debugLog += "\n"
                            }
                        }
                        
                        // Write debug log to file
                        do {
                            try debugLog.write(to: debugFilePath, atomically: true, encoding: .utf8)
                            print("Debug log written to: \(debugFilePath)")
                        } catch {
                            print("Failed to write debug log: \(error)")
                        }
                    }
                }
                
                // Step 3: Post-Processing and Filtering
                let finalReflections: [MissedReflection]
                
                if isDeveloperMode {
                    // In developer mode, return all triggered reflections without filtering, sorted chronologically
                    finalReflections = triggeredReflections.sorted { $0.date < $1.date }
                } else {
                    // Partition by Measurement Type
                    let stepsReflections = triggeredReflections.filter { $0.measurementType == .steps }
                    let heartRateReflections = triggeredReflections.filter { $0.measurementType == .heartRate }
                    
                    // Overlapping and Redundancy Filtering for Steps
                    var filteredSteps = stepsReflections.sorted { $0.date < $1.date }
                    let strongSteps = filteredSteps.filter { $0.reminderType == .strong }
                    let nonStrongSteps = filteredSteps.filter { $0.reminderType != .strong }
                    var filteredNonStrongSteps: [MissedReflection] = []
                    var lastTriggerTimeSteps: Date?
                    
                    for reflection in nonStrongSteps {
                        let buffer = Interval.buffer(reflection.interval)
                        if lastTriggerTimeSteps == nil || reflection.date.timeIntervalSince(lastTriggerTimeSteps!) >= buffer {
                            filteredNonStrongSteps.append(reflection)
                            lastTriggerTimeSteps = reflection.date
                        }
                    }
                    filteredSteps = (strongSteps + filteredNonStrongSteps).sorted { $0.date < $1.date }
                    
                    // Overlapping and Redundancy Filtering for Heart Rate
                    var filteredHeartRate = heartRateReflections.sorted { $0.date < $1.date }
                    let strongHeartRate = filteredHeartRate.filter { $0.reminderType == .strong }
                    let nonStrongHeartRate = filteredHeartRate.filter { $0.reminderType != .strong }
                    var filteredNonStrongHeartRate: [MissedReflection] = []
                    var lastTriggerTimeHeartRate: Date?
                    
                    for reflection in nonStrongHeartRate {
                        let buffer = Interval.buffer(reflection.interval)
                        if lastTriggerTimeHeartRate == nil || reflection.date.timeIntervalSince(lastTriggerTimeHeartRate!) >= buffer {
                            filteredNonStrongHeartRate.append(reflection)
                            lastTriggerTimeHeartRate = reflection.date
                        }
                    }
                    filteredHeartRate = (strongHeartRate + filteredNonStrongHeartRate).sorted { $0.date < $1.date }
                    
                    // Limit to the most recent 5 reflections per measurement type
                    let finalSteps = filteredSteps.suffix(5)
                    let finalHeartRate = filteredHeartRate.suffix(5)
                    
                    // Combine the filtered reflections
                    let combinedReflections = (finalSteps + finalHeartRate).sorted { $0.date < $1.date }
                    
                    // Filter out actioned reflections
                    finalReflections = combinedReflections.filter { !$0.isActioned }
                }
                
                completion(.success(finalReflections))
            }
        }
    }
    
    /// Fetches all step data from the last 24 hours using `HKSampleQuery`.
    ///
    /// - Retrieves all `.stepCount` samples within the 24-hour window preceding the current time.
    /// - Returns an array of tuples `(startDate, endDate, stepCount)`.
    /// - Each tuple corresponds to one `HKQuantitySample`.
    /// - Saves results to a JSON file named "stepDataLast24Hours.json" in the document directory.
    ///
    /// - Parameters:
    ///   - completion: A closure called with an array of `(Date, Date, Double)` representing all samples.
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

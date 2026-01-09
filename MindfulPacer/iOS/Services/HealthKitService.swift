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
    
    static func activeCases(for date: Date) -> [Period] {
        if Calendar.current.isDateInToday(date) {
            return Period.allCases
        } else {
            return [.day, .week]
        }
    }
    
    func startDate(endingAt endDate: Date) -> Date {
        switch self {
        case .oneHour:
            return Calendar.current.date(byAdding: .hour, value: -1, to: endDate)!
        case .twoHours:
            return Calendar.current.date(byAdding: .hour, value: -2, to: endDate)!
        case .day:
            return Calendar.current.date(byAdding: .day, value: 0, to: endDate)!
        case .week:
            return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: endDate)!
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
    
    func startDate(relativeTo endDate: Date = Date()) -> Date {
        switch self {
        case .oneHour:
            return Calendar.current.date(byAdding: .hour, value: -1, to: endDate)!
        case .twoHours:
            return Calendar.current.date(byAdding: .hour, value: -2, to: endDate)!
        case .day:
            return Calendar.current.date(byAdding: .day, value: -1, to: endDate)!
        case .week:
            return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: endDate)!
        }
    }
    
    func window(relativeTo endDate: Date = Date()) -> (start: Date, end: Date) {
        (startDate(relativeTo: endDate), endDate)
    }
}

// MARK: - HealthPermissionsState

enum HealthPermissionsState {
    case ok
    case needsRequest
    case unavailable
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol {
    func requestAuthorization(
        completion: @escaping @Sendable (Bool, HealthKitError?) -> Void
    )
    func fetchMeasurementData(
        for period: Period,
        measurementType: MeasurementType,
        endDate: Date,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    )
    func fetchCurrentMeasurement(
        for measurementType: MeasurementType,
        completion: @escaping @Sendable (Result<(value: Double, timestamp: Date), HealthKitError>) -> Void
    )
    func fetchStepDataLast24Hours(
        completion: @escaping @Sendable ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void
    )
    func fetchStepDataCurrentDay(
        completion: @escaping @Sendable ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void
    )
    func fetchHeartRateDataLast24Hours(
        completion: @escaping @Sendable ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void
    )
    func fetchCumulativeStepData(
        for period: Period,
        endDate: Date,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    )
    func checkPermissionsStatus(
        for deviceMode: DeviceMode,
        completion: @escaping @Sendable (HealthPermissionsState) -> Void
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
        endDate: Date,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(
            forIdentifier: measurementType == .steps ? .stepCount : .heartRate
        ) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let (start, end) = period.window(relativeTo: endDate)
        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictEndDate
        )
        
        if measurementType == .steps {
            fetchStepBuckets(
                using: quantityType,
                predicate: predicate,
                period: period,
                endDate: endDate,
                completion: completion
            )
        } else {
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
        endDate: Date,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    ) {
        let interval: DateComponents
        switch period {
        case .oneHour, .twoHours:
            interval = DateComponents(minute: 15)
        case .day:
            interval = DateComponents(hour: 1)
        case .week:
            interval = DateComponents(day: 1)
        }
        
        let anchorDate = Calendar.current.startOfDay(for: endDate)
        
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
            let (start, end) = period.window(relativeTo: endDate)
            
            statisticsCollection.enumerateStatistics(from: start, to: end) { statistics, _ in
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
        endDate: Date,
        completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let startDate: Date = {
            if period == .day {
                return Calendar.current.startOfDay(for: endDate)
            } else {
                return period.startDate(relativeTo: endDate)
            }
        }()
        
        // Use the provided endDate instead of Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        
        let interval = DateComponents(minute: 15)
        let anchorDate = Calendar.current.startOfDay(for: endDate)
        
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
            
            statisticsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
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
                    if stepCount > 0 {
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
    
    // MARK: - Check Permission Status
    
    func checkPermissionsStatus(
        for deviceMode: DeviceMode,
        completion: @escaping @Sendable (HealthPermissionsState) -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable(), let healthStore else {
            completion(.unavailable)
            return
        }
        
        switch deviceMode {
        case .iPhoneOnly:
            guard
                let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
                let stepType      = HKObjectType.quantityType(forIdentifier: .stepCount)
            else {
                completion(.unavailable)
                return
            }
            
            let startDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
            let predicate = HKQuery.predicateForSamples(withStart: startDate,
                                                        end: Date(),
                                                        options: [])
            
            let group = DispatchGroup()
            
            let stateQueue = DispatchQueue(label: "HealthKitService.PermissionState")
            var _hasHeartRateData = false
            var _hasStepData      = false
            var _hadError         = false
            
            func setHasHeartRateData(_ newValue: Bool) {
                stateQueue.sync { _hasHeartRateData = newValue }
            }
            func setHasStepData(_ newValue: Bool) {
                stateQueue.sync { _hasStepData = newValue }
            }
            func setHadError(_ newValue: Bool) {
                stateQueue.sync { _hadError = newValue }
            }
            func readState() -> (hasHeartRateData: Bool, hasStepData: Bool, hadError: Bool) {
                stateQueue.sync { (_hasHeartRateData, _hasStepData, _hadError) }
            }
            
            // Heart rate
            group.enter()
            let hrQuery = HKSampleQuery(sampleType: heartRateType,
                                        predicate: predicate,
                                        limit: 1,
                                        sortDescriptors: nil) { _, samples, error in
                defer { group.leave() }
                
                if let error = error {
                  
                    print("DEBUGY: HR query error:", error)
                    setHadError(true)
                    return
                }
                
                setHasHeartRateData(!(samples?.isEmpty ?? true))
            }
            healthStore.execute(hrQuery)
            
            // Steps
            group.enter()
            let stepQuery = HKSampleQuery(sampleType: stepType,
                                          predicate: predicate,
                                          limit: 1,
                                          sortDescriptors: nil) { _, samples, error in
                defer { group.leave() }
                
                if let error = error {
                    print("DEBUGY: Steps query error:", error)
                    setHadError(true)
                    return
                }
                
                setHasStepData(!(samples?.isEmpty ?? true))
            }
            healthStore.execute(stepQuery)
            
            group.notify(queue: .main) {
                let state = readState()
                if state.hadError {
                    completion(.unavailable)
                    return
                }
                
                let allGood = state.hasHeartRateData && state.hasStepData
                completion(allGood ? .ok : .needsRequest)
            }
            
        case .iPhoneAndWatch:
            let workoutType   = HKObjectType.workoutType()
            let workoutStatus = healthStore.authorizationStatus(for: workoutType)
            
            print("DEBUGY: iPhone+Watch workout status =", workoutStatus.rawValue)
            
            switch workoutStatus {
            case .sharingAuthorized:
                completion(.ok)
            case .sharingDenied, .notDetermined:
                completion(.needsRequest)
            @unknown default:
                completion(.unavailable)
            }
        }
    }
}

extension HealthKitService {

    fileprivate struct ExistingReflectionInfo: Sendable {
        let date: Date
        let measurementType: Reminder.MeasurementType?
        let isRejected: Bool
        let isHandled: Bool
    }

    // Existing entry point (app / SwiftData reflections)
    func checkMissedReflections(
        reminders: [Reminder],
        existingReflections: [Reflection],
        isDeveloperMode: Bool = false,
        completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void
    ) {
        let infos: [ExistingReflectionInfo] = existingReflections.map {
            ExistingReflectionInfo(
                date: $0.date,
                measurementType: $0.measurementType,
                isRejected: $0.isRejected,
                isHandled: ($0.activity != nil)
            )
        }

        checkMissedReflectionsCore(
            reminders: reminders,
            existingInfos: infos,
            isDeveloperMode: isDeveloperMode,
            completion: completion
        )
    }

    // ✅ New entry point (background snapshots)
    func checkMissedReflections(
        reminders: [Reminder],
        existingReflectionSnapshots: [BackgroundReflectionSnapshot],
        isDeveloperMode: Bool = false,
        completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void
    ) {
        let infos: [ExistingReflectionInfo] = existingReflectionSnapshots.map {
            ExistingReflectionInfo(
                date: $0.date,
                measurementType: $0.measurementType,
                isRejected: $0.isRejected,
                isHandled: $0.isHandled
            )
        }

        checkMissedReflectionsCore(
            reminders: reminders,
            existingInfos: infos,
            isDeveloperMode: isDeveloperMode,
            completion: completion
        )
    }

    // ✅ Core implementation shared by both
    private func checkMissedReflectionsCore(
        reminders: [Reminder],
        existingInfos: [ExistingReflectionInfo],
        isDeveloperMode: Bool = false,
        completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void
    ) {
        let calendar = Calendar.current

        struct DayKey: Hashable, Sendable {
            let dayStart: Date
            let measurementType: Reminder.MeasurementType
        }

        struct MinuteKey: Hashable, Sendable {
            let minuteBucket: Int64
            let measurementType: Reminder.MeasurementType
        }

        @Sendable
        func minuteBucket(for date: Date) -> Int64 {
            Int64(date.timeIntervalSince1970 / 60.0)
        }

        // ✅ Equivalent of: isRejected || activity != nil
        let handledInfos = existingInfos.filter { $0.isRejected || $0.isHandled }

        let handledTimesByType: [Reminder.MeasurementType: [Date]] = {
            var tmp: [Reminder.MeasurementType: [Date]] = [:]
            for r in handledInfos {
                if let mt = r.measurementType {
                    tmp[mt, default: []].append(r.date)
                }
            }
            for (k, v) in tmp { tmp[k] = v.sorted() }
            return tmp
        }()

        @Sendable
        func hasHandledNear(
            _ date: Date,
            measurementType: Reminder.MeasurementType,
            interval: Reminder.Interval,
            context: IntervalContext
        ) -> Bool {
            let buffer = interval.buffer(for: context)
            guard buffer > 0, let times = handledTimesByType[measurementType], !times.isEmpty else {
                return false
            }
            for t in times {
                if abs(t.timeIntervalSince(date)) <= buffer { return true }
            }
            return false
        }

        let existingDayKeys: Set<DayKey> = Set(
            handledInfos.compactMap { r in
                guard let mt = r.measurementType else { return nil }
                return DayKey(dayStart: calendar.startOfDay(for: r.date), measurementType: mt)
            }
        )

        let existingMinuteKeys: Set<MinuteKey> = Set(
            handledInfos.compactMap { r in
                guard let mt = r.measurementType else { return nil }
                return MinuteKey(minuteBucket: minuteBucket(for: r.date), measurementType: mt)
            }
        )

        let rejectedWithoutType = existingInfos.filter { $0.isRejected && $0.measurementType == nil }
        let rejectedAnyTypeDayKeys: Set<Date> = Set(rejectedWithoutType.map { calendar.startOfDay(for: $0.date) })
        let rejectedAnyTypeMinuteBuckets: Set<Int64> = Set(rejectedWithoutType.map { minuteBucket(for: $0.date) })
        let rejectedExactTimestamps: Set<Int64> = Set(rejectedWithoutType.map { Int64($0.date.timeIntervalSince1970) })

        // --- Everything below is your original implementation, unchanged except:
        //     it calls completion at the end and uses existingDayKeys/existingMinuteKeys/rejected sets above.

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
                var potentialNewReflections: [Reflection] = []
                var lastTriggerTimes: [String: Date] = [:]

                for reminder in reminders {
                    let context: IntervalContext = reminder.measurementType == .steps ? .steps : .heartRate

                    if reminder.measurementType == .steps {
                        let dataSource = stepSamples

                        if reminder.interval == .oneDay {
                            let totalSteps = dataSource.reduce(0.0) { $0 + $1.stepCount }
                            if totalSteps > Double(reminder.threshold) {
                                let windowEnd = dataSource.max(by: { $0.endDate < $1.endDate })?.endDate ?? Date()

                                if hasHandledNear(windowEnd, measurementType: .steps, interval: reminder.interval, context: context) {
                                    continue
                                }

                                let dayStart = calendar.startOfDay(for: windowEnd)
                                let key = DayKey(dayStart: dayStart, measurementType: reminder.measurementType)
                                let eventExists =
                                existingDayKeys.contains(key) ||
                                rejectedAnyTypeDayKeys.contains(dayStart)

                                if !eventExists {
                                    let triggerSamples: [MeasurementSample] = dataSource.map {
                                        MeasurementSample(type: .steps, value: $0.stepCount, date: $0.endDate)
                                    }
                                    potentialNewReflections.append(
                                        Reflection(
                                            id: UUID(),
                                            date: windowEnd,
                                            activity: nil,
                                            subactivity: nil,
                                            mood: nil,
                                            didTriggerCrash: false,
                                            wellBeing: nil,
                                            fatigue: nil,
                                            shortnessOfBreath: nil,
                                            sleepDisorder: nil,
                                            cognitiveImpairment: nil,
                                            physicalPain: nil,
                                            depressionOrAnxiety: nil,
                                            additionalInformation: "",
                                            measurementType: reminder.measurementType,
                                            reminderType: reminder.reminderType,
                                            threshold: reminder.threshold,
                                            interval: reminder.interval,
                                            triggerSamples: triggerSamples
                                        )
                                    )
                                }
                            }
                        } else {
                            for currentIndex in 0..<dataSource.count {
                                let currentSample = dataSource[currentIndex]
                                let windowEnd = currentSample.endDate
                                let windowStart = windowEnd.addingTimeInterval(-reminder.interval.timeInterval)

                                var totalStepsInWindow: Double = 0
                                for i in stride(from: currentIndex, through: 0, by: -1) {
                                    let sample = dataSource[i]
                                    if sample.startDate < windowStart { break }
                                    totalStepsInWindow += sample.stepCount
                                }

                                if totalStepsInWindow > Double(reminder.threshold) {
                                    if hasHandledNear(windowEnd, measurementType: .steps, interval: reminder.interval, context: context) {
                                        continue
                                    }

                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString]
                                    let buffer = reminder.interval.buffer(for: context)
                                    if lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= buffer {
                                        let bucket = minuteBucket(for: windowEnd)
                                        let eventExists =
                                        existingMinuteKeys.contains(MinuteKey(minuteBucket: bucket, measurementType: reminder.measurementType)) ||
                                        rejectedAnyTypeMinuteBuckets.contains(bucket) ||
                                        rejectedExactTimestamps.contains(Int64(windowEnd.timeIntervalSince1970))

                                        if !eventExists {
                                            var triggerSamples: [MeasurementSample] = []
                                            for i in stride(from: currentIndex, through: 0, by: -1) {
                                                let s = dataSource[i]
                                                if s.startDate < windowStart { break }
                                                triggerSamples.append(MeasurementSample(type: .steps, value: s.stepCount, date: s.endDate))
                                            }
                                            triggerSamples.reverse()

                                            potentialNewReflections.append(
                                                Reflection(
                                                    id: UUID(),
                                                    date: windowEnd,
                                                    activity: nil,
                                                    subactivity: nil,
                                                    mood: nil,
                                                    didTriggerCrash: false,
                                                    wellBeing: nil,
                                                    fatigue: nil,
                                                    shortnessOfBreath: nil,
                                                    sleepDisorder: nil,
                                                    cognitiveImpairment: nil,
                                                    physicalPain: nil,
                                                    depressionOrAnxiety: nil,
                                                    additionalInformation: "",
                                                    measurementType: reminder.measurementType,
                                                    reminderType: reminder.reminderType,
                                                    threshold: reminder.threshold,
                                                    interval: reminder.interval,
                                                    triggerSamples: triggerSamples
                                                )
                                            )
                                            lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                        }
                                    }
                                }
                            }
                        }
                    } else if reminder.measurementType == .heartRate {
                        let dataSource = heartRateSamples

                        if reminder.interval == .immediately {
                            for sample in dataSource {
                                let bpm = sample.stepCount
                                if bpm > Double(reminder.threshold) {
                                    let windowEnd = sample.startDate

                                    if hasHandledNear(windowEnd, measurementType: .heartRate, interval: reminder.interval, context: context) {
                                        continue
                                    }

                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString]
                                    let buffer = reminder.interval.buffer(for: context)
                                    if lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= buffer {
                                        let bucket = minuteBucket(for: windowEnd)
                                        let eventExists =
                                        existingMinuteKeys.contains(MinuteKey(minuteBucket: bucket, measurementType: reminder.measurementType)) ||
                                        rejectedAnyTypeMinuteBuckets.contains(bucket) ||
                                        rejectedExactTimestamps.contains(Int64(windowEnd.timeIntervalSince1970))

                                        if !eventExists {
                                            let triggerSamples = [
                                                MeasurementSample(type: .heartRate, value: bpm, date: sample.startDate)
                                            ]
                                            potentialNewReflections.append(
                                                Reflection(
                                                    id: UUID(),
                                                    date: windowEnd,
                                                    activity: nil,
                                                    subactivity: nil,
                                                    mood: nil,
                                                    didTriggerCrash: false,
                                                    wellBeing: nil,
                                                    fatigue: nil,
                                                    shortnessOfBreath: nil,
                                                    sleepDisorder: nil,
                                                    cognitiveImpairment: nil,
                                                    physicalPain: nil,
                                                    depressionOrAnxiety: nil,
                                                    additionalInformation: "",
                                                    measurementType: reminder.measurementType,
                                                    reminderType: reminder.reminderType,
                                                    threshold: reminder.threshold,
                                                    interval: reminder.interval,
                                                    triggerSamples: triggerSamples
                                                )
                                            )
                                            lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                        }
                                    }
                                }
                            }
                        } else {
                            for currentIndex in 0..<dataSource.count {
                                let currentSample = dataSource[currentIndex]
                                let windowEnd = currentSample.startDate
                                let windowStart = windowEnd.addingTimeInterval(-reminder.interval.timeInterval)

                                let windowSamples = dataSource.filter { $0.startDate >= windowStart && $0.startDate <= windowEnd }
                                if !windowSamples.isEmpty && windowSamples.allSatisfy({ $0.stepCount > Double(reminder.threshold) }) {

                                    if hasHandledNear(windowEnd, measurementType: .heartRate, interval: reminder.interval, context: context) {
                                        continue
                                    }

                                    let lastTrigger = lastTriggerTimes[reminder.id.uuidString]
                                    let buffer = reminder.interval.buffer(for: context)
                                    if lastTrigger == nil || windowEnd.timeIntervalSince(lastTrigger!) >= buffer {
                                        let bucket = minuteBucket(for: windowEnd)
                                        let eventExists =
                                        existingMinuteKeys.contains(MinuteKey(minuteBucket: bucket, measurementType: reminder.measurementType)) ||
                                        rejectedAnyTypeMinuteBuckets.contains(bucket) ||
                                        rejectedExactTimestamps.contains(Int64(windowEnd.timeIntervalSince1970))

                                        if !eventExists {
                                            let triggerSamples: [MeasurementSample] = windowSamples.map {
                                                MeasurementSample(type: .heartRate, value: $0.stepCount, date: $0.startDate)
                                            }
                                            potentialNewReflections.append(
                                                Reflection(
                                                    id: UUID(),
                                                    date: windowEnd,
                                                    activity: nil,
                                                    subactivity: nil,
                                                    mood: nil,
                                                    didTriggerCrash: false,
                                                    wellBeing: nil,
                                                    fatigue: nil,
                                                    shortnessOfBreath: nil,
                                                    sleepDisorder: nil,
                                                    cognitiveImpairment: nil,
                                                    physicalPain: nil,
                                                    depressionOrAnxiety: nil,
                                                    additionalInformation: "",
                                                    measurementType: reminder.measurementType,
                                                    reminderType: reminder.reminderType,
                                                    threshold: reminder.threshold,
                                                    interval: reminder.interval,
                                                    triggerSamples: triggerSamples
                                                )
                                            )
                                            lastTriggerTimes[reminder.id.uuidString] = windowEnd
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                struct ReflectionKey: Hashable {
                    let measurementType: Reminder.MeasurementType
                    let date: Date
                }
                var filteredReflections: [Reflection] = []
                let groupedByTypeAndTime = Dictionary(grouping: potentialNewReflections) { reflection in
                    ReflectionKey(measurementType: reflection.measurementType!, date: reflection.date)
                }
                for (_, reflections) in groupedByTypeAndTime {
                    if let strongReflection = reflections.first(where: { $0.reminderType == .strong }) {
                        filteredReflections.append(strongReflection)
                    } else if let mediumReflection = reflections.first(where: { $0.reminderType == .medium }) {
                        filteredReflections.append(mediumReflection)
                    } else if let lightReflection = reflections.first(where: { $0.reminderType == .light }) {
                        filteredReflections.append(lightReflection)
                    }
                }

                DispatchQueue.main.async {
                    completion(.success(filteredReflections.sorted { $0.date > $1.date }))
                }
            }
        }
    }
}

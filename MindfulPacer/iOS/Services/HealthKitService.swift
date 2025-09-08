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
        completion: @escaping @Sendable (Bool, HealthKitError?) -> Void
    )
    func fetchMeasurementData(
        for period: Period,
        measurementType: MeasurementType,
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
        existingReflections: [Reflection],
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

        @Sendable func minuteBucket(for date: Date) -> Int64 {
            Int64(date.timeIntervalSince1970 / 60.0)
        }

        let handledReflections = existingReflections.filter { $0.isRejected || $0.activity != nil }

        let existingDayKeys: Set<DayKey> = Set(
            handledReflections.compactMap { r in
                guard let mt = r.measurementType else { return nil }
                return DayKey(dayStart: calendar.startOfDay(for: r.date), measurementType: mt)
            }
        )

        let existingMinuteKeys: Set<MinuteKey> = Set(
            handledReflections.compactMap { r in
                guard let mt = r.measurementType else { return nil }
                return MinuteKey(minuteBucket: minuteBucket(for: r.date), measurementType: mt)
            }
        )

        let rejectedWithoutType = existingReflections.filter { $0.isRejected && $0.measurementType == nil }
        let rejectedAnyTypeDayKeys: Set<Date> = Set(rejectedWithoutType.map { calendar.startOfDay(for: $0.date) })
        let rejectedAnyTypeMinuteBuckets: Set<Int64> = Set(rejectedWithoutType.map { minuteBucket(for: $0.date) })
        let rejectedExactTimestamps: Set<Int64> = Set(rejectedWithoutType.map { Int64($0.date.timeIntervalSince1970) })

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

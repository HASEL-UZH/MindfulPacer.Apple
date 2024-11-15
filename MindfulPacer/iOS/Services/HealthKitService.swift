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
            return Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        case .twoHours:
            return Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        case .day:
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        case .week:
            return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
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
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol {
    func requestAuthorization(completion: @escaping @Sendable (Bool, HealthKitError?) -> Void)
    func fetchMeasurementData(for period: Period, measurementType: MeasurementType, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void)
    func fetchCurrentMeasurement(for measurementType: MeasurementType, completion: @escaping @Sendable (Result<(value: Double, timestamp: Date), HealthKitError>) -> Void)
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
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            let error = HealthKitError(type: .healthDataUnavailable)
            
            DispatchQueue.main.async {
                completion(false, error)
            }
            return
        }
        
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [heartRateType, stepType]
        
        healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    let customError = HealthKitError(type: .unknownError, underlyingError: error)
                    completion(false, customError)
                } else if !success {
                    let deniedError = HealthKitError(type: .permissionDenied)
                    completion(false, deniedError)
                } else {
                    completion(true, nil)
                }
            }
        }
    }
    
    // MARK: - Fetch Measurement Data (Heart Rate or Steps)
    
    func fetchMeasurementData(for period: Period, measurementType: MeasurementType, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void) {
        guard let quantityTypeIdentifier = measurementType.quantityTypeIdentifier,
              let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: period.startDate, end: Date(), options: .strictEndDate)
        
        if measurementType == .steps {
            // Use HKStatisticsCollectionQuery for steps data
            fetchStepsData(using: quantityType, predicate: predicate, period: period, completion: completion)
        } else {
            // Use HKSampleQuery for heart rate data
            fetchHeartRateData(using: quantityType, predicate: predicate, completion: completion)
        }
    }
    
    // MARK: - Fetch Steps Data using HKStatisticsCollectionQuery
    
    private func fetchStepsData(using quantityType: HKQuantityType, predicate: NSPredicate, period: Period, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void) {
        let calendar = Calendar.current
        
        let intervalComponents: DateComponents
        switch period {
        case .oneHour:
            intervalComponents = DateComponents(minute: 10) // 10-minute intervals
        case .twoHours:
            intervalComponents = DateComponents(minute: 15) // 15-minute intervals
        case .day:
            intervalComponents = DateComponents(hour: 2) // 2-hour intervals
        case .week:
            intervalComponents = DateComponents(day: 1) // Each day
        }
        
        // Set up the statistics collection query
        let query = HKStatisticsCollectionQuery(
            quantityType: quantityType,
            quantitySamplePredicate: predicate,
            options: [.cumulativeSum],
            anchorDate: period.startDate,
            intervalComponents: intervalComponents
        )
        
        query.initialResultsHandler = { query, statisticsCollection, error in
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
            statisticsCollection.enumerateStatistics(from: period.startDate, to: Date()) { statistics, _ in
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
            
            // Create an immutable copy to avoid data races
            let samplesCopy = samples
            
            samplesCopy.forEach { sample in
                print("DEBUGY:", sample.quantity, sample.startDate, sample.endDate)
            }
            
            completion(.success(samplesCopy))
        }
        
        healthStore?.execute(query)
    }
    
    // MARK: - Fetch Heart Rate Data using HKSampleQuery
    
    private func fetchHeartRateData(using quantityType: HKQuantityType, predicate: NSPredicate, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }
            
            guard let samples = results as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                }
                return
            }
            
            completion(.success(samples))
            
        }
        
        healthStore?.execute(query)
    }
    
    // MARK: - Fetch Current Measurement Value
    
    func fetchCurrentMeasurement(for measurementType: MeasurementType, completion: @escaping @Sendable (Result<(value: Double, timestamp: Date), HealthKitError>) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: measurementType == .steps ? .stepCount : .heartRate) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictEndDate)
        
        if measurementType == .steps {
            // Use HKStatisticsQuery for current day's steps
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                    }
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    DispatchQueue.main.async {
                        completion(.failure(HealthKitError(type: .failedToFetchSamples)))
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
            // For heart rate, fetch the most recent sample
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, results, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                    }
                    return
                }
                
                guard let sample = results?.first as? HKQuantitySample else {
                    DispatchQueue.main.async {
                        completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                    }
                    return
                }
                
                let latestHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                let timestamp = sample.endDate
                
                DispatchQueue.main.async {
                    completion(.success((latestHeartRate, timestamp)))
                }
            }
            
            healthStore?.execute(query)
        }
    }
}

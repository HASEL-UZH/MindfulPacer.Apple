//
//  HealthKitService.swift
//  iOS
//
//  Created by Grigor Dochev on 29.07.2024.
//

import Foundation
import HealthKit

// MARK: - Period

enum Period {
    case day
    case week
    case month
    case sixMonths
    
    var startDate: Date {
        switch self {
        case .day:
            return Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        case .week:
            return Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        case .month:
            return Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        case .sixMonths:
            return Calendar.current.date(byAdding: .month, value: -6, to: Date())!
        }
    }
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol {
    func requestAuthorization(completion: @escaping (Bool, HealthKitError?) -> Void)
    func fetchHeartRateData(for period: Period, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void)
    func fetchCurrentStepCount(completion: @escaping @Sendable (Result<Double, HealthKitError>) -> Void)
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

    func requestAuthorization(completion: @escaping (Bool, HealthKitError?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            let error = HealthKitError(type: .healthDataUnavailable)
            completion(false, error)
            return
        }
        
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [heartRateType, stepType]
        
        healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
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

    // MARK: - Fetch Heart Rate Data

    func fetchHeartRateData(for period: Period, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(.failure(HealthKitError(type: .heartRateTypeUnavailable)))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: period.startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, results, error in
            if let error = error {
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }
            
            guard let samples = results as? [HKQuantitySample] else {
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                }
                return
            }
            
            completion(.success(samples))
        }
        
        healthStore?.execute(query)
    }

    // MARK: - Fetch Current Step Count

    func fetchCurrentStepCount(completion: @escaping @Sendable (Result<Double, HealthKitError>) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(.failure(HealthKitError(type: .stepCountTypeUnavailable)))
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictEndDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .failedToFetchStepCount)))
                }
                return
            }
            
            let stepCount = sum.doubleValue(for: HKUnit.count())
            completion(.success(stepCount))
        }
        
        healthStore?.execute(query)
    }
}

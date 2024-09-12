//
//  HealthKitService.swift
//  iOS
//
//  Created by Grigor Dochev on 29.07.2024.
//

import Foundation
import HealthKit
import CocoaLumberjackSwift

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
            DDLogInfo("HealthKitService initialized and HealthKit is available")
        } else {
            DDLogWarn("HealthKit is not available on this device")
        }
    }

    // MARK: - Request HealthKit Authorization

    func requestAuthorization(completion: @escaping (Bool, HealthKitError?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            let error = HealthKitError(type: .healthDataUnavailable)
            DDLogError("Health data unavailable: heart rate or step count types are missing")
            completion(false, error)
            return
        }

        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [heartRateType, stepType]

        healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if let error = error {
                let customError = HealthKitError(type: .unknownError, underlyingError: error)
                DDLogError("HealthKit authorization failed: \(error.localizedDescription)")
                completion(false, customError)
            } else if !success {
                let deniedError = HealthKitError(type: .permissionDenied)
                DDLogWarn("HealthKit authorization denied by user")
                completion(false, deniedError)
            } else {
                DDLogInfo("HealthKit authorization granted")
                completion(true, nil)
            }
        }
    }

    // MARK: - Fetch Heart Rate Data

    func fetchHeartRateData(for period: Period, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            DDLogError("Heart rate data type unavailable")
            completion(.failure(HealthKitError(type: .heartRateTypeUnavailable)))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: period.startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
            if let error = error {
                DDLogError("Failed to fetch heart rate data: \(error.localizedDescription)")
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }

            guard let samples = results as? [HKQuantitySample] else {
                DDLogError("Failed to cast fetched heart rate data to HKQuantitySample")
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                }
                return
            }

            DDLogInfo("Successfully fetched heart rate data with \(samples.count) samples")
            completion(.success(samples))
        }

        healthStore?.execute(query)
    }

    // MARK: - Fetch Current Step Count

    func fetchCurrentStepCount(completion: @escaping @Sendable (Result<Double, HealthKitError>) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            DDLogError("Step count data type unavailable")
            completion(.failure(HealthKitError(type: .stepCountTypeUnavailable)))
            return
        }

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictEndDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                DDLogError("Failed to fetch step count: \(error.localizedDescription)")
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }

            guard let result = result, let sum = result.sumQuantity() else {
                DDLogError("Failed to fetch step count or sum quantity is nil")
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .failedToFetchStepCount)))
                }
                return
            }

            let stepCount = sum.doubleValue(for: HKUnit.count())
            DDLogInfo("Successfully fetched current step count: \(stepCount)")
            completion(.success(stepCount))
        }

        healthStore?.execute(query)
    }
}

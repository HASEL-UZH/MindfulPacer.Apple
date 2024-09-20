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

enum Period: String, CaseIterable {
    case oneHour = "1H"
    case twoHours = "2H"
    case day = "D"
    case week = "W"
    
    var startDate: Date {
        switch self {
        case .oneHour:
            Calendar.current.date(byAdding: .hour, value: -1, to: Date())!
        case .twoHours:
            Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        case .day:
            Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        case .week:
            Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date())!
        }
    }
    
    var description: String {
        switch self {
        case .oneHour:
            "one hour"
        case .twoHours:
            "two hours"
        case .day:
            "day"
        case .week:
            "week"
        }
    }
}

// MARK: - HealthKitServiceProtocol

protocol HealthKitServiceProtocol {
    func requestAuthorization(completion: @escaping @Sendable (Bool, HealthKitError?) -> Void)
    func fetchMeasurementData(for period: Period, measurementType: MeasurementType, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void)
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

    func requestAuthorization(completion: @escaping @Sendable (Bool, HealthKitError?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            let error = HealthKitError(type: .healthDataUnavailable)
            DDLogError("Health data unavailable: heart rate or step count types are missing")
            
            // Run completion explicitly on the main thread.
            DispatchQueue.main.async {
                completion(false, error)
            }
            return
        }

        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [heartRateType, stepType]

        healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            // Ensure the completion runs on the main thread.
            DispatchQueue.main.async {
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
    }
    
    // MARK: - Fetch Measurement Data (Heart Rate or Steps)
    
    func fetchMeasurementData(for period: Period, measurementType: MeasurementType, completion: @escaping @Sendable (Result<[HKQuantitySample], HealthKitError>) -> Void) {
        guard let quantityTypeIdentifier = measurementType.quantityTypeIdentifier,
              let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) else {
            DDLogError("\(measurementType.rawValue) data type unavailable")
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: period.startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
            if let error = error {
                DDLogError("Failed to fetch \(measurementType.rawValue) data: \(error.localizedDescription)")
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }
            
            guard let samples = results as? [HKQuantitySample] else {
                DDLogError("Failed to cast fetched \(measurementType.rawValue) data to HKQuantitySample")
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                }
                return
            }
            
            DDLogInfo("Successfully fetched \(samples.count) \(measurementType.rawValue) samples")
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

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
            
            let aggregatedSamples = self.aggregateSamples(samples, for: period, measurementType: measurementType)
            
            DDLogInfo("Successfully fetched and aggregated \(aggregatedSamples.count) \(measurementType.rawValue) samples")
            completion(.success(aggregatedSamples))
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
    
    // MARK: - Aggregate Samples
    
    private func aggregateSamples(_ samples: [HKQuantitySample], for period: Period, measurementType: MeasurementType) -> [HKQuantitySample] {
        var groupedSamples: [Date: Double] = [:]
        let calendar = Calendar.current
        
        for sample in samples {
            var normalizedDate: Date
            
            // For different periods, aggregate by minute, hour, or day
            if period == .oneHour || period == .twoHours {
                normalizedDate = calendar.date(bySetting: .minute, value: calendar.component(.minute, from: sample.startDate), of: sample.startDate)!
                normalizedDate = calendar.date(bySetting: .second, value: 0, of: normalizedDate)!
            } else if period == .day {
                normalizedDate = calendar.date(bySetting: .hour, value: calendar.component(.hour, from: sample.startDate), of: sample.startDate)!
                normalizedDate = calendar.date(bySetting: .minute, value: 0, of: normalizedDate)!
                normalizedDate = calendar.date(bySetting: .second, value: 0, of: normalizedDate)!
            } else if period == .week {
                normalizedDate = calendar.startOfDay(for: sample.startDate)
            } else {
                normalizedDate = sample.startDate
            }
            
            let currentValue = groupedSamples[normalizedDate] ?? 0
            
            switch measurementType {
            case .steps:
                groupedSamples[normalizedDate] = currentValue + sample.quantity.doubleValue(for: HKUnit.count())
            case .heartRate:
                // Aggregate heart rate by averaging
                groupedSamples[normalizedDate] = (currentValue + sample.quantity.doubleValue(for: HKUnit(from: "count/min"))) / 2.0
            }
            
            print("Normalized Date for Grouping: \(normalizedDate), Updated Value: \(groupedSamples[normalizedDate] ?? 0)")
        }
        
        // Convert the grouped data back to HKQuantitySample-like structures
        var aggregatedSamples: [HKQuantitySample] = []
        for (normalizedDate, value) in groupedSamples {
            let sample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: measurementType == .steps ? .stepCount : .heartRate)!,
                quantity: HKQuantity(unit: measurementType == .steps ? HKUnit.count() : HKUnit(from: "count/min"), doubleValue: value),
                start: normalizedDate,
                end: normalizedDate
            )
            aggregatedSamples.append(sample)
        }
        
        return aggregatedSamples.sorted { $0.startDate < $1.startDate }
    }
}

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
            // Ensure the completion runs on the main thread.
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
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, results, error in
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
            
            let aggregatedSamples = self.aggregateSamples(samples, for: period, measurementType: measurementType)
            
            completion(.success(aggregatedSamples))
        }
        
        healthStore?.execute(query)
    }
    
    // MARK: - Fetch Current Measurement Value
    
    func fetchCurrentMeasurement(for measurementType: MeasurementType, completion: @escaping @Sendable (Result<(value: Double, timestamp: Date), HealthKitError>) -> Void) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: measurementType == .steps ? .stepCount : .heartRate) else {
            completion(.failure(HealthKitError(type: .healthDataUnavailable)))
            return
        }
        
        // Define the time range as starting from the beginning of today until now
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictEndDate)
        
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, results, error in
            if let error = error {
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .unknownError, underlyingError: error)))
                }
                return
            }
            
            guard let samples = results as? [HKQuantitySample], !samples.isEmpty else {
                Task { @MainActor in
                    completion(.failure(HealthKitError(type: .failedToFetchSamples)))
                }
                return
            }
            
            switch measurementType {
            case .steps:
                // Aggregate steps count and get the timestamp of the last recorded sample
                let totalSteps = samples.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.count()) }
                let lastTimestamp = samples.first!.endDate  // Latest sample is at index 0 due to descending sort
                completion(.success((totalSteps, lastTimestamp)))
                
            case .heartRate:
                // Return the latest heart rate value and its timestamp
                let latestHeartRate = samples.first!.quantity.doubleValue(for: HKUnit(from: "count/min"))
                let lastTimestamp = samples.first!.endDate
                completion(.success((latestHeartRate, lastTimestamp)))
            }
        }
        
        healthStore?.execute(query)
    }
    
    // MARK: - Aggregate Samples
    
    private func aggregateSamples(_ samples: [HKQuantitySample], for period: Period, measurementType: MeasurementType) -> [HKQuantitySample] {
        var groupedSamples: [Date: [Double]] = [:]
        let calendar = Calendar.current
        
        for sample in samples {
            var normalizedDate: Date
            
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
            
            // Store values for each normalized date
            if groupedSamples[normalizedDate] == nil {
                groupedSamples[normalizedDate] = []
            }
            groupedSamples[normalizedDate]?.append(sample.quantity.doubleValue(for: measurementType == .steps ? HKUnit.count() : HKUnit(from: "count/min")))
        }
        
        // Convert the grouped data back to HKQuantitySample-like structures
        var aggregatedSamples: [HKQuantitySample] = []
        for (normalizedDate, values) in groupedSamples {
            let aggregatedValue: Double
            
            switch measurementType {
            case .steps:
                // Sum steps
                aggregatedValue = values.reduce(0, +)
            case .heartRate:
                // Average heart rate
                aggregatedValue = values.reduce(0, +) / Double(values.count)
            }
            
            let sample = HKQuantitySample(
                type: HKQuantityType.quantityType(forIdentifier: measurementType == .steps ? .stepCount : .heartRate)!,
                quantity: HKQuantity(unit: measurementType == .steps ? HKUnit.count() : HKUnit(from: "count/min"), doubleValue: aggregatedValue),
                start: normalizedDate,
                end: normalizedDate
            )
            aggregatedSamples.append(sample)
        }
        
        return aggregatedSamples.sorted { $0.startDate < $1.startDate }
    }
}

//
//  HealthKitService.swift
//  iOS
//
//  Created by Grigor Dochev on 29.07.2024.
//

import Foundation
import HealthKit

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
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void)
    func fetchHeartRateData(for period: Period, completion: @escaping @Sendable (Result<[HKQuantitySample], Error>) -> Void)
}

// MARK: - HealthKitService

class HealthKitService: HealthKitServiceProtocol,  @unchecked Sendable {
    static let shared = HealthKitService()
    private var healthStore: HKHealthStore?

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        }
    }

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(false, NSError(domain: "HealthKitService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Heart rate type is unavailable."]))
            return
        }

        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [heartRateType]

        healthStore?.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }

    func fetchHeartRateData(for period: Period, completion: @escaping @Sendable (Result<[HKQuantitySample], Error>) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(.failure(NSError(domain: "HealthKitService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Heart rate type is unavailable."])))
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: period.startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, results, error in
            if let error = error {
                Task { @MainActor in
                    completion(.failure(error))
                }
                return
            }

            guard let samples = results as? [HKQuantitySample] else {
                Task { @MainActor in
                    completion(.failure(NSError(domain: "HealthKitService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch heart rate samples."])))
                }
                return
            }

            completion(.success(samples))
        }

        healthStore?.execute(query)
    }
}

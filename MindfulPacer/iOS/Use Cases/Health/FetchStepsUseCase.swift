//
//  FetchStepsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 20.09.2024.
//

import Foundation
import HealthKit

protocol FetchStepsUseCase {
    func execute(for period: Period, endDate: Date, completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void)
    func executeBucketed(for period: Period, endDate: Date, completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void)
    func executeHistory(for period: Period, startDate: Date, endDate: Date,
                        completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void)

}

// MARK: - Use Case Implementation

final class DefaultFetchStepsUseCase: FetchStepsUseCase {
    private let healthKitService: HealthKitServiceProtocol
    
    init(healthKitService: HealthKitServiceProtocol = HealthKitService.shared) {
        self.healthKitService = healthKitService
    }
    
    func execute(
        for period: Period,
        endDate: Date,
        completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void
    ) {
        healthKitService.fetchCumulativeStepData(for: period, endDate: endDate) { result in
            switch result {
            case .success(let samples):
                let chartData = samples.map { sample in
                    ChartDataItem(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        value: sample.quantity.doubleValue(for: HKUnit.count())
                    )
                }
                completion(.success(chartData))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func executeBucketed(
        for period: Period,
        endDate: Date,
        completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void
    ) {
        healthKitService.fetchMeasurementData(for: period, measurementType: .steps, endDate: endDate) { result in
            switch result {
            case .success(let samples):
                let chartData = samples.map { sample in
                    ChartDataItem(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        value: sample.quantity.doubleValue(for: HKUnit.count())
                    )
                }
                completion(.success(chartData))
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    /// Keep raw totals so Analytics can accumulate steps from each visible window's start.
    func executeHistory(for period: Period, startDate: Date, endDate: Date,
                        completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        healthKitService.fetchMeasurementData(for: period == .week ? .week : .oneHour, measurementType: .steps,
                                             startDate: startDate, endDate: endDate) { result in
            completion(result.map { samples in
                samples.map { sample in
                    ChartDataItem(startDate: sample.startDate, endDate: min(sample.endDate, endDate),
                                  value: sample.quantity.doubleValue(for: .count()))
                }
            })
        }
    }

}

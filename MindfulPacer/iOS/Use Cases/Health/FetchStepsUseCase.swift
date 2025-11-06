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
}

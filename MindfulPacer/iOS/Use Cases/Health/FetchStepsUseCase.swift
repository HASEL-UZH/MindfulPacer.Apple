//
//  FetchStepsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 20.09.2024.
//

import Foundation
import HealthKit

protocol FetchStepsUseCase {
    func execute(for period: Period, completion: @escaping @Sendable (Result<[DateValueChartData], HealthKitError>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultFetchStepsUseCase: FetchStepsUseCase {
    private let healthKitService: HealthKitServiceProtocol
    
    init(healthKitService: HealthKitServiceProtocol = HealthKitService.shared) {
        self.healthKitService = healthKitService
    }
    
    func execute(for period: Period, completion: @escaping @Sendable (Result<[DateValueChartData], HealthKitError>) -> Void) {
        healthKitService.fetchMeasurementData(for: period, measurementType: .steps) { result in
            switch result {
            case .success(let samples):
                let chartData = samples.map { sample in
                    DateValueChartData(date: sample.startDate, value: sample.quantity.doubleValue(for: HKUnit(from: "count")))
                }
                completion(.success(chartData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

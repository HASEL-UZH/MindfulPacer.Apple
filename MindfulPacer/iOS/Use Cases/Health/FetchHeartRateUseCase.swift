//
//  FetchHeartRateUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 20.09.2024.
//

import Foundation
import HealthKit

protocol FetchHeartRateUseCase {
    func execute(for period: Period, completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultFetchHeartRateUseCase: FetchHeartRateUseCase {
    private let healthKitService: HealthKitServiceProtocol

    init(healthKitService: HealthKitServiceProtocol = HealthKitService.shared) {
        self.healthKitService = healthKitService
    }

    func execute(for period: Period, completion: @escaping @Sendable (Result<[ChartDataItem], HealthKitError>) -> Void) {
        healthKitService.fetchMeasurementData(for: period, measurementType: .heartRate) { result in
            switch result {
            case .success(let samples):
                let chartData = samples.map { sample in
                    ChartDataItem(date: sample.startDate, value: sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                }
                completion(.success(chartData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

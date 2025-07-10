//
//  FetchHeartRateDataLast24HoursUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 23.03.2025.
//

import Foundation

protocol FetchHeartRateDataLast24HoursUseCase {
    func execute(completion: @Sendable @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultFetchHeartRateDataLast24HoursUseCase: FetchHeartRateDataLast24HoursUseCase {
    private let healthKitService: HealthKitServiceProtocol

    init(healthKitService: HealthKitServiceProtocol = HealthKitService.shared) {
        self.healthKitService = healthKitService
    }

    func execute(completion: @Sendable @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void) {
        healthKitService.fetchHeartRateDataLast24Hours(completion: completion)
    }
}

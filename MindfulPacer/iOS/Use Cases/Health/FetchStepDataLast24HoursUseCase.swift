//
//  FetchStepDataLast24HoursUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 23.03.2025.
//

import Foundation

protocol FetchStepsDataLast24HoursUseCase {
    func execute(completion: @Sendable @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultFetchStepsDataLast24HoursUseCase: FetchStepsDataLast24HoursUseCase {
    private let healthKitService: HealthKitServiceProtocol

    init(healthKitService: HealthKitServiceProtocol = HealthKitService.shared) {
        self.healthKitService = healthKitService
    }

    func execute(completion: @Sendable @escaping ([(startDate: Date, endDate: Date, stepCount: Double)]) -> Void) {
        healthKitService.fetchStepDataLast24Hours(completion: completion)
    }
}

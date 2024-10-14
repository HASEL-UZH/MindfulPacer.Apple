//
//  FetchCurrentStepsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 01.09.2024.
//

import Foundation

protocol FetchCurrentStepsUseCase {
    func execute(completion: @escaping @Sendable (Result<(stepCount: Double, timestamp: Date), Error>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultFetchCurrentStepsUseCase: FetchCurrentStepsUseCase {
    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    func execute(completion: @escaping @Sendable (Result<(stepCount: Double, timestamp: Date), Error>) -> Void) {
        HealthKitService.shared.fetchCurrentMeasurement(for: .steps) { result in
            switch result {
            case .success(let stepCount):
                let timestamp = Date()
                completion(.success((stepCount: stepCount, timestamp: timestamp)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

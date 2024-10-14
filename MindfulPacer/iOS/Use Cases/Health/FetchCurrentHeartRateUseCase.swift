//
//  FetchCurrentHeartRateUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 01.10.2024.
//

import Foundation

protocol FetchCurrentHeartRateUseCase {
    func execute(completion: @escaping @Sendable (Result<(heartRate: Double, timestamp: Date), Error>) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultFetchCurrentHeartRateUseCase: FetchCurrentHeartRateUseCase {
    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    func execute(completion: @escaping @Sendable (Result<(heartRate: Double, timestamp: Date), Error>) -> Void) {
        HealthKitService.shared.fetchCurrentMeasurement(for: .heartRate) { result in
            switch result {
            case .success(let heartRate):
                let timestamp = Date()
                completion(.success((heartRate: heartRate, timestamp: timestamp)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

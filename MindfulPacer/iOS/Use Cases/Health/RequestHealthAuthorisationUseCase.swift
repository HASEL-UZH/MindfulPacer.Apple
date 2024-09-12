//
//  RequestHealthAuthorisationUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 11.09.2024.
//

import Foundation

protocol RequestHealthAuthorisationUseCase {
    func execute(completion: @escaping (Bool, HealthKitError?) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultRequestHealthAuthorisationUseCase: RequestHealthAuthorisationUseCase {
    private let healthKitService: HealthKitService

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    func execute(completion: @escaping (Bool, HealthKitError?) -> Void) {
        healthKitService.requestAuthorization(completion: completion)
    }
}

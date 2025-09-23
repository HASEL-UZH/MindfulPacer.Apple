//
//  CheckHealthPermissionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 09.09.2025.
//
import Foundation

protocol CheckHealthPermissionsUseCase {
    func execute(completion: @escaping @Sendable (HealthPermissionsState) -> Void)
}

// MARK: - Use Case Implementation

final class DefaultCheckHealthPermissionsUseCase: CheckHealthPermissionsUseCase {
    private let healthKitService: HealthKitService
    
    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }
    
    func execute(completion: @escaping @Sendable (HealthPermissionsState) -> Void) {
        healthKitService.checkPermissionsStatus(completion: completion)
    }
}

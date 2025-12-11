//
//  CheckHealthPermissionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 09.09.2025.
//
import Foundation

import Foundation

protocol CheckHealthPermissionsUseCase {
    func execute(
        deviceMode: DeviceMode,
        completion: @escaping @Sendable (HealthPermissionsState) -> Void
    )
}

// MARK: - Use Case Implementation

final class DefaultCheckHealthPermissionsUseCase: CheckHealthPermissionsUseCase {
    private let healthKitService: HealthKitService
    
    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }
    
    func execute(
        deviceMode: DeviceMode,
        completion: @escaping @Sendable (HealthPermissionsState) -> Void
    ) {
        healthKitService.checkPermissionsStatus(
            for: deviceMode,
            completion: completion
        )
    }
}

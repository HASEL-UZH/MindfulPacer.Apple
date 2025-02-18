//
//  CheckMissedReflectionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 03.01.2025.
//

import Foundation

protocol CheckMissedReflectionsUseCase {
    func execute(
        reminders: [Reminder],
        actionedMissedReflectionIDs: [String],
        completion: @escaping @Sendable (Result<[MissedReflection], HealthKitError>) -> Void
    )
}

// MARK: - Use Case Implementation

final class DefaultCheckMissedReflectionsUseCase: CheckMissedReflectionsUseCase {
    private let healthKitService: HealthKitService
    
    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }
    
    func execute(
        reminders: [Reminder],
        actionedMissedReflectionIDs: [String],
        completion: @escaping @Sendable (Result<[MissedReflection], HealthKitError>) -> Void
    ) {
        healthKitService.checkMissedReflections(
            reminders: reminders,
            actionedMissedReflectionIDs: actionedMissedReflectionIDs,
            completion: completion
        )
    }
}

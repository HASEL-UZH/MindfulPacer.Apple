//
//  FetchMissedReflectionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import Foundation
import SwiftData

protocol FetchMissedReflectionsUseCase {
    func execute(
        reminders: [Reminder],
        existingReflections: [Reflection],
        completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void
    )
    
    func execute(
        reminderConfigs: [BackgroundReminderConfig],
        existingReflections: [Reflection],
        completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void
    )
}

// MARK: - Use Case Implementation

final class DefaultFetchMissedReflectionsUseCase: FetchMissedReflectionsUseCase {
    private let healthKitService: HealthKitService
    
    init(
        healthKitService: HealthKitService
    ) {
        self.healthKitService = healthKitService
    }
    
    func execute(
        reminders: [Reminder],
        existingReflections: [Reflection],
        completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void
    ) {
        healthKitService.checkMissedReflections(
            reminders: reminders,
            existingReflections: existingReflections,
            isDeveloperMode: false,
            completion: completion
        )
    }
    
    func execute(
        reminderConfigs: [BackgroundReminderConfig],
        existingReflections: [Reflection],
        completion: @escaping @MainActor (Result<[Reflection], HealthKitError>) -> Void
    ) {
        let transientReminders: [Reminder] = reminderConfigs.map { cfg in
            Reminder(
                id: cfg.id,
                measurementType: cfg.measurementType,
                reminderType: cfg.reminderType,
                threshold: cfg.threshold,
                interval: cfg.interval
            )
        }
        
        healthKitService.checkMissedReflections(
            reminders: transientReminders,
            existingReflections: existingReflections,
            isDeveloperMode: false,
            completion: completion
        )
    }
}

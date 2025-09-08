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
}

// MARK: - Use Case Implementation

class DefaultFetchMissedReflectionsUseCase: FetchMissedReflectionsUseCase {
    private let modelContext: ModelContext
    private let healthKitService: HealthKitService
    
    init(
        modelContext: ModelContext,
        healthKitService: HealthKitService
    ) {
        self.modelContext = modelContext
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
}

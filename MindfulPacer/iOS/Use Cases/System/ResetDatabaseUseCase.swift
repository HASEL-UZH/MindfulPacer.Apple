//
//  ResetDatabaseUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 04.09.2025.
//

import Foundation
import SwiftData

@MainActor
protocol ResetDatabaseUseCase {
    func execute() async throws
}

// MARK: - Use Case Implementation

@MainActor
final class DefaultResetDatabaseUseCase: ResetDatabaseUseCase {
    private let context: ModelContext
    init(modelContext: ModelContext) { self.context = modelContext }

    func execute() async throws {
        try context.delete(model: Reflection.self)
        try context.delete(model: Subactivity.self)
        try context.delete(model: Activity.self)
        try context.delete(model: Reminder.self)
        try context.save()
    }
}

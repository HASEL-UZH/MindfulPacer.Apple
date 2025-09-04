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

    init(modelContext: ModelContext) {
        self.context = modelContext
    }

    func execute() async throws {
        try deleteAll(Reflection.self)
        try deleteAll(Subactivity.self)
        try deleteAll(Activity.self)
        try deleteAll(Reminder.self)
        try context.save()
    }

    private func deleteAll<T: PersistentModel>(_ type: T.Type, batchSize: Int = 200) throws {
        while true {
            var fd = FetchDescriptor<T>()
            fd.fetchLimit = batchSize
            let chunk = try context.fetch(fd)
            if chunk.isEmpty { break }
            for object in chunk { context.delete(object) }
            try context.save()
        }
    }
}

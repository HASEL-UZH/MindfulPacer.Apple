//
//  SchemaV1.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 21.07.2024.
//

import SwiftData
import SwiftUI

// MARK: - Schema1

typealias CurrentScheme = SchemaV1

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Review.self,
            Category.self,
            Subcategory.self,
            ReviewReminder.self
        ]
    }
}

// MARK: - Container

extension ModelContainer {
    /// Container used in production

    static let prod: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            // FIXME: Performing I/O on the main thread can cause slow launches.
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("DEBUG: Failed to initialize ModelContainer.")
        }
    }()

    /// Container used for previews
    @MainActor
    static let preview: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("DEBUG: Failed to initialize ModelContainer.")
        }
    }()
}

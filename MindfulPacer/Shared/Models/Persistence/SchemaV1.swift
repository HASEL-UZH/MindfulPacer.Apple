//
//  SchemaV1.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 21.07.2024.
//

import SwiftData
import SwiftUI
import Foundation

// MARK: - Schema1

typealias CurrentScheme = SchemaV1

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        [
            Reflection.self,
            Activity.self,
            Subactivity.self,
            Reminder.self
        ]
    }
}

// MARK: - Container

extension ModelContainer {
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

// MARK: - Production Container

@MainActor
extension ModelContainer {
    static let prod: ModelContainer = {
        let schema = Schema(CurrentScheme.models)

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.Cloud.com.MindfulPacer.Apple.iOS")
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }()
}

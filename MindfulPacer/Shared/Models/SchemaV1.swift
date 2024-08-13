//
//  SchemaV1.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 21.07.2024.
//

import SwiftData

typealias CurrentScheme = SchemaV1

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        .init(1, 0, 0)
    }
    
    static var models: [any PersistentModel.Type] {
        [HeartRateSample.self, Review.self, Category.self, Subcategory.self]
    }
}

// MARK: - Container

extension ModelContainer {
    @MainActor
    static let prod: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("DEBUG: Failed to initialize ModelContainer.")
        }
    }()
    
    @MainActor
    static let preview: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // TODO: Only add categories if it's empty!!
        
//        let categories: [Category] = [
//            Category(name: "Movement", icon: "figure.run", subcategories: []),
//            Category(name: "Household", icon: "house"),
//            Category(name: "Self-Care", icon: "shower"),
//            Category(name: "Interaction", icon: "bubble.left.and.text.bubble.right"),
//            Category(name: "Alarms", icon: "alarm"),
//            Category(name: "Others", icon: "puzzlepiece")
//        ]
//        
//        categories.forEach { container.mainContext.insert($0) }
//        try! container.mainContext.save()
        
        return container
    }()
}

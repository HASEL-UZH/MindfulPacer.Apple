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
            HeartRateSample.self,
            Review.self,
            Category.self,
            Subcategory.self,
            ReviewReminder.self
        ]
    }
}

// MARK: - Container

extension ModelContainer {
    @MainActor
    /// Container used in production
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
    /// Container used to provide data for the Previews
    static let preview: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
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

// MARK: - Preview

struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Category.self, configurations: config)
        
        let categories: [Category] = [
            Category(name: "Movement", icon: "figure.run", subcategories: []),
            Category(name: "Household", icon: "house"),
            Category(name: "Self-Care", icon: "shower"),
            Category(name: "Interaction", icon: "bubble.left.and.text.bubble.right"),
            Category(name: "Alarms", icon: "alarm"),
            Category(name: "Others", icon: "puzzlepiece")
        ]
        
        categories.forEach { container.mainContext.insert($0) }
        try container.mainContext.save()
        
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
        content.modelContainer(context)
    }
}

extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleData: Self = .modifier(SampleData())
}

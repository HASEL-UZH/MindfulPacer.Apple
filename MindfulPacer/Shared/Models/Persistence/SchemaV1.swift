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
    @MainActor
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
    
    /// Container used to provide data for the Previews
    @MainActor
    static let preview: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        
        let fetchDescriptor = FetchDescriptor<Category>()
        
        do {
            let categories = try container.mainContext.fetch(fetchDescriptor)
            if categories.isEmpty {
                DefaultCategoryData.initializeData()

                for category in DefaultCategoryData.categories {
                    container.mainContext.insert(category)
                    
                    if let subcategories = category.subcategories {
                        for subcategory in subcategories {
                            container.mainContext.insert(subcategory)
                        }
                    }
                }
            }
        } catch {
            
        }
        
        return container
    }()
    
    @MainActor
    static let testing: ModelContainer = {
        let schema = Schema(CurrentScheme.models)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
        
        let fetchDescriptor = FetchDescriptor<Category>()
        
        do {
            let categoriesCount = try container.mainContext.fetch(fetchDescriptor).count
            
            if categoriesCount == 0 {
                let categories: [Category] = [
                    Category(name: "Movement", icon: "figure.run", subcategories: []),
                    Category(name: "Household", icon: "house"),
                    Category(name: "Self-Care", icon: "shower"),
                    Category(name: "Interaction", icon: "bubble.left.and.text.bubble.right"),
                    Category(name: "Alarms", icon: "alarm"),
                    Category(name: "Others", icon: "puzzlepiece")
                ]
                
                categories.forEach { container.mainContext.insert($0) }
                try! container.mainContext.save()
            }
        } catch {
            
        }
        
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

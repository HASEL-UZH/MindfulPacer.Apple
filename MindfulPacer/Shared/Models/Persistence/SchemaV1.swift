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
            //            DefaultCategoryData.initializeData()
//
//            for category in DefaultCategoryData.categories {
//                preview.mainContext.insert(category)
//
//                if let subcategories = category.subcategories {
//                    for subcategory in subcategories {
//                        preview.mainContext.insert(subcategory)
//                    }
//                }
//            }
//
//            do {
//                try preview.mainContext.save()
//            } catch {
//                print("Error saving default categories: \(error)")
//            }
//
//            let review = Review(
//                date: .now,
////                category: DefaultCategoryData.categories[0],
////                subcategory: DefaultCategoryData.categories[0].subcategories![0],
//                mood: "😭",
//                perceivedEnergyLevelRating: 2,
//                headachesRating: 1,
//                shortnessOfBreatheRating: 1,
//                feverRating: 0,
//                painsAndNeedlesRating: 3,
//                muscleAchesRating: 2,
//                additionalInformation: "This was super tiring!"
//            )
//
//            preview.mainContext.insert(review)

            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("DEBUG: Failed to initialize ModelContainer.")
        }
    }()
}

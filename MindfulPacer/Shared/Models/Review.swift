//
//  Review.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 08.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

typealias Review = SchemaV1.Review
typealias Category = SchemaV1.Category
typealias Subcategory = SchemaV1.Subcategory

// MARK: - Schema

extension SchemaV1 {
    @Model
    final class Review {
        var id: UUID = UUID()
        var category: Category?
        var subcategory: Subcategory?
        var mood: String? = ""
        var didTriggerCrash: Bool?
        var perceivedEnergyLevelRating: Int?
        var headachesRating: Int?
        var shortnessOfBreatheRating: Int?
        var feverRating: Int?
        var painsAndNeedlesRating: Int?
        var muscleAchesRating: Int?
        var additionalInformation: String?
        
        init(
            id: UUID = UUID(),
            category: Category? = nil,
            subcategory: Subcategory? = nil,
            mood: String? = "",
            didTriggerCrash: Bool? = false,
            perceivedEnergyLevelRating: Int? = 0,
            headachesRating: Int? = 0,
            shortnessOfBreatheRating: Int? = 0,
            feverRating: Int? = 0,
            painsAndNeedlesRating: Int? = 0,
            muscleAchesRating: Int? = 0,
            additionalInformation: String? = ""
        ) {
            self.id = id
            self.category = category
            self.subcategory = subcategory
            self.mood = mood
            self.didTriggerCrash = didTriggerCrash
            self.perceivedEnergyLevelRating = perceivedEnergyLevelRating
            self.headachesRating = headachesRating
            self.shortnessOfBreatheRating = shortnessOfBreatheRating
            self.feverRating = feverRating
            self.painsAndNeedlesRating = painsAndNeedlesRating
            self.muscleAchesRating = muscleAchesRating
            self.additionalInformation = additionalInformation
        }
    }
}

// MARK: - Category

extension SchemaV1 {
    @Model
    final class Category {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        @Relationship(inverse: \Subcategory.category) var subcategories: [Subcategory]?
        var review: Review?
        
        init(
            id: UUID = UUID(),
            name: String = "",
            icon: String = "",
            subcategories: [Subcategory] = [],
            review: Review? = nil
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.subcategories = subcategories
            self.review = review
        }
    }
}

// MARK: - Subcategory

extension SchemaV1 {
    @Model
    final class Subcategory {
        var id: UUID = UUID()
        var name: String = ""
        var icon: String = ""
        var category: Category?
        var review: Review?
        
        init(
            id: UUID,
            name: String = "",
            icon: String = "",
            category: Category? = nil,
            review: Review? = nil
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.category = category
            self.review = review
        }
    }
}

// MARK: - Previews

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

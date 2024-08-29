//
//  Previewer.swift
//  iOS
//
//  Created by Grigor Dochev on 29.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
struct Previewer {
    let container: ModelContainer
    let review: Review
    
    init() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: Category.self, Subcategory.self, Review.self, ReviewReminder.self, configurations: config)
                
        DefaultCategoryData.initializeData()

        for category in DefaultCategoryData.categories {
            container.mainContext.insert(category)
            
            if let subcategories = category.subcategories {
                for subcategory in subcategories {
                    container.mainContext.insert(subcategory)
                }
            }
        }
        
        do {
            try container.mainContext.save()
        } catch {
            print("Error saving default categories: \(error)")
        }
        
        review = Review(
            date: .now,
            category: DefaultCategoryData.categories[0],
            subcategory: DefaultCategoryData.categories[0].subcategories![0],
            mood: "😭",
            perceivedEnergyLevelRating: 2,
            headachesRating: 1,
            shortnessOfBreatheRating: 1,
            feverRating: 0,
            painsAndNeedlesRating: 3,
            muscleAchesRating: 2,
            additionalInformation: "This was super tiring!"
        )
        
        container.mainContext.insert(review)
    }
}

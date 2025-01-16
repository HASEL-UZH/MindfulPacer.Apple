//
//  AddDefaultCategoriesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 08.08.2024.
//

import Foundation
import SwiftData

protocol AddDefaultCategoriesUseCase {
    func execute() async
}

// MARK: - Use Case Implementation

class DefaultAddDefaultCategoriesUseCase: AddDefaultCategoriesUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // TODO: Categories seem to be duplicated, must not be fetching from CloudKit fast enough
    /*
     Potential solution:
     - Add a timestamp property to each Activity which will reflect exactly when it was added
     - On each app launch check if there are duplicate categories and only keep the activity with the earliest timestamp
     - Before doing that, make sure to update all reviews that may referece a newer duplicate activity to now reference the oldest one
     */
    func execute() async {
        if await categoriesExist() {
            return
        }

        await addDefaultCategories()
    }

    private func categoriesExist() async -> Bool {
        do {
            let descriptor = FetchDescriptor<Activity>()
            let categories = try modelContext.fetch(descriptor)
            return !categories.isEmpty
        } catch {
            print("DEBUG: Fetch failed")
            return false
        }
    }

    @MainActor
    private func addDefaultCategories() async {
        DefaultActivityData.initializeData()

        for activity in DefaultActivityData.activities {
            modelContext.insert(activity)

            if let subcategories = activity.subactivities {
                for subactivity in subcategories {
                    modelContext.insert(subactivity)
                }
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving default categories: \(error)")
        }
    }
}

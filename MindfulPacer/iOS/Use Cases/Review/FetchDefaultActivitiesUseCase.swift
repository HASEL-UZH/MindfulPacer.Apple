//
//  FetchDefaultCategoriesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 13.08.2024.
//

import Foundation
import SwiftData

protocol FetchDefaultActivitiesUseCase {
    func execute() -> [Activity]?
}

// MARK: - Use Case Implementation

class DefaultFetchDefaultActivitiesUseCase: FetchDefaultActivitiesUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute() -> [Activity]? {
        do {
            let descriptor = FetchDescriptor<Activity>(sortBy: [SortDescriptor(\.name)])
            let categories = try modelContext.fetch(descriptor)
            return categories
        } catch {
            print("DEBUG: Fetch failed")
            return nil
        }
    }
}

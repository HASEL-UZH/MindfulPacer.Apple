//
//  FetchDefaultCategoriesUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 13.08.2024.
//

import Foundation
import SwiftData

protocol FetchDefaultCategoriesUseCase {
    func execute() -> [Category]?
}

// MARK: - Use Case Implementation

class DefaultFetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute() -> [Category]? {
        do {
            let descriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.name)])
            let categories = try modelContext.fetch(descriptor)
            return categories
        } catch {
            print("DEBUG: Fetch failed")
            return nil
        }
    }
}

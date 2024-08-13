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
    
    func execute() async {
        if await categoriesExist() {
            return
        }
        
        await addDefaultCategories()
    }
    
    private func categoriesExist() async -> Bool {
        
        do {
            let descriptor = FetchDescriptor<Category>()
            let categories = try modelContext.fetch(descriptor)
            return !categories.isEmpty
        } catch {
            print("DEBUG: Fetch failed")
            return false
        }
    }
    
    private func addDefaultCategories() async {
//        await Category.defaultCategories.forEach { category in
//            
//        }
        
//        for category in Category.defaultCategories {
//            modelContext.insert(category)
//        }
//        
//        do {
//            try modelContext.save()
//        } catch {
//            print("Error saving default categories: \(error)")
//        }
    }
}

//
//  CreateReviewViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class CreateReviewViewModel {
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase

    // MARK: - Published Properties (State)

    var categories: [Category] = []
    var selectedCategory: Category? = nil
    var selectedSubcategory: Subcategory? = nil
    var navigationPath = NavigationPath()

    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase
    ) {
        self.modelContext = modelContext
        self.fetchDefaultCategoriesUseCase = fetchDefaultCategoriesUseCase
    }

    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        if let fetchedCategories = fetchDefaultCategoriesUseCase.execute() {
            categories = fetchedCategories
        }
    }

    // MARK: - User Actions
    
    func selectCategory(_ category: Category) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
        }
        navigationPath.removeLast()
    }

    // MARK: - Private Methods
    
    private func somePrivateHelperMethod() {
        // Any private methods to support the ViewModel's logic
    }

    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        // Handle errors that occur within the ViewModel
    }
}

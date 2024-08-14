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
    
    var navigationPath = NavigationPath()
    var isRatingSheetPresented: Bool = false
    var currentRatingType: ReviewMetricRatingType? = nil
    
    var categories: [Category] = []
    var moods: [String] = ["😁", "😭", "😓", "😡", "😴", "😆", "🥳", "🤢", "🤧"]
    
    var selectedCategory: Category? = nil
    var selectedMood: String? = nil
    var selectedSubcategory: Subcategory? = nil
    var didTriggerCrash: Bool = false
    var additionalInformation: String = ""    
    
    var ratings: [ReviewMetricRating] = [
        ReviewMetricRating(type: .headaches),
        ReviewMetricRating(type: .energyLevel),
        ReviewMetricRating(type: .shortnessOfBreath),
        ReviewMetricRating(type: .fever),
        ReviewMetricRating(type: .painsAndNeedles),
        ReviewMetricRating(type: .muscleAches)
    ]
    
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
            navigationPath.removeLast()
        }
    }
    
    func selectMood(_ mood: String) {
        if selectedMood == mood {
            selectedMood = nil
        } else {
            selectedMood = mood
            navigationPath.removeLast()
        }
    }
    
    func updateRating(for type: ReviewMetricRatingType, with value: Int?) {
        if let index = ratings.firstIndex(where: { $0.type == type }) {
            if ratings[index].value == value {
                ratings[index].value = nil
                isRatingSheetPresented = true
            } else {
                ratings[index].value = value
                isRatingSheetPresented = false
            }
        }
    }
    
    func showRatingSheet(for type: ReviewMetricRatingType) {
        currentRatingType = type
        isRatingSheetPresented = true
    }
    
    func createReview() {
        
    }
    
    // MARK: - Private Methods
    
    // MARK: - Error Handling
    
}

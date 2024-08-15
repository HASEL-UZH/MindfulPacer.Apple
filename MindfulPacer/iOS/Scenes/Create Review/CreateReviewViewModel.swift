//
//  CreateReviewViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class CreateReviewViewModel {
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let createReviewUseCase: CreateReviewUseCase
    private let fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase
    
    // MARK: - Published Properties (State)
    
    var navigationPath = NavigationPath()
    var isRatingSheetPresented: Bool = false
    var currentRatingType: ReviewMetricRatingType? = nil
    var alertItem: AlertItem? = nil
    
    var categories: [Category] = []
    var moods: [String] = ["😁", "😭", "😓", "😡", "😴", "😆", "🥳", "🤢", "🤧", "😤"]
    
    var date: Date = .now
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
        createReviewUseCase: CreateReviewUseCase,
        fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase
    ) {
        self.modelContext = modelContext
        self.createReviewUseCase = createReviewUseCase
        self.fetchDefaultCategoriesUseCase = fetchDefaultCategoriesUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchDefaultCategories()
    }
    
    // MARK: - User Actions
    
    func toggleCategorySelection(_ category: Category) {
        if selectedCategory == category {
            selectedCategory = nil
        } else {
            selectedCategory = category
            navigationPath.removeLast()
        }
    }
    
    func toggleMoodSelection(_ mood: String) {
        if selectedMood == mood {
            selectedMood = nil
        } else {
            selectedMood = mood
            navigationPath.removeLast()
        }
    }
    
    func setRating(for type: ReviewMetricRatingType, with value: Int?) {
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
    
    func presentRatingSheet(for type: ReviewMetricRatingType) {
        currentRatingType = type
        isRatingSheetPresented = true
    }
    
    func saveReview() {
        let result = createReviewUseCase.execute(
            date: date,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            didTriggerCrash: didTriggerCrash,
            perceivedEnergyLevelRating: ratings[.energyLevel]?.value,
            headachesRating: ratings[.headaches]?.value,
            shortnessOfBreatheRating: ratings[.shortnessOfBreath]?.value,
            feverRating: ratings[.fever]?.value,
            painsAndNeedlesRating: ratings[.painsAndNeedles]?.value,
            muscleAchesRating: ratings[.muscleAches]?.value,
            additionalInformation: additionalInformation
        )
        
        if case .failure(_) = result {
            alertItem = AlertContext.unableToSaveReview
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchDefaultCategories() {
        if let fetchedCategories = fetchDefaultCategoriesUseCase.execute() {
            categories = fetchedCategories
        }
    }
        
    // MARK: - Error Handling
}

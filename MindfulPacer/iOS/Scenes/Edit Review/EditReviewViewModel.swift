//
//  EditReviewViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 06.08.2024.
//

import Foundation
import SwiftData

// MARK: - EditReviewViewModel

@MainActor
@Observable
class EditReviewViewModel {
    enum Mode { case create, edit }

    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let createReviewUseCase: CreateReviewUseCase
    private let deleteReviewUseCase: DeleteReviewUseCase
    private let fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase
    private let saveReviewUseCase: SaveReviewUseCase

    // MARK: - Published Properties (State)

    var mode: Mode = .create
    var navigationPath: [EditReviewNavigationDestination] = []
    var activeSheet: EditReviewSheet?
    var activeAlert: EditReviewAlert?

    var categories: [Category] = []

    var navigationTitle: String {
        switch mode {
        case .create:
            return "Create Review"
        case .edit:
            return "Edit Review"
        }
    }
        
    var date: Date = .now
    var selectedCategory: Category? {
        didSet {
            selectedSubcategory = nil
        }
    }
    var selectedMood: Mood?
    var selectedSubcategory: Subcategory?
    var wellBeing = Symptom.wellBeing(nil)
    var fatigue = Symptom.fatigue(nil)
    var shortnessOfBreath = Symptom.shortnessOfBreath(nil)
    var sleepDisorder = Symptom.sleepDisorder(nil)
    var cognitiveImpairment = Symptom.cognitiveImpairment(nil)
    var physicalPain = Symptom.physicalPain(nil)
    var depressionOrAnxiety = Symptom.depressionOrAnxiety(nil)
    var didTriggerCrash: Bool = false
    var additionalInformation: String = ""

    var isActionButtonDisabled: Bool {
        let disabled = selectedCategory == nil
        return disabled
    }

    var isSaveButtonDisabled: Bool {
        let disabled = selectedCategory == nil
        return disabled
    }

    var isReviewDeleted = false

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        createReviewUseCase: CreateReviewUseCase,
        deleteReviewUseCase: DeleteReviewUseCase,
        fetchDefaultCategoriesUseCase: FetchDefaultCategoriesUseCase,
        saveReviewUseCase: SaveReviewUseCase
    ) {
        self.modelContext = modelContext
        self.createReviewUseCase = createReviewUseCase
        self.deleteReviewUseCase = deleteReviewUseCase
        self.fetchDefaultCategoriesUseCase = fetchDefaultCategoriesUseCase
        self.saveReviewUseCase = saveReviewUseCase
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear() {
        fetchDefaultCategories()
    }

    func configureMode(with review: Review?) {
        if let review {
            mode = .edit
            loadReview(review)
        }
    }

    // MARK: - User Actions

    func toggleSelection<T: Equatable>(_ item: T, selectedItem: inout T?) {
        if selectedItem == item {
            selectedItem = nil
        } else {
            selectedItem = item
            if !ProcessInfo.processInfo.isRunningInPreviewOrTest {
                navigationPath.removeLast()
            }
        }
    }
    
    func setSymptomValue(for symptom: Symptom, with value: Int?) {
        switch symptom {
        case .wellBeing: wellBeing.setValue(value)
        case .fatigue: fatigue.setValue(value)
        case .shortnessOfBreath: shortnessOfBreath.setValue(value)
        case .sleepDisorder: sleepDisorder.setValue(value)
        case .cognitiveImpairment: cognitiveImpairment.setValue(value)
        case .physicalPain: physicalPain.setValue(value)
        case .depressionOrAnxiety: depressionOrAnxiety.setValue(value)
        }
    }
    
    func createReview() {
        let result = createReviewUseCase.execute(
            date: date,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            mood: selectedMood,
            didTriggerCrash: didTriggerCrash,
            wellBeing: wellBeing,
            fatigue: fatigue,
            shortnessOfBreath: shortnessOfBreath,
            sleepDisorder: sleepDisorder,
            cognitiveImpairment: cognitiveImpairment,
            physicalPain: physicalPain,
            depressionOrAnxiety: depressionOrAnxiety,
            additionalInformation: additionalInformation,
            measurementType: nil,
            reviewReminderType: nil,
            threshold: nil,
            interval: nil
        )

        if case .failure = result {
            presentAlert(.unableToSaveReview)
        }
    }

    func saveReview(_ review: Review?) {
        let result = saveReviewUseCase.execute(
            existingReview: review.unsafelyUnwrapped,
            newDate: date,
            newCategory: selectedCategory,
            newSubcategory: selectedSubcategory,
            newMood: selectedMood,
            newDidTriggerCrash: didTriggerCrash,
            newWellBeing: wellBeing,
            newFatigue: fatigue,
            newShortnessOfBreath: shortnessOfBreath,
            newSleepDisorder: sleepDisorder,
            newCognitiveImpairment: cognitiveImpairment,
            newPhysicalPain: physicalPain,
            newDepressionOrAnxiety: depressionOrAnxiety,
            newAdditionalInformation: additionalInformation
        )
        
        if case .failure = result {
            presentAlert(.unableToSaveReview)
        }
    }

    func deleteReview(_ review: Review?) {
        isReviewDeleted = true
        guard let review else {
            return
        }
        deleteReviewUseCase.execute(review: review)
    }
    
    func reviewReminderTriggerSummary(for review: Review) -> String {
        guard let reviewReminderMeasurementType = review.measurementType,
              let reviewReminderInterval = review.interval,
              let reviewReminderThreshold = review.threshold else { return "No summary" }
        
        switch reviewReminderMeasurementType {
        case .heartRate:
            return "Above \(reviewReminderThreshold) bpm for \(reviewReminderInterval.rawValue.lowercased())"
        case .steps:
            return "Above \(reviewReminderThreshold) steps within the window of \(reviewReminderInterval.rawValue.lowercased())"
        }
    }
    
    // MARK: - Presentation
    
    func navigateTo(destination: EditReviewNavigationDestination) {
        navigationPath.append(destination)
    }

    func presentSymptomValueSheet(for symptom: Symptom) {
        presentSheet(.symptomValueView(symptom))
    }

    func presentSheet(_ sheet: EditReviewSheet) {
        activeSheet = sheet
    }

    func dismissSheet(_ sheet: EditReviewSheet) {
        activeSheet = nil
    }

    func presentAlert(_ alert: EditReviewAlert) {
        activeAlert = alert
    }

    // MARK: - Private Methods

    private func fetchDefaultCategories() {
        if let fetchedCategories = fetchDefaultCategoriesUseCase.execute() {
            categories = fetchedCategories
        }
    }

    private func loadReview(_ review: Review) {
        date = review.date
        selectedCategory = review.category
        selectedSubcategory = review.subcategory
        selectedMood = review.mood
        wellBeing.setValue(review.wellBeing?.value)
        fatigue.setValue(review.fatigue?.value)
        shortnessOfBreath.setValue(review.shortnessOfBreath?.value)
        sleepDisorder.setValue(review.sleepDisorder?.value)
        cognitiveImpairment.setValue(review.cognitiveImpairment?.value)
        physicalPain.setValue(review.physicalPain?.value)
        depressionOrAnxiety.setValue(review.depressionOrAnxiety?.value)
        didTriggerCrash = review.didTriggerCrash
        additionalInformation = review.additionalInformation
    }
}

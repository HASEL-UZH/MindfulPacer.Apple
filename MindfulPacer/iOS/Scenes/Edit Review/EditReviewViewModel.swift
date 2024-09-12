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

    var currentRatingType: ReviewMetricRatingType?
    var categories: [Category] = []

    var navigationTitle: String {
        switch mode {
        case .create:
            "Create Review"
        case .edit:
            "Edit Review"
        }
    }

    var date: Date = .now
    var selectedCategory: Category? {
        didSet { selectedSubcategory = nil }
    }
    var selectedMood: Mood?
    var selectedSubcategory: Subcategory?
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

    var isActionButtonDisabled: Bool {
        selectedCategory == nil
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

    func setRating(for type: ReviewMetricRatingType, with value: Int?) {
        if let index = ratings.firstIndex(where: { $0.type == type }) {
            if ratings[index].value == value {
                ratings[index].value = nil
                presentSheet(.ratingSheet)
            } else {
                ratings[index].value = value
                dismissSheet(.ratingSheet)
            }
        }
    }

    func createReview() {
        let result = createReviewUseCase.execute(
            date: date,
            category: selectedCategory,
            subcategory: selectedSubcategory,
            mood: selectedMood?.emoji,
            didTriggerCrash: didTriggerCrash,
            perceivedEnergyLevelRating: ratings[.energyLevel]?.value,
            headachesRating: ratings[.headaches]?.value,
            shortnessOfBreatheRating: ratings[.shortnessOfBreath]?.value,
            feverRating: ratings[.fever]?.value,
            painsAndNeedlesRating: ratings[.painsAndNeedles]?.value,
            muscleAchesRating: ratings[.muscleAches]?.value,
            additionalInformation: additionalInformation
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
            newMood: selectedMood?.emoji,
            newDidTriggerCrash: didTriggerCrash,
            newPerceivedEnergyLevelRating: ratings[1].value,
            newHeadachesRating: ratings[0].value,
            newShortnessOfBreatheRating: ratings[2].value,
            newFeverRating: ratings[3].value,
            newPainsAndNeedlesRating: ratings[4].value,
            newMuscleAchesRating: ratings[5].value,
            newAdditionalInformation: additionalInformation
        )

        if case .failure = result {
            presentAlert(.unableToSaveReview)
        }
    }

    func deleteReview(_ review: Review?) {
        /// Fix for crash that occurs when you try to access reviewReminder property when the review is deleted
        isReviewDeleted = true
        guard let review else { return }
        deleteReviewUseCase.execute(review: review)
    }

    // MARK: - Presentation

    func navigateTo(destination: EditReviewNavigationDestination) {
        navigationPath.append(destination)
    }

    func presentRatingSheet(for type: ReviewMetricRatingType) {
        currentRatingType = type
        presentSheet(.ratingSheet)
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
        selectedMood = Mood.mood(for: review.mood)
        ratings[0] = ReviewMetricRating(type: .headaches, value: review.headachesRating)
        ratings[1] = ReviewMetricRating(type: .energyLevel, value: review.perceivedEnergyLevelRating)
        ratings[2] = ReviewMetricRating(type: .shortnessOfBreath, value: review.shortnessOfBreatheRating)
        ratings[3] = ReviewMetricRating(type: .fever, value: review.feverRating)
        ratings[4] = ReviewMetricRating(type: .painsAndNeedles, value: review.painsAndNeedlesRating)
        ratings[5] = ReviewMetricRating(type: .muscleAches, value: review.muscleAchesRating)
        didTriggerCrash = review.didTriggerCrash
        additionalInformation = review.additionalInformation
    }
}

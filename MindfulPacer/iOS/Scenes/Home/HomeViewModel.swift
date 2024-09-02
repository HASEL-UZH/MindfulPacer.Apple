//
//  HomeViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class HomeViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let deleteReviewUseCase: DeleteReviewUseCase
    private let fetchCurrentStepsUseCase: FetchCurrentStepsUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    
    // MARK: - Published Properties (State)
    
    var activeSheet: HomeViewSheet? = nil
    
    var reviews: [Review] = []
    var reviewReminders: [ReviewReminder] = []
    var recentReviews: [Review] {
        Array(reviews.prefix(3))
    }
    var recentReviewReminders: [ReviewReminder] {
        Array(reviewReminders.prefix(3))
    }
    var currentSteps: (stepCount: Double, timestamp: Date)? = nil
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        deleteReviewUseCase: DeleteReviewUseCase,
        fetchCurrentStepsUseCase: FetchCurrentStepsUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    ) {
        self.modelContext = modelContext
        self.deleteReviewUseCase = deleteReviewUseCase
        self.fetchCurrentStepsUseCase = fetchCurrentStepsUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchCurrentSteps()
        fetchReviews()
        fetchReviewReminders()
    }
    
    func onSheetDismissed() {
        fetchReviews()
        fetchReviewReminders()
    }
    
    // MARK: - User Actions
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: HomeViewSheet) {
        activeSheet = sheet
    }
    
    // MARK: - Private Methods
    
    private func fetchCurrentSteps() {
        fetchCurrentStepsUseCase.execute { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let success):
                    self.currentSteps = success
                case .failure(let failure):
                    print("DEBUG: Could not fetch current steps: \(failure)")
                }
            }
        }
    }
    
    private func fetchReviews() {
        reviews = fetchReviewsUseCase.execute() ?? []
    }
    
    private func fetchReviewReminders() {
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
    }
}

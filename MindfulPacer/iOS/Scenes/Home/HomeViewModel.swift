//
//  HomeViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class HomeViewModel {
    
    // MARK: - Dependencies
    
    private let deleteReviewUseCase: DeleteReviewUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    private let modelContext: ModelContext
    
    // MARK: - Published Properties (State)
    
    var activeSheet: HomeViewSheet? = nil
    
    var reviews: [Review] = []
    var reviewReminders: [ReviewReminder] = []
    
    // MARK: - Initialization
    
    init(
        deleteReviewUseCase: DeleteReviewUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase,
        modelContext: ModelContext
    ) {
        self.deleteReviewUseCase = deleteReviewUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
        self.modelContext = modelContext
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
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
    
    private func fetchReviews() {
        reviews = fetchReviewsUseCase.execute() ?? []
    }
    
    private func fetchReviewReminders() {
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
    }
}

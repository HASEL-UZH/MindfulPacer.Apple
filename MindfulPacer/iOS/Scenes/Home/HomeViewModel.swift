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
    
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    private let modelContext: ModelContext
    
    // MARK: - Published Properties (State)
    
    var navigationPath: [HomeViewNavigationDestination] = []
    var activeSheet: HomeViewSheet? = nil
    var alertItem: AlertItem? = nil
    
    var reviews: [Review] = []
    var reviewReminders: [ReviewReminder] = []
    
    // MARK: - Initialization
    
    init(
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase,
        modelContext: ModelContext
    ) {
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
        self.modelContext = modelContext
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        fetchReviews()
        fetchReviewReminders()
    }
    
    // MARK: - User Actions
    
    func presentSheet(_ sheet: HomeViewSheet) {
        activeSheet = sheet
    }
    
    func updateReviews(with reviews: [Review]) {
        self.reviews = reviews
    }
    
    // MARK: - Private Methods
    
    private func fetchReviews() {
        reviews = fetchReviewsUseCase.execute() ?? []
    }
    
    private func fetchReviewReminders() {
        reviewReminders = fetchReviewRemindersUseCase.execute() ?? []
    }
}

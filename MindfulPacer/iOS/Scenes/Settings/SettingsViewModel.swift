//
//  SettingsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 13.09.2024.
//

import CocoaLumberjackSwift
import Foundation
import MessageUI

@Observable
class SettingsViewModel {
    
    // MARK: - Dependencies
    private let createReviewUseCase: CreateReviewUseCase
    private let fetchReviewsUseCase: FetchReviewsUseCase
    private let fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: SettingsSheet?
    
    var mailResult: Result<MFMailComposeResult, Error>?
    
    // MARK: - Initialization
    
    init(
        createReviewUseCase: CreateReviewUseCase,
        fetchReviewsUseCase: FetchReviewsUseCase,
        fetchReviewRemindersUseCase: FetchReviewRemindersUseCase
    ) {
        self.createReviewUseCase = createReviewUseCase
        self.fetchReviewsUseCase = fetchReviewsUseCase
        self.fetchReviewRemindersUseCase = fetchReviewRemindersUseCase
    }
    
    // MARK: - View Events
    
    func onViewAppear() {}
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: SettingsSheet) {
        DDLogInfo("Presenting sheet: \(sheet)")
        activeSheet = sheet
    }
    
    // MARK: - User Actions
    
    func manuallyCreateReviewWithReviewReminder() {
       guard let reviewReminders = fetchReviewRemindersUseCase.execute() else { return }
        
        _ = createReviewUseCase.execute(
            date: Date.now,
            category: nil,
            subcategory: nil,
            mood: Mood(emoji: "😭", text: "Crying"),
            didTriggerCrash: false,
            perceivedEnergyLevelRating: nil,
            headachesRating: nil,
            shortnessOfBreatheRating: nil,
            feverRating: nil,
            painsAndNeedlesRating: nil,
            muscleAchesRating: nil,
            additionalInformation: "",
            reviewReminder: reviewReminders.first!
        )
        
    }
    
    // MARK: - Private Methods
}

//
//  RootViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Foundation
import SwiftData
import CocoaLumberjackSwift
import SwiftUI

// MARK: - RootViewModel

@Observable
class RootViewModel {
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let addDefaultCategoriesUseCase: AddDefaultCategoriesUseCase
    private let checkUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase
    private let initializeConnectivityUseCase: InitializeConnectivityUseCase

    // MARK: - Published Properties

    var activeSheet: RootSheet?
    var selectedTab: Tab = .home
    
    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        addDefaultCategoriesUseCase: AddDefaultCategoriesUseCase,
        checkUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase,
        initializeConnectivityUseCase: InitializeConnectivityUseCase
    ) {
        self.modelContext = modelContext
        self.addDefaultCategoriesUseCase = addDefaultCategoriesUseCase
        self.checkUserHasSeenOnboardingUseCase = checkUserHasSeenOnboardingUseCase
        self.initializeConnectivityUseCase = initializeConnectivityUseCase

        DDLogInfo("RootViewModel initialized")
    }

    // MARK: - View Events

    @MainActor
    func onViewFirstAppear() {
        DDLogInfo("onViewFirstAppear called")

        Task {
            DDLogInfo("Adding default categories")
            await addDefaultCategoriesUseCase.execute()

            DDLogInfo("Initializing connectivity")
            initializeConnectivityUseCase.execute()
        }

        checkIfUserHasSeenOnboarding()
    }

    // MARK: - Presentation

    func presentSheet(_ sheet: RootSheet) {
        DDLogInfo("Presenting sheet: \(sheet)")
        activeSheet = sheet
    }

    // MARK: - User Actions
    
    func widgetTapped() {
        selectedTab = .analytics
    }
    
    // MARK: - Private Methods

    private func checkIfUserHasSeenOnboarding() {
        DDLogInfo("Checking if user has seen onboarding")
        let hasSeenOnboarding = checkUserHasSeenOnboardingUseCase.execute()

        if !hasSeenOnboarding {
            DDLogInfo("User has not seen onboarding, presenting onboarding sheet")
            presentSheet(.onboardingView)
        } else {
            DDLogInfo("User has seen onboarding")
        }
    }
}

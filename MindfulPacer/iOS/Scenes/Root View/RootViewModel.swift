//
//  RootViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Combine
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
    private let listenToThemeChangesUseCase: ListenToThemeChangesUseCase

    // MARK: - Published Properties
    
    var activeSheet: RootSheet?
    var selectedTab: Tab = .home
    var selectedTheme: Theme = .system
    
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        addDefaultCategoriesUseCase: AddDefaultCategoriesUseCase,
        checkUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase,
        initializeConnectivityUseCase: InitializeConnectivityUseCase,
        listenToThemeChangesUseCase: ListenToThemeChangesUseCase
    ) {
        self.modelContext = modelContext
        self.addDefaultCategoriesUseCase = addDefaultCategoriesUseCase
        self.checkUserHasSeenOnboardingUseCase = checkUserHasSeenOnboardingUseCase
        self.initializeConnectivityUseCase = initializeConnectivityUseCase
        self.listenToThemeChangesUseCase = listenToThemeChangesUseCase

        DDLogInfo("RootViewModel initialized")

        // Listen for theme changes
        listenForThemeChanges()
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

    private func listenForThemeChanges() {
        listenToThemeChangesUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] theme in
                self?.selectedTheme = theme
            }
            .store(in: &cancellables)
    }
}

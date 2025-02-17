//
//  RootViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Combine
import Foundation
import SwiftData
import SwiftUI

// MARK: - ModeOfUse

enum ModeOfUse: String, CaseIterable, Identifiable {
    case essentials
    case expanded
    
    var id: Self { self }
    
    var name: String {
        self.rawValue.capitalized
    }
    
    var description: String {
        switch self {
        case .essentials:
            "Simpler minified user interface that focuses on comparing subjective well-being, pursued activity and biometric data."
        case .expanded:
            "Access all app features, including the ability to provide fine-grained self-reports on Fatigue, Shortness of Breath, Pains, and other factors."
        }
    }
    
    var icon: String {
        switch self {
        case .essentials:
            "MindfulPacer Essentials Icon"
        case .expanded:
            "MindfulPacer Expanded Icon"
        }
    }
    
    static var appStorageKey: String {
        "modeOfUse"
    }
}

// MARK: - RootViewModel

@Observable
class RootViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let addDefaultActivitiesUseCase: AddDefaultActivitiesUseCase
    private let checkUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase
    private let initializeConnectivityUseCase: InitializeConnectivityUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: RootSheet?
    var selectedTab: Tab = .home
    var selectedTheme: Theme = .system

    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        addDefaultActivitiesUseCase: AddDefaultActivitiesUseCase,
        checkUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase,
        initializeConnectivityUseCase: InitializeConnectivityUseCase
    ) {
        self.modelContext = modelContext
        self.addDefaultActivitiesUseCase = addDefaultActivitiesUseCase
        self.checkUserHasSeenOnboardingUseCase = checkUserHasSeenOnboardingUseCase
        self.initializeConnectivityUseCase = initializeConnectivityUseCase
    }
    
    // MARK: - View Events
    
    @MainActor
    func onViewFirstAppear() {
        Task {
            await addDefaultActivitiesUseCase.execute()
            initializeConnectivityUseCase.execute()
        }
        
        checkIfUserHasSeenOnboarding()
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: RootSheet) {
        activeSheet = sheet
    }
    
    // MARK: - User Actions
    
    func onWidgetTapped() {
        selectedTab = .analytics
    }
    
    // MARK: - Private Methods
    
    private func checkIfUserHasSeenOnboarding() {
        let hasSeenOnboarding = checkUserHasSeenOnboardingUseCase.execute()
        
        if !hasSeenOnboarding {
            presentSheet(.onboardingView)
        }
    }
}

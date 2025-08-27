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

// MARK: - NewFeature

struct NewFeature: Identifiable {
    var id: String { title }
    
    var title: String
    var description: String
    var icon: String
    var color: Color = .brandPrimary
}

// MARK: - ModeOfUse

enum ModeOfUse: String, CaseIterable, Identifiable {
    case essentials
    case expanded
    
    var id: Self { self }
    
    var name: String {
        self.rawValue.capitalized
    }
    
    var localized: String {
        switch self {
        case .essentials:
            String(localized: "Essentials")
        case .expanded:
            String(localized: "Expanded")
        }
    }
    
    var description: String {
        switch self {
        case .essentials:
            String(localized: "Simpler minified user interface that focuses on comparing subjective well-being, pursued activity and biometric data.")
        case .expanded:
            String(localized: "Access all app features, including the ability to provide fine-grained self-reports on Fatigue, Shortness of Breath, Pains, and other factors.")
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
    
    // MARK: - Published Properties
    
    var activeSheet: RootSheet?
    var selectedTab: Tab = .home
    var selectedTheme: Theme = .system
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let whatsNewDefaultsKey = "lastSeenWhatsNewVersion"

    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        addDefaultActivitiesUseCase: AddDefaultActivitiesUseCase,
        checkUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase
    ) {
        self.modelContext = modelContext
        self.addDefaultActivitiesUseCase = addDefaultActivitiesUseCase
        self.checkUserHasSeenOnboardingUseCase = checkUserHasSeenOnboardingUseCase
    }
    
    // MARK: - View Events
    
    @MainActor
    func onViewFirstAppear() {
        Task {
            await addDefaultActivitiesUseCase.execute()
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
    
    // MARK: - What's New
    
    private let allWhatsNew: [String: [NewFeature]] = [
        "1.5": [
            NewFeature(
                title: String(localized: "Apple Watch Support"),
                description: String(localized: "New WatchOS app to continuously monitor your heart rate and step reminders."),
                icon: "applewatch"
            ),
            NewFeature(
                title: String(localized: "Enhanced Reflections"),
                description: String(localized: "Visualize the data that led to a triggered reminder."),
                icon: "chart.xyaxis.line"
            )
        ]
    ]
    
    var whatsNewFeatures: [NewFeature] {
        allWhatsNew[currentVersion] ?? []
    }
    
    func markWhatsNewSeen() {
        UserDefaults.standard.set(currentVersion, forKey: whatsNewDefaultsKey)
    }
    
    private var currentVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0.0.0"
    }
    
    private func shouldPresentWhatsNew() -> Bool {
        let lastSeen = UserDefaults.standard.string(forKey: whatsNewDefaultsKey)
        return !(allWhatsNew[currentVersion]?.isEmpty ?? true) && lastSeen != currentVersion
    }
    
    private func maybePresentWhatsNew() {
        if shouldPresentWhatsNew() {
            presentSheet(.whatsNewView)
        }
    }
    
    // MARK: - Private Methods
    
    private func checkIfUserHasSeenOnboarding() {
        let hasSeenOnboarding = checkUserHasSeenOnboardingUseCase.execute()
        
        if !hasSeenOnboarding {
            presentSheet(.onboardingView)
        } else {
            maybePresentWhatsNew()
        }
    }
}

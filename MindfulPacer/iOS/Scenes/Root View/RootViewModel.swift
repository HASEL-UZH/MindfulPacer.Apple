//
//  RootViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Foundation
import SwiftData
import SwiftUI

// MARK: - ModeOfUse

enum ModeOfUse: String, CaseIterable, Identifiable {
    case expanded
    case essentials
    
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

// MARK: - DeviceMode

enum DeviceMode: String, CaseIterable, Identifiable {
    case iPhoneAndWatch
    case iPhoneOnly
    
    var id: Self { self }
    
    var localized: String {
        switch self {
        case .iPhoneAndWatch: String(localized: "iPhone + Apple Watch")
        case .iPhoneOnly: String(localized: "iPhone Only")
        }
    }
    
    var icon: String {
        switch self {
        case .iPhoneOnly:
            "iphone"
        case .iPhoneAndWatch:
            "ipod.and.applewatch"
        }
    }
    
    var description: String {
        switch self {
        case .iPhoneOnly:
            String(localized: "Use MindfulPacer with just yourcha iPhone. You can log reflections and activities manually without a paired Apple Watch.")
        case .iPhoneAndWatch:
            String(localized: "Pair MindfulPacer with your Apple Watch to automatically collect health data, reminders, and activity tracking alongside your reflections.")
        }
    }
    
    static var appStorageKey: String {
        "deviceMode"
    }
}

extension DeviceMode {
    static func current(from defaults: UserDefaults = DefaultsStore.shared) -> DeviceMode {
        if let raw = defaults.string(forKey: DeviceMode.appStorageKey),
           let mode = DeviceMode(rawValue: raw) {
            return mode
        }
        return .iPhoneAndWatch
    }
}

// MARK: - RootViewModel

@Observable
class RootViewModel {
    
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let addDefaultActivitiesUseCase: AddDefaultActivitiesUseCase
    private let checkUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase
    
    // MARK: - State
    
    var activeSheet: RootSheet?
    var selectedTab: Tab = .home
    var selectedTheme: Theme = .system
    
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
    
    // MARK: - Private
    
    private func checkIfUserHasSeenOnboarding() {
        let hasSeenOnboarding = checkUserHasSeenOnboardingUseCase.execute()
        
        if !hasSeenOnboarding {
            presentSheet(.onboardingView)
        }
    }
}

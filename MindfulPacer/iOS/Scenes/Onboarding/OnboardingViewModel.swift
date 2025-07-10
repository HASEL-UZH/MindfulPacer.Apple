//
//  OnboardingViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import Combine
import Foundation

// MARK: - KeyFeatureItem

struct KeyFeatureItem {
    let icon: String
    let title: String
    let description: String
}

// MARK: - MainFeatureItem

struct MainFeatureItem {
    let icon: String
    let title: String
    let description: String
    let points: [String]
    let image: String
}

// MARK: - ActivityPromotingFeature

struct ActivityPromotingFeature {
    let icon: String
    let title: String
    let steps: String
}

// MARK: - OnboardingViewModel

@Observable
@MainActor
class OnboardingViewModel {
    
    // MARK: - Dependencies

    private let initializeNotificationsUseCase: InitializeNotificationsUseCase
    private let requestHealthAuthorisationUseCase: RequestHealthAuthorisationUseCase
    private let toggleUserHasSeenOnboardingUseCase: ToggleUserHasSeenOnboardingUseCase

    // MARK: - Published Properties

    var navigationPath: [OnboardingNavigationDestination] = []

    var shouldDismiss: Bool = false
    var actionButtonHeight: CGFloat = 0.0
    var selectedModeOfUse: ModeOfUse?
    
    var actionButtonTitle: String {
        guard let lastDestination = navigationPath.last else {
            return String(localized: "Continue")
        }

        switch lastDestination {
        case .appleWatchConnection:
            return String(localized: "Continue")
        case .notifications:
            return didCompleteNotificationsRequest ? String(localized: "Continue") : String(localized: "Allow Notifications")
        case .appleHealth:
            return didCompleteHealthAuthorization ? String(localized: "Continue") : String(localized: "Allow Health Access")
        case .mainFeatures:
            return String(localized: "Continue")
        case .modeOfUse:
            return String(localized: "Continue")
        case .activityPromotingFeatures:
            return String(localized: "Continue")
        case .disclaimer:
            return String(localized: "Finish")
        }
    }

    var isActionButtonDisabled: Bool {
        guard let lastDestination = navigationPath.last else {
            return false
        }

        switch lastDestination {
        case .disclaimer:
            return !didAcceptTerms
        case .modeOfUse:
            return selectedModeOfUse.isNil
        default:
            return false
        }
    }

    var showAcceptTermsButton: Bool {
        guard let lastDestination = navigationPath.last else {
            return false
        }

        return lastDestination == .disclaimer
    }
    var didAcceptTerms: Bool = false

    var didCompleteNotificationsRequest: Bool = false
    var didCompleteHealthAuthorization: Bool = false

    let keyFeatures: [KeyFeatureItem] = [
        KeyFeatureItem(
            icon: "figure.run",
            title: String(localized: "Support for Activity Pacing"),
            description: String(localized: "Better manage your physical and mental energy by regulating your activity levels.")
        ),
        KeyFeatureItem(
            icon: "book.pages.fill",
            title: String(localized: "Diary on Activities & Energy"),
            description: String(localized: "Reflection your activities, energy management, moods and symptoms.")
        ),
        KeyFeatureItem(
            icon: "applewatch",
            title: String(localized: "Apple Watch Sync"),
            description: String(localized: "Amend your reflection with biometric data and receive reminders for reflection.")
        ),
        KeyFeatureItem(
            icon: "chart.xyaxis.line",
            title: String(localized: "Insights"),
            description: String(localized: "Learn how your activities impact your energy by visualizing the diary and biometric data on a timeline.")
        )
    ]

    let mainFeatures: [MainFeatureItem] = [
        MainFeatureItem(
            icon: "flame",
            title: String(localized: "Energy & Activity Pacing"),
            description: String(localized: "Better manage your physical and mental energy by regulating your activity levels."),
            points: [
                String(localized: "Timelines of your physical activity (steps, heart rate and others)"),
                String(localized: "Overlays of your reflections on activity & energy"),
                String(localized: "Visually correlate activities, energy levels and reflections")
            ],
            image: "Main Feature 1"
        ),
        MainFeatureItem(
            icon: "book.pages",
            title: String(localized: "Reflections of Activities & Energy Levels"),
            description: String(localized: "Add reflections on your activities, energy management, moods and symptoms."),
            points: [
                String(localized: "Your Apple Watch can remind you to reflect at times of high activity or specific times of the day"),
                String(localized: "Manually add and edit reflections anytime")
            ],
            image: "Main Feature 2"
        )
    ]
    
    let activityPromotingFeatures: [ActivityPromotingFeature] = [
        ActivityPromotingFeature(
            icon: "figure.stand",
            title: String(localized: "Disabling Stand Reminders"),
            steps:
                String(localized: """
                1. Open the Watch app on your iPhone.
                2. Tap on 'My Watch' at the bottom.
                3. Scroll down and tap on 'Activity'.
                4. Toggle off 'Stand Reminders'.
                """)
        ),
        ActivityPromotingFeature(
            icon: "bell.badge",
            title: String(localized: "Disabling Activity Reminders"),
            steps:
                String(localized: """
                1. Open the Watch app on your iPhone.
                2. Tap on 'My Watch'.
                3. Tap on 'Notifications'.
                4. Select 'Activity'.
                5. Toggle off 'Activity Reminders'.
                """)
        ),
        ActivityPromotingFeature(
            icon: "figure.walk",
            title: String(localized: "Adjust Move Goals"),
            steps:
                String(localized: """
                1. Open the Activity app on your Apple Watch.
                2. Firmly press the display.
                3. Tap 'Change Move Goal'.
                4. Adjust the goal to a level that suits your current capabilities.
                """)
        ),
        ActivityPromotingFeature(
            icon: "aqi.low",
            title: String(localized: "Disabling Breathe Reminders"),
            steps:
                String(localized: """
                1. Open the Activity app on your Apple Watch.
                2. Firmly press the display.
                3. Tap 'Change Move Goal'.
                4. Adjust the goal to a level that suits your current capabilities.
                """)
        )
    ]

    // MARK: - Initialization

    init(
        initializeNotificationsUseCase: InitializeNotificationsUseCase,
        requestHealthAuthorisationUseCase: RequestHealthAuthorisationUseCase,
        toggleUserHasSeenOnboardingUseCase: ToggleUserHasSeenOnboardingUseCase
    ) {
        self.initializeNotificationsUseCase = initializeNotificationsUseCase
        self.requestHealthAuthorisationUseCase = requestHealthAuthorisationUseCase
        self.toggleUserHasSeenOnboardingUseCase = toggleUserHasSeenOnboardingUseCase
    }

    // MARK: - View Lifecycle

    func onViewFirstAppear() {}

    // MARK: - User Actions

    func actionButtonTapped() {
        /// Check if we are on the first page
        guard let currentDestination = navigationPath.last else {
            navigationPath.append(OnboardingNavigationDestination.appleWatchConnection)
            return
        }

        switch currentDestination {
        case .appleWatchConnection:
            navigationPath.append(OnboardingNavigationDestination.notifications)
        case .notifications:
            requestNotificationPermission()
        case .appleHealth:
            requestHealthAuthorization()
        case .mainFeatures:
            navigationPath.append(OnboardingNavigationDestination.activityPromotingFeatures)
        case .activityPromotingFeatures:
            navigationPath.append(OnboardingNavigationDestination.modeOfUse)
        case .modeOfUse:
            navigationPath.append(OnboardingNavigationDestination.disclaimer)
        case .disclaimer:
            toggleUserHasSeenOnboardingUseCase.execute()
            shouldDismiss = true
        }
    }

    func skipButtonTapped() {
        /// Check if we are on the first page
        guard let currentDestination = navigationPath.last else {
            navigateTo(destination: .appleWatchConnection)
            return
        }

        switch currentDestination {
        case .appleWatchConnection:
            navigateTo(destination: .notifications)
        case .notifications:
            navigateTo(destination: .appleHealth)
        case .appleHealth:
            navigateTo(destination: .mainFeatures)
        case .mainFeatures:
            navigateTo(destination: .activityPromotingFeatures)
        case .activityPromotingFeatures:
            navigateTo(destination: .modeOfUse)
        default:
            break
        }
    }

    // MARK: - Presentation

    func navigateTo(destination: OnboardingNavigationDestination) {
        navigationPath.append(destination)
    }

    // MARK: - Private Methods
    
    private func requestNotificationPermission() {
        initializeNotificationsUseCase.execute { result in
            switch result {
            case .success:
                print("Notifications are now authorized")
            case .failure(let failure):
                print("Notifications not authorized \(String(describing: failure.failureReason))")
            }
            
            Task { @MainActor in
                self.navigateTo(destination: .appleHealth)
                self.didCompleteNotificationsRequest = true
            }
        }
    }

    private func requestHealthAuthorization() {
        requestHealthAuthorisationUseCase.execute { success, error in
            if let error = error {
                print("Health authorization failed: \(error.errorDescription ?? "Unknown error")")
            } else if success {
                Task { @MainActor in
                    self.didCompleteHealthAuthorization = true
                    self.navigateTo(destination: .mainFeatures)
                }
            }
            
            Task { @MainActor in
                self.didCompleteHealthAuthorization = true
            }
        }
    }
}

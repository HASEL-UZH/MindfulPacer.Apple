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
    private let setModeOfUseUseCase: SetModeOfUseUseCase
    private let toggleUserHasSeenOnboardingUseCase: ToggleUserHasSeenOnboardingUseCase

    // MARK: - Published Properties

    var navigationPath: [OnboardingNavigationDestination] = []

    var shouldDismiss: Bool = false
    var actionButtonHeight: CGFloat = 0.0
    var selectedModeOfUse: ModeOfUse?
    
    var actionButtonTitle: String {
        guard let lastDestination = navigationPath.last else {
            return "Continue"
        }

        switch lastDestination {
        case .appleWatchConnection:
            return "Continue"
        case .notifications:
            return didCompleteNotificationsRequest ? "Continue" : "Allow Notifications"
        case .appleHealth:
            return didCompleteHealthAuthorization ? "Continue" : "Allow Health Access"
        case .mainFeatures:
            return "Continue"
        case .modeOfUse:
            return "Continue"
        case .activityPromotingFeatures:
            return "Continue"
        case .disclaimer:
            return "Finish"
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
            title: "Support for Activity Pacing",
            description: "Better manage your physical and mental energy by regulating your activity levels."
        ),
        KeyFeatureItem(
            icon: "book.pages.fill",
            title: "Diary on Activities & Energy",
            description: "Review your activities, energy management, moods and symptoms."
        ),
        KeyFeatureItem(
            icon: "applewatch",
            title: "Apple Watch Sync",
            description: "Amend your review with biometric data and receive reminders for reflection."
        ),
        KeyFeatureItem(
            icon: "chart.xyaxis.line",
            title: "Insights",
            description: "Learn how your activities impact your energy by visualizing the diary and biometric data on a timeline."
        )
    ]

    let mainFeatures: [MainFeatureItem] = [
        MainFeatureItem(
            icon: "flame",
            title: "Energy & Activity Pacing",
            description: "Better manage your physical and mental energy by regulating your activity levels.",
            points: [
                "Timelines of your physical activity (steps, heart rate and others)",
                "Overlays of your reviews on activity & energy",
                "Visually correlate activities, energy levels and reviews"
            ],
            image: "Main Feature 1"
        ),
        MainFeatureItem(
            icon: "book.pages",
            title: "Reviews of Activities & Energy Levels",
            description: "Add reflections on your activities, energy management, moods and symptoms.",
            points: [
                "Your Apple Watch can remind you to reflect at times of high activity or specific times of the day",
                "Manually add and edit reviews anytime"
            ],
            image: "Main Feature 2"
        )
    ]
    
    let activityPromotingFeatures: [ActivityPromotingFeature] = [
        ActivityPromotingFeature(
            icon: "figure.stand",
            title: "Disabling Stand Reminders",
            steps:
                """
                1. Open the Watch app on your iPhone.
                2. Tap on 'My Watch' at the bottom.
                3. Scroll down and tap on 'Activity'.
                4. Toggle off 'Stand Reminders'.
                """
        ),
        ActivityPromotingFeature(
            icon: "bell.badge",
            title: "Disabling Activity Reminders",
            steps:
                """
                1. Open the Watch app on your iPhone.
                2. Tap on 'My Watch'.
                3. Tap on 'Notifications'.
                4. Select 'Activity'.
                5. Toggle off 'Activity Reminders'.
                """
        ),
        ActivityPromotingFeature(
            icon: "figure.pool.swim",
            title: "Disabling Exercise Notifications",
            steps:
                """
                1. Open the Watch app on your iPhone.
                2. Tap on 'My Watch'.
                3. Tap on 'Notifications'.
                4. Select 'Activity'.
                5. Toggle off 'Workout Reminders'.
                """
        ),
        ActivityPromotingFeature(
            icon: "figure.walk",
            title: "Adjust Move Goals",
            steps:
                """
                1. Open the Activity app on your Apple Watch.
                2. Firmly press the display.
                3. Tap 'Change Move Goal'.
                4. Adjust the goal to a level that suits your current capabilities.
                """
        ),
        ActivityPromotingFeature(
            icon: "aqi.low",
            title: "Disabling Breathe Reminders",
            steps:
                """
                1. Open the Activity app on your Apple Watch.
                2. Firmly press the display.
                3. Tap 'Change Move Goal'.
                4. Adjust the goal to a level that suits your current capabilities.
                """
        )
    ]

    // MARK: - Initialization

    init(
        initializeNotificationsUseCase: InitializeNotificationsUseCase,
        requestHealthAuthorisationUseCase: RequestHealthAuthorisationUseCase,
        setModeOfUseUseCase: SetModeOfUseUseCase,
        toggleUserHasSeenOnboardingUseCase: ToggleUserHasSeenOnboardingUseCase
    ) {
        self.initializeNotificationsUseCase = initializeNotificationsUseCase
        self.requestHealthAuthorisationUseCase = requestHealthAuthorisationUseCase
        self.setModeOfUseUseCase = setModeOfUseUseCase
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
            setModeOfUseUseCase.execute(modeOfUse: selectedModeOfUse.unsafelyUnwrapped)
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

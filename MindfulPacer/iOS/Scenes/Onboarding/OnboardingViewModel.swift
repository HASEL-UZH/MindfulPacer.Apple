//
//  OnboardingViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

import Combine
import Foundation

// MARK: - AppleWatchComplicationType

enum AppleWatchComplicationType: String, CaseIterable {
    case rectangular
    case circular
    case corner
    case inline
    
    var icon: String {
        switch self {
        case .circular: "circle.fill"
        case .rectangular: "rectangle.fill"
        case .corner: "righttriangle.split.diagonal.fill"
        case .inline: "line.3.horizontal"
        }
    }
    
    var image: String {
        switch self {
        case .circular:
            "Circular Complication"
        case .rectangular:
            "Rectangular Complication"
        case .corner:
            "Corner Complication"
        case .inline:
            "Inline Complication"
        }
    }
}

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
    var selectedDeviceMode: DeviceMode?
    var selectedAppleWatchComplicationTyoe: AppleWatchComplicationType = .rectangular
    
    var actionButtonTitle: String {
        guard let lastDestination = navigationPath.last else {
            return String(localized: "Continue")
        }

        switch lastDestination {
        case .deviceMode:
            return String(localized: "Continue")
        case .appleWatchConnection:
            return String(localized: "Continue")
        case .notifications:
            return didCompleteNotificationsRequest ? String(localized: "Continue") : String(localized: "Allow Notifications")
        case .appleHealth:
            return String(localized: "Continue")
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
        guard let lastDestination = navigationPath.last else { return false }

        switch lastDestination {
        case .disclaimer:
            return !didAcceptTerms
        case .modeOfUse:
            return selectedModeOfUse.isNil
        case .deviceMode:
            return selectedDeviceMode.isNil
        default:
            return false
        }
    }
    
    var imageNameForPermissions: String {
        switch selectedDeviceMode {
        case .iPhoneOnly:
            return "Correct Permissions - iPhone Only"
        case .iPhoneAndWatch:
            return "Correct Permissions - iPhone and Watch"
        case nil:
            return ""
        }
    }
    
    var descriptionForPermissions: String {
        switch selectedDeviceMode {
        case .iPhoneOnly:
            "Please make sure read permissions are granted for Heart Rate and Steps."
        case .iPhoneAndWatch:
            "Pleese make sure write permissions are granted for Workouts."
        case nil:
            ""
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
        guard let currentDestination = navigationPath.last else {
            navigationPath.append(.deviceMode)
            return
        }
        
        switch currentDestination {
        case .deviceMode:
            if selectedDeviceMode == .iPhoneAndWatch {
                navigationPath.append(.appleWatchConnection)
            } else {
                navigationPath.append(.notifications)
            }
        case .appleWatchConnection:
            navigationPath.append(.notifications)
        case .notifications:
            requestNotificationPermission()
        case .appleHealth:
            requestHealthAuthorization()
        case .mainFeatures:
            navigationPath.append(.activityPromotingFeatures)
        case .activityPromotingFeatures:
            navigationPath.append(.modeOfUse)
        case .modeOfUse:
            navigationPath.append(.disclaimer)
        case .disclaimer:
            toggleUserHasSeenOnboardingUseCase.execute()
            WatchOnboardingBridge.shared.notifyCompletedNow()
            shouldDismiss = true
        }
    }
    
    func skipButtonTapped() {
        guard let currentDestination = navigationPath.last else {
            navigateTo(destination: .deviceMode)
            return
        }
        
        switch currentDestination {
        case .deviceMode:
            navigateTo(destination: .notifications)
        case .appleWatchConnection:
            navigateTo(destination: .notifications)
        case .notifications:
            navigateTo(destination: .appleHealth)
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

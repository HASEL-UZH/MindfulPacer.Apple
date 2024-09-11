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
    let points: String
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
class OnboardingViewModel {
    // MARK: - Dependencies
    
    private let initializeNotificationsUseCase: InitializeNotificationsUseCase
    
    // MARK: - Published Properties
    
    var navigationPath: [OnboardingNavigationDestination] = []
    
    var viewDismissalPublisher = PassthroughSubject<Bool, Never>()
    private var shouldDismiss = false {
        didSet {
            viewDismissalPublisher.send(shouldDismiss)
        }
    }
    
    var actionButtonHeight: CGFloat = 0.0
    
    var actionButtonTitle: String {
        guard let lastDestination = navigationPath.last else {
            return "Continue"
        }
        
        switch lastDestination {
        case .appleWatchConnection:
            return "Continue"
        case .notifications:
            return "Allow Notifications"
        case .appleHealth:
            return "Allow Health Access"
        case .mainFeatures:
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
            points:
                """
                - Timelines of your physical activity (steps, heart rate and others)
                - Overlays of your reviews on activity & energy
                - Visually correlate activities, energy levels and reviews
                """,
            image: "iPhone Placeholder"
        ),
        MainFeatureItem(
            icon: "book.pages",
            title: "Reviews of Activities & Energy Levels",
            description: "Add reflections on your activities, energy management, moods and symptoms.",
            points:
                """
                - Your Apple Watch can remind you to reflect at times of high activity or specific times of the day
                - Manually add and edit reviews anytime
                """,
            image: "iPhone Placeholder"
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
        initializeNotificationsUseCase: InitializeNotificationsUseCase
    ) {
        self.initializeNotificationsUseCase = initializeNotificationsUseCase
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {
        
    }
    
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
            initializeNotificationsUseCase.execute { result in
                switch result {
                case .success(_):
                    self.navigationPath.append(OnboardingNavigationDestination.appleHealth)
                case .failure(let failure):
                    print("DEBUG: Notifications not authorized \(String(describing: failure.failureReason))")
                }
            }
        case .appleHealth:
            navigationPath.append(OnboardingNavigationDestination.mainFeatures)
        case .mainFeatures:
            navigationPath.append(OnboardingNavigationDestination.activityPromotingFeatures)
        case .activityPromotingFeatures:
            navigationPath.append(OnboardingNavigationDestination.disclaimer)
        case .disclaimer:
            shouldDismiss = true
        }
    }
    
    func skipButtonTapped() {
        /// Check if we are on the first page
        guard let currentDestination = navigationPath.last else {
            navigationPath.append(OnboardingNavigationDestination.appleWatchConnection)
            return
        }
        
        switch currentDestination {
        case .appleWatchConnection:
            navigationPath.append(OnboardingNavigationDestination.notifications)
        case .notifications:
            navigationPath.append(OnboardingNavigationDestination.appleHealth)
        case .appleHealth:
            navigationPath.append(OnboardingNavigationDestination.mainFeatures)
        case .mainFeatures:
            navigationPath.append(OnboardingNavigationDestination.activityPromotingFeatures)
        case .activityPromotingFeatures:
            navigationPath.append(OnboardingNavigationDestination.disclaimer)
        default:
            break
        }
    }
    
    // MARK: - Presentation
    
    
    // MARK: - Private Methods
}

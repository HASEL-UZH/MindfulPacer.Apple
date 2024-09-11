//
//  OnboardingViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 10.09.2024.
//

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

// MARK: - OnboardingViewModel

@Observable
class OnboardingViewModel {
    // MARK: - Dependencies
    
    // MARK: - Published Properties (State)
    
    var navigationPath: [OnboardingNavigationDestination] = []
    
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
    
    var showAcceptTermsButton: Bool {
        guard let lastDestination = navigationPath.last else {
            return false
        }
        
        return lastDestination == .disclaimer
    }
    var didAcceptTerms: Bool = false
    
    // MARK: - Initialization
    
    init(
        
    ) {
        
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
            navigationPath.append(OnboardingNavigationDestination.appleHealth)
        case .appleHealth:
            navigationPath.append(OnboardingNavigationDestination.mainFeatures)
        case .mainFeatures:
            navigationPath.append(OnboardingNavigationDestination.activityPromotingFeatures)
        case .activityPromotingFeatures:
            navigationPath.append(OnboardingNavigationDestination.disclaimer)
        case .disclaimer:
            break // TODO: We need to dismiss
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

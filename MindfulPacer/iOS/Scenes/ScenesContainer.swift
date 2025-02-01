//
//  ScenesContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 01.07.2024.
//

import Foundation
import Factory
import SwiftData

final class ScenesContainer: SharedContainer, @unchecked Sendable {
    static let shared = ScenesContainer()
    var manager = ContainerManager()

    // MARK: - Analytics

    @MainActor
    var analyticsViewModel: Factory<AnalyticsViewModel> {
        self {
            AnalyticsViewModel(
                modelContext: ModelContainer.prod.mainContext,
                fetchHeartRateUseCase: UseCasesContainer.shared.fetchHeartRateUseCase(),
                fetchReviewsInPeriodUseCase: UseCasesContainer.shared.fetchReviewsInPeriodUseCase(),
                fetchReviewRemindersUseCase: UseCasesContainer.shared.fetchReviewRemindersUseCase(),
                fetchStepsUseCase: UseCasesContainer.shared.fetchStepsUseCase()
            )
        }
    }

    // MARK: - Home

    @MainActor
    var homeViewModel: Factory<HomeViewModel> {
        self {
            HomeViewModel(
                modelContext: ModelContainer.prod.mainContext,
                checkMissedReviewsUseCase: UseCasesContainer.shared.checkMissedReviewsUseCase(),
                createReviewUseCase: UseCasesContainer.shared.createReviewUseCase(),
                fetchActionedMissedReviewsUseCase: UseCasesContainer.shared.fetchActionedMissedReviewsUseCase(),
                fetchCurrentHeartRateUseCase: UseCasesContainer.shared.fetchCurrentHeartRateUseCase(),
                fetchCurrentStepsUseCase: UseCasesContainer.shared.fetchCurrentStepsUseCase(),
                fetchDefaultActivitiesUseCase: UseCasesContainer.shared.fetchDefaultActivitiesUseCase(),
                fetchReviewsUseCase: UseCasesContainer.shared.fetchReviewsUseCase(),
                fetchReviewRemindersUseCase: UseCasesContainer.shared.fetchReviewRemindersUseCase(),
                filterReviewsUseCase: UseCasesContainer.shared.filterReviewsUseCase(),
                markMissedReviewAsActionedUseCase: UseCasesContainer.shared.markMissedReviewAsActionedUseCase()
            )
        }
    }

    // MARK: - Onboarding

    @MainActor
    var onboardingViewModel: Factory<OnboardingViewModel> {
        self {
            OnboardingViewModel(
                initializeNotificationsUseCase: UseCasesContainer.shared.initializeNotificationsUseCase(),
                requestHealthAuthorisationUseCase: UseCasesContainer.shared.requestHealthAuthorisationUseCase(),
                toggleUserHasSeenOnboardingUseCase: UseCasesContainer.shared.toggleUserHasSeenOnboardingUseCase()
            )
        }
    }

    // MARK: - Root

    @MainActor
    var rootViewModel: Factory<RootViewModel> {
        self {
            RootViewModel(
                modelContext: ModelContainer.prod.mainContext,
                addDefaultActivitiesUseCase: UseCasesContainer.shared.addDefaultActivitiesUseCase(),
                checkUserHasSeenOnboardingUseCase: UseCasesContainer.shared.checkUserHasSeenOnboardingUseCase(),
                initializeConnectivityUseCase: UseCasesContainer.shared.initializeConnectivityUseCase()
            )
        }
    }

    // MARK: - Review

    @MainActor
    var editReviewViewModel: Factory<EditReviewViewModel> {
        self {
            EditReviewViewModel(
                modelContext: ProcessInfo.processInfo.isRunningInPreviewOrTest ? ModelContainer.preview.mainContext : ModelContainer.prod.mainContext,
                createReviewUseCase: UseCasesContainer.shared.createReviewUseCase(),
                deleteReviewUseCase: UseCasesContainer.shared.deleteReviewUseCase(),
                fetchDefaultActivitiesUseCase: UseCasesContainer.shared.fetchDefaultActivitiesUseCase(),
                saveReviewUseCase: UseCasesContainer.shared.saveReviewUseCase()
            )
        }
    }

    @MainActor
    var reviewsFilterViewModel: Factory<ReviewsFilterViewModel> {
        self {
            ReviewsFilterViewModel(fetchDefaultActivitiesUseCase: UseCasesContainer.shared.fetchDefaultActivitiesUseCase())
        }
    }

    // MARK: - Review Reminder

    @MainActor
    var createReviewReminderViewModel: Factory<CreateReviewReminderViewModel> {
        self {
            CreateReviewReminderViewModel(
                modelContext: ModelContainer.prod.mainContext,
                createReviewReminderUseCase: UseCasesContainer.shared.createReviewReminderUseCase(),
                deleteReviewReminderUseCase: UseCasesContainer.shared.deleteReviewReminderUseCase(),
                saveReviewReminderUseCase: UseCasesContainer.shared.saveReviewReminderUseCase(),
                triggerWatchNotificationUseCase: UseCasesContainer.shared.triggerWatchNotificationUseCase()
            )
        }
    }
    
    // MARK: - Settings
    
    @MainActor
    var settingsViewModel: Factory<SettingsViewModel> {
        self {
            SettingsViewModel(
                checkInternetConnectivityUseCase: UseCasesContainer.shared.checkInternetConnectivityUseCase(),
                fetchRoadmapUseCase: UseCasesContainer.shared.fetchRoadmapUseCase()
            )
        }
    }
}

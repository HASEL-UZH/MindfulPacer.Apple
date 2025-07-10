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
                fetchReflectionsInPeriodUseCase: UseCasesContainer.shared.fetchReflectionsInPeriodUseCase(),
                fetchRemindersUseCase: UseCasesContainer.shared.fetchRemindersUseCase(),
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
                checkMissedReflectionsUseCase: UseCasesContainer.shared.checkMissedReflectionsUseCase(),
                createReflectionUseCase: UseCasesContainer.shared.createReflectionUseCase(),
                fetchActionedMissedReflectionsUseCase: UseCasesContainer.shared.fetchActionedMissedReflectionsUseCase(),
                fetchCurrentHeartRateUseCase: UseCasesContainer.shared.fetchCurrentHeartRateUseCase(),
                fetchCurrentStepsUseCase: UseCasesContainer.shared.fetchCurrentStepsUseCase(),
                fetchDefaultActivitiesUseCase: UseCasesContainer.shared.fetchDefaultActivitiesUseCase(),
                fetchHeartRateDataLast24HoursUseCase: UseCasesContainer.shared.fetchHeartRateDataLast24HoursUseCase(),
                fetchReflectionsUseCase: UseCasesContainer.shared.fetchReflectionsUseCase(),
                fetchRemindersUseCase: UseCasesContainer.shared.fetchRemindersUseCase(),
                fetchStepDataLast24HoursUseCase: UseCasesContainer.shared.fetchStepDataLast24HoursUseCase(),
                filterReflectionsUseCase: UseCasesContainer.shared.filterReflectionsUseCase(),
                markMissedReflectionAsActionedUseCase: UseCasesContainer.shared.markMissedReflectionAsActionedUseCase()
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
    
    // MARK: - Outreach
    
    @MainActor
    var outreachViewModel: Factory<OutreachViewModel> {
        self {
            OutreachViewModel(
                fetchBlogArticlesUseCase: UseCasesContainer.shared.fetchBlogArticlesUseCase()
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
    
    // MARK: - Reflection
    
    @MainActor
    var editReflectionViewModel: Factory<EditReflectionViewModel> {
        self {
            EditReflectionViewModel(
                modelContext: ProcessInfo.processInfo.isRunningInPreviewOrTest ? ModelContainer.preview.mainContext : ModelContainer.prod.mainContext,
                createReflectionUseCase: UseCasesContainer.shared.createReflectionUseCase(),
                deleteReflectionUseCase: UseCasesContainer.shared.deleteReflectionUseCase(),
                fetchDefaultActivitiesUseCase: UseCasesContainer.shared.fetchDefaultActivitiesUseCase(),
                saveReflectionUseCase: UseCasesContainer.shared.saveReflectionUseCase()
            )
        }
    }
    
    @MainActor
    var reviewsFilterViewModel: Factory<ReflectionsFilterViewModel> {
        self {
            ReflectionsFilterViewModel(fetchDefaultActivitiesUseCase: UseCasesContainer.shared.fetchDefaultActivitiesUseCase())
        }
    }
    
    // MARK: - Roadmap
    
    @MainActor
    var roadMapViewModel: Factory<RoadmapViewModel> {
        self {
            RoadmapViewModel(
                checkInternetConnectivityUseCase: UseCasesContainer.shared.checkInternetConnectivityUseCase(),
                fetchRoadmapUseCase: UseCasesContainer.shared.fetchRoadmapUseCase()
            )
        }
    }
    
    // MARK: - Reminder
    
    @MainActor
    var createReminderViewModel: Factory<CreateReminderViewModel> {
        self {
            CreateReminderViewModel(
                modelContext: ModelContainer.prod.mainContext,
                createReminderUseCase: UseCasesContainer.shared.createReminderUseCase(),
                deleteReminderUseCase: UseCasesContainer.shared.deleteReminderUseCase(),
                saveReminderUseCase: UseCasesContainer.shared.saveReminderUseCase(),
                triggerWatchNotificationUseCase: UseCasesContainer.shared.triggerWatchNotificationUseCase()
            )
        }
    }
    
    // MARK: - Settings
    
    @MainActor
    var settingsViewModel: Factory<SettingsViewModel> {
        self {
            SettingsViewModel(
                checkMissedReflectionsUseCase: UseCasesContainer.shared.checkMissedReflectionsUseCase(),
                fetchHeartRateDataLast24HoursUseCase: UseCasesContainer.shared.fetchHeartRateDataLast24HoursUseCase(),
                fetchReflectionsUseCase: UseCasesContainer.shared.fetchReflectionsUseCase(),
                fetchRemindersUseCase: UseCasesContainer.shared.fetchRemindersUseCase(),
                fetchStepDataLast24HoursUseCase: UseCasesContainer.shared.fetchStepDataLast24HoursUseCase()
            )
        }
    }
}

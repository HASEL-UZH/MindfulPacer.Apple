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
                checkHealthPermissionsUseCase: UseCasesContainer.shared.checkHealthPermissionsUseCase(),
                fetchCurrentHeartRateUseCase: UseCasesContainer.shared.fetchCurrentHeartRateUseCase(),
                fetchCurrentStepsUseCase: UseCasesContainer.shared.fetchCurrentStepsUseCase(),
                fetchHeartRateDataLast24HoursUseCase: UseCasesContainer.shared.fetchHeartRateDataLast24HoursUseCase(),
                fetchMissedReflectionsUseCase: UseCasesContainer.shared.fetchMissedReflectionsUseCase(),
                fetchStepDataLast24HoursUseCase: UseCasesContainer.shared.fetchStepDataLast24HoursUseCase()
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
                checkUserHasSeenOnboardingUseCase: UseCasesContainer.shared.checkUserHasSeenOnboardingUseCase()
            )
        }
    }
    
    // MARK: - Reflection
    
    @MainActor
    var editReflectionViewModel: Factory<EditReflectionViewModel> {
        self {
            EditReflectionViewModel(
                modelContext: ProcessInfo.processInfo.isRunningInPreviewOrTest ? ModelContainer.preview.mainContext : ModelContainer.prod.mainContext
            )
        }
    }
    
    @MainActor
    var reviewsFilterViewModel: Factory<ReflectionsFilterViewModel> {
        self {
            ReflectionsFilterViewModel()
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
                watchUpdateService: WatchUpdateService.shared,
                triggerWatchNotificationUseCase: UseCasesContainer.shared.triggerWatchNotificationUseCase()
            )
        }
    }
    
    // MARK: - Settings
    
    @MainActor
    var settingsViewModel: Factory<SettingsViewModel> {
        self {
            SettingsViewModel(
                modelContext: ModelContainer.prod.mainContext,
                resetDatabaseUseCase: UseCasesContainer.shared.resetDatabaseUseCase()
            )
        }
    }
    
    // MARK: - Whats New
    
    @MainActor
    var whatsNewViewModel: Factory<WhatsNewViewModel> {
        self {
            WhatsNewViewModel()
        }
    }
}

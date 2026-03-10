//
//  UseCasesContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Factory
import SwiftData

// MARK: - UseCasesContainer

final class UseCasesContainer: SharedContainer, @unchecked Sendable {
    static let shared = UseCasesContainer()
    var manager = ContainerManager()
}

extension UseCasesContainer {

    // MARK: - Blog
    
    @MainActor
    var fetchBlogArticlesUseCase: Factory<DefaultFetchBlogArticlesUseCase> {
        self { DefaultFetchBlogArticlesUseCase(repository: DataContainer.shared.blogRepository()) }
    }
    
    // MARK: - Health

    @MainActor
    var checkHealthPermissionsUseCase: Factory<DefaultCheckHealthPermissionsUseCase> {
        self { DefaultCheckHealthPermissionsUseCase(healthKitService: HealthKitService.shared) }
    }
    
    @MainActor
    var fetchCurrentHeartRateUseCase: Factory<DefaultFetchCurrentHeartRateUseCase> {
        self { DefaultFetchCurrentHeartRateUseCase(healthKitService: HealthKitService.shared) }
    }
    
    @MainActor
    var fetchCurrentStepsUseCase: Factory<DefaultFetchCurrentStepsUseCase> {
        self { DefaultFetchCurrentStepsUseCase(healthKitService: HealthKitService.shared) }
    }

    @MainActor
    var fetchHeartRateUseCase: Factory<DefaultFetchHeartRateUseCase> {
        self { DefaultFetchHeartRateUseCase(healthKitService: HealthKitService.shared) }
    }
    
    @MainActor
    var fetchStepsUseCase: Factory<DefaultFetchStepsUseCase> {
        self { DefaultFetchStepsUseCase(healthKitService: HealthKitService.shared) }
    }
    
    @MainActor
    var requestHealthAuthorisationUseCase: Factory<DefaultRequestHealthAuthorisationUseCase> {
        self { DefaultRequestHealthAuthorisationUseCase(healthKitService: HealthKitService.shared) }
    }
    
    @MainActor
    var fetchStepDataLast24HoursUseCase: Factory<DefaultFetchStepsDataLast24HoursUseCase> {
        self { DefaultFetchStepsDataLast24HoursUseCase(healthKitService: HealthKitService.shared)}
    }
    
    @MainActor
    var fetchHeartRateDataLast24HoursUseCase: Factory<DefaultFetchHeartRateDataLast24HoursUseCase> {
        self { DefaultFetchHeartRateDataLast24HoursUseCase(healthKitService: HealthKitService.shared)}
    }

    // MARK: - Onboarding

    @MainActor
    var checkUserHasSeenOnboardingUseCase: Factory<DefaultCheckUserHasSeenOnboardingUseCase> {
        self { DefaultCheckUserHasSeenOnboardingUseCase() }
    }

    @MainActor
    var toggleUserHasSeenOnboardingUseCase: Factory<DefaultToggleUserHasSeenOnboardingUseCase> {
        self { DefaultToggleUserHasSeenOnboardingUseCase() }
    }

    // MARK: - Reflection

    @MainActor
    var addDefaultActivitiesUseCase: Factory<DefaultAddDefaultActivitiesUseCase> {
        self { DefaultAddDefaultActivitiesUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var fetchMissedReflectionsUseCase: Factory<DefaultFetchMissedReflectionsUseCase> {
        self {
            DefaultFetchMissedReflectionsUseCase(
                healthKitService: HealthKitService.shared
            )
        }
    }

    // MARK: - Settings
    
    @MainActor
    var fetchRoadmapUseCase: Factory<FetchRoadmapUseCase> {
        self { DefaultFetchRoadmapUseCase(roadmapRepository: DataContainer.shared.roadmapRepository()) }
    }
    
    // MARK: - System

    @MainActor
    var checkInternetConnectivityUseCase: Factory<DefaultCheckInternetConnectivityUseCase> {
        self { DefaultCheckInternetConnectivityUseCase(networkMonitor: NetworkMonitorService.shared) }
    }
    
    @MainActor
    var initializeNotificationsUseCase: Factory<DefaultInitializeNotificationsUseCase> {
        self { DefaultInitializeNotificationsUseCase(notificationService: NotificationService.shared) }
    }
    
    @MainActor
    var resetDatabaseUseCase: Factory<DefaultResetDatabaseUseCase> {
        self { DefaultResetDatabaseUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    // MARK: - Watch Communication

    @MainActor
    var triggerWatchNotificationUseCase: Factory<DefaultTriggerWatchNotificationUseCase> {
        self { DefaultTriggerWatchNotificationUseCase(notificationService: NotificationService.shared)}
    }
}

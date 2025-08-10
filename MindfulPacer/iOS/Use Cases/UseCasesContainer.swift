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
    var createReflectionUseCase: Factory<CreateReflectionUseCase> {
        self { DefaulCreateReflectionUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var deleteReflectionUseCase: Factory<DeleteReflectionUseCase> {
        self { DefaultDeleteReflectionUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var fetchActionedMissedReflectionsUseCase: Factory<FetchActionedMissedReflectionsUseCase> {
        self { DefaultFetchActionedMissedReflectionsUseCase() }
    }
    
    @MainActor
    var fetchDefaultActivitiesUseCase: Factory<DefaultFetchDefaultActivitiesUseCase> {
        self { DefaultFetchDefaultActivitiesUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var fetchReflectionsUseCase: Factory<DefaultFetchReflectionsUseCase> {
        self { DefaultFetchReflectionsUseCase(modelContext: ModelContainer.prod.mainContext) }
    }
    
    @MainActor
    var fetchReflectionsInPeriodUseCase: Factory<DefaultFetchReflectionsInPeriodUseCase> {
        self { DefaultFetchReflectionsInPeriodUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var filterReflectionsUseCase: Factory<DefaultFilterReflectionsUseCase> {
        self { DefaultFilterReflectionsUseCase() }
    }

    @MainActor
    var markMissedReflectionAsActionedUseCase: Factory<DefaultMarkMissedReflectionAsActionedUseCase> {
        self { DefaultMarkMissedReflectionAsActionedUseCase() }
    }
    
    @MainActor
    var saveReflectionUseCase: Factory<DefaultSaveReflectionUseCase> {
        self { DefaultSaveReflectionUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    // MARK: - Reminder

    @MainActor
    var checkMissedReflectionsUseCase: Factory<CheckMissedReflectionsUseCase> {
        self { DefaultCheckMissedReflectionsUseCase(healthKitService: HealthKitService.shared) }
    }
    
    @MainActor
    var createReminderUseCase: Factory<CreateReminderUseCase> {
        self { DefaultCreateReminderUseCase(modelContext: ModelContainer.prod.mainContext, watchUpdateService: WatchUpdateService.shared) }
    }

    @MainActor
    var deleteReminderUseCase: Factory<DeleteReminderUseCase> {
        self { DefaultDeleteReminderUseCase(modelContext: ModelContainer.prod.mainContext, watchUpdateService: WatchUpdateService.shared) }
    }

    @MainActor
    var fetchRemindersUseCase: Factory<DefaultFetchRemindersUseCase> {
        self { DefaultFetchRemindersUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var saveReminderUseCase: Factory<DefaultSaveReminderUseCase> {
        self { DefaultSaveReminderUseCase(modelContext: ModelContainer.prod.mainContext, watchUpdateService: WatchUpdateService.shared) }
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

    // MARK: - Watch Communication

    @MainActor
    var triggerWatchNotificationUseCase: Factory<DefaultTriggerWatchNotificationUseCase> {
        self { DefaultTriggerWatchNotificationUseCase(notificationService: NotificationService.shared)}
    }
}

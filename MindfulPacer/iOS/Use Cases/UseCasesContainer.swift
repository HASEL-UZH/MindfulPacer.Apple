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

    // MARK: - Onboarding

    @MainActor
    var checkUserHasSeenOnboardingUseCase: Factory<DefaultCheckUserHasSeenOnboardingUseCase> {
        self { DefaultCheckUserHasSeenOnboardingUseCase() }
    }

    @MainActor
    var toggleUserHasSeenOnboardingUseCase: Factory<DefaultToggleUserHasSeenOnboardingUseCase> {
        self { DefaultToggleUserHasSeenOnboardingUseCase() }
    }

    // MARK: - Review

    @MainActor
    var addDefaultActivitiesUseCase: Factory<DefaultAddDefaultActivitiesUseCase> {
        self { DefaultAddDefaultActivitiesUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var createReviewUseCase: Factory<CreateReviewUseCase> {
        self { DefaulCreateReviewUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var deleteReviewUseCase: Factory<DeleteReviewUseCase> {
        self { DefaultDeleteReviewUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var fetchActionedMissedReviewsUseCase: Factory<FetchActionedMissedReviewsUseCase> {
        self { DefaultFetchActionedMissedReviewsUseCase() }
    }
    
    @MainActor
    var fetchDefaultActivitiesUseCase: Factory<DefaultFetchDefaultActivitiesUseCase> {
        self { DefaultFetchDefaultActivitiesUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var fetchReviewsUseCase: Factory<DefaultFetchReviewsUseCase> {
        self { DefaultFetchReviewsUseCase(modelContext: ModelContainer.prod.mainContext) }
    }
    
    @MainActor
    var fetchReviewsInPeriodUseCase: Factory<DefaultFetchReviewsInPeriodUseCase> {
        self { DefaultFetchReviewsInPeriodUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var filterReviewsUseCase: Factory<DefaultFilterReviewsUseCase> {
        self { DefaultFilterReviewsUseCase() }
    }

    @MainActor
    var markMissedReviewAsActionedUseCase: Factory<DefaultMarkMissedReviewAsActionedUseCase> {
        self { DefaultMarkMissedReviewAsActionedUseCase() }
    }
    
    @MainActor
    var saveReviewUseCase: Factory<DefaultSaveReviewUseCase> {
        self { DefaultSaveReviewUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    // MARK: - Review Reminder

    @MainActor
    var checkMissedReviewsUseCase: Factory<CheckMissedReviewsUseCase> {
        self { DefaultCheckMissedReviewsUseCase(healthKitService: HealthKitService.shared) }
    }
    
    @MainActor
    var createReviewReminderUseCase: Factory<CreateReviewReminderUseCase> {
        self { DefaultCreateReviewReminderUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var deleteReviewReminderUseCase: Factory<DeleteReviewReminderUseCase> {
        self { DefaultDeleteReviewReminderUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var fetchReviewRemindersUseCase: Factory<DefaultFetchReviewRemindersUseCase> {
        self { DefaultFetchReviewRemindersUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    @MainActor
    var saveReviewReminderUseCase: Factory<DefaultSaveReviewReminderUseCase> {
        self { DefaultSaveReviewReminderUseCase(modelContext: ModelContainer.prod.mainContext) }
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
    var initializeConnectivityUseCase: Factory<DefaultInitializeConnectivityUseCase> {
        self { DefaultInitializeConnectivityUseCase(connectivityService: ConnectivityService.shared) }
    }

    @MainActor
    var triggerWatchNotificationUseCase: Factory<DefaultTriggerWatchNotificationUseCase> {
        self { DefaultTriggerWatchNotificationUseCase(notificationService: NotificationService.shared)}
    }
}

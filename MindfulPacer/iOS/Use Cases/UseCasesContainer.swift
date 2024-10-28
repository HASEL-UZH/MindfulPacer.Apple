//
//  UseCasesContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Factory
import SwiftData

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
    var addDefaultCategoriesUseCase: Factory<DefaultAddDefaultCategoriesUseCase> {
        self { DefaultAddDefaultCategoriesUseCase(modelContext: ModelContainer.prod.mainContext) }
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
    var fetchDefaultCategoriesUseCase: Factory<DefaultFetchDefaultCategoriesUseCase> {
        self { DefaultFetchDefaultCategoriesUseCase(modelContext: ModelContainer.prod.mainContext) }
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
    var saveReviewUseCase: Factory<DefaultSaveReviewUseCase> {
        self { DefaultSaveReviewUseCase(modelContext: ModelContainer.prod.mainContext) }
    }

    // MARK: - Review Reminder

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
    var fetchThemeUseCase: Factory<FetchThemeUseCase> {
        self { DefaultFetchThemeUseCase() }
    }
    
    @MainActor
    var listenToThemeChangesUseCase: Factory<ListenToThemeChangesUseCase> {
        self { DefaultListenToThemeChangesUseCase() }
    }
    
    @MainActor
    var setThemeUseCase: Factory<SetThemeUseCase> {
        self { DefaultSetThemeUseCase() }
    }
    
    // MARK: - System

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

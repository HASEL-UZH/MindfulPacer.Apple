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
    
    // MARK: - Home
    
    @MainActor
    var homeViewModel: Factory<HomeViewModel> {
        self {
            HomeViewModel(
                modelContext: ModelContainer.prod.mainContext,
                fetchCurrentStepsUseCase: UseCasesContainer.shared.fetchCurrentStepsUseCase(),
                fetchReviewsUseCase: UseCasesContainer.shared.fetchReviewsUseCase(),
                fetchReviewRemindersUseCase: UseCasesContainer.shared.fetchReviewRemindersUseCase(),
                filterReviewsUseCase: UseCasesContainer.shared.filterReviewsUseCase()
            )
        }
    }
    
    // MARK: - Onboarding
    
    @MainActor
    var onboardingViewModel: Factory<OnboardingViewModel> {
        self {
            OnboardingViewModel(
                initializeNotificationsUseCase: UseCasesContainer.shared.initializeNotificationsUseCase()
            )
        }
    }
    
    // MARK: - Root
    
    @MainActor
    var rootViewModel: Factory<RootViewModel> {
        self {
            RootViewModel(
                modelContext: ModelContainer.prod.mainContext,
                addDefaultCategoriesUseCase: UseCasesContainer.shared.addDefaultCategoriesUseCase(),
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
                fetchDefaultCategoriesUseCase: UseCasesContainer.shared.fetchDefaultCategoriesUseCase(),
                saveReviewUseCase: UseCasesContainer.shared.saveReviewUseCase()
            )
        }
    }
    
    @MainActor
    var reviewsFilterViewModel: Factory<ReviewsFilterViewModel> {
        self {
            ReviewsFilterViewModel(fetchDefaultCategoriesUseCase: UseCasesContainer.shared.fetchDefaultCategoriesUseCase())
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
}

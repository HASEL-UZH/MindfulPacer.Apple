//
//  ScenesContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 01.07.2024.
//

import Factory
import SwiftData

final class ScenesContainer: SharedContainer, @unchecked Sendable {
    static let shared = ScenesContainer()
    var manager = ContainerManager()
    
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
    // MARK: - Create Review
    
    @MainActor
    var createReviewViewModel: Factory<CreateReviewViewModel> {
        self {
            CreateReviewViewModel(
                modelContext: ModelContainer.prod.mainContext,
                createReviewUseCase: UseCasesContainer.shared.createReviewUseCase(),
                fetchDefaultCategoriesUseCase: UseCasesContainer.shared.fetchDefaultCategoriesUseCase()
            )
        }
    }
    
    // MARK: - Create Review Reminder
    
    @MainActor
    var createReviewReminderViewModel: Factory<CreateReviewReminderViewModel> {
        self {
            CreateReviewReminderViewModel(
                modelContext: ModelContainer.prod.mainContext,
                createReviewReminderUseCase: UseCasesContainer.shared.createReviewReminderUseCase(),
                triggerHapticFeedbackUseCase: UseCasesContainer.shared.triggerHapticFeedbackUseCase(),
                triggerWatchNotificationUseCase: UseCasesContainer.shared.triggerWatchNotificationUseCase()
            )
        }
    }
    
    // MARK: - Home
    
    @MainActor
    var homeViewModel: Factory<HomeViewModel> {
        self {
            HomeViewModel(
                fetchReviewsUseCase: UseCasesContainer.shared.fetchReviewsUseCase(),
                fetchReviewRemindersUseCase: UseCasesContainer.shared.fetchReviewRemindersUseCase(),
                modelContext: ModelContainer.prod.mainContext
            )
        }
    }
}

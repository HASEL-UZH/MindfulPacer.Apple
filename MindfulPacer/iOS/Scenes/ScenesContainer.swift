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
    
    // MARK: - Home
    
    @MainActor
    var homeViewModel: Factory<HomeViewModel> {
        self {
            HomeViewModel(
                deleteReviewUseCase: UseCasesContainer.shared.deleteReviewUseCase(),
                fetchReviewsUseCase: UseCasesContainer.shared.fetchReviewsUseCase(),
                fetchReviewRemindersUseCase: UseCasesContainer.shared.fetchReviewRemindersUseCase(),
                modelContext: ModelContainer.prod.mainContext
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
                modelContext: ModelContainer.prod.mainContext,
                createReviewUseCase: UseCasesContainer.shared.createReviewUseCase(),
                deleteReviewUseCase: UseCasesContainer.shared.deleteReviewUseCase(),
                fetchDefaultCategoriesUseCase: UseCasesContainer.shared.fetchDefaultCategoriesUseCase(),
                saveReviewUseCase: UseCasesContainer.shared.saveReviewUseCase()
            )
        }
    }

    // MARK: - Review Reminder
    
    @MainActor
    var createReviewReminderViewModel: Factory<CreateReviewReminderViewModel> {
        self {
            CreateReviewReminderViewModel(
                modelContext: ModelContainer.prod.mainContext,
                createReviewReminderUseCase: UseCasesContainer.shared.createReviewReminderUseCase(),
                triggerWatchNotificationUseCase: UseCasesContainer.shared.triggerWatchNotificationUseCase()
            )
        }
    }
}

//
//  ScenesContainer.swift
//  iOS
//
//  Created by Grigor Dochev on 01.07.2024.
//

import Factory
import SwiftUI
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
                addDefaultCategoriesUseCase: UseCasesContainer.shared.addDefaultCategoriesUseCase()
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
        self { CreateReviewReminderViewModel(modelContext: ModelContainer.prod.mainContext) }
    }
}

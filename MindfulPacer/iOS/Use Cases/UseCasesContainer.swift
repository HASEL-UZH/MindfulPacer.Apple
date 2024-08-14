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
    var fetchDefaultCategoriesUseCase: Factory<DefaultFetchDefaultCategoriesUseCase> {
        self { DefaultFetchDefaultCategoriesUseCase(modelContext: ModelContainer.prod.mainContext) }
    }
}

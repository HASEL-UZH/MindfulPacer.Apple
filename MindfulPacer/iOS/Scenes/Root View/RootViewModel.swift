//
//  RootViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Foundation
import SwiftData

@Observable
class RootViewModel {
    // MARK: - Dependencies

    private let modelContext: ModelContext
    private let addDefaultCategoriesUseCase: AddDefaultCategoriesUseCase
    private let initializeConnectivityUseCase: InitializeConnectivityUseCase
    
    // MARK: - Initialization
    
    init(
        modelContext: ModelContext,
        addDefaultCategoriesUseCase: AddDefaultCategoriesUseCase,
        initializeConnectivityUseCase: InitializeConnectivityUseCase
    ) {
        self.modelContext = modelContext
        self.addDefaultCategoriesUseCase = addDefaultCategoriesUseCase
        self.initializeConnectivityUseCase = initializeConnectivityUseCase
    }
    
    // MARK: View Events
    
    @MainActor
    func onViewFirstAppear() {
        Task {
            await addDefaultCategoriesUseCase.execute()
            initializeConnectivityUseCase.execute()
        }
    }
}

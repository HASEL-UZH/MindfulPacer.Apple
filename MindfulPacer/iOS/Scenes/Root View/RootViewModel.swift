//
//  RootViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Foundation
import SwiftData

// MARK: - RootViewModel

@Observable
class RootViewModel {
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    private let addDefaultCategoriesUseCase: AddDefaultCategoriesUseCase
    private let initializeConnectivityUseCase: InitializeConnectivityUseCase
    
    // MARK: - Published Properties
    
    var activeSheet: RootSheet? = nil
    
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
    
    // MARK: - View Events
    
    @MainActor
    func onViewFirstAppear() {
        Task {
            await addDefaultCategoriesUseCase.execute()
            initializeConnectivityUseCase.execute()
        }
        presentSheet(.onboardingView)
    }
    
    // MARK: - Presentation
    
    func presentSheet(_ sheet: RootSheet) {
        activeSheet = sheet
    }
}

//
//  CreateReviewReminderViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class CreateReviewReminderViewModel {
    // MARK: - Dependencies
    
    private let modelContext: ModelContext
    
    // MARK: - Published Properties (State)
    
    var navigationPath = NavigationPath()
    var alertItem: AlertItem? = nil

    // MARK: - Initialization
    
    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }
    
    // MARK: - View Lifecycle
    
    func onViewFirstAppear() {

    }
    
    // MARK: - User Actions
    
    // MARK: - Private Methods
    
    // MARK: - Error Handling
}

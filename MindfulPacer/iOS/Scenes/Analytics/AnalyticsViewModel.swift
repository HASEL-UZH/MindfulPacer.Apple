//
//  AnalyticsViewModel.swift
//  iOS
//
//  Created by Grigor Dochev on 12.09.2024.
//

import Foundation
import SwiftData

@Observable
class AnalyticsViewModel {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Published Properties (State)

    // MARK: - Initialization

    init(
        modelContext: ModelContext
    ) {
        self.modelContext = modelContext
    }

    // MARK: - View Lifecycle

    func onViewAppear() {}

    // MARK: - User Actions

    // MARK: - Private Methods

    // MARK: - Error Handling
}

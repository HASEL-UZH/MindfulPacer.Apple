//
//  ResetDatabaseUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 04.09.2025.
//

import Foundation
import SwiftData

@MainActor
protocol ResetDatabaseUseCase {
    func execute() async
}

// MARK: - Implementation

@MainActor
final class DefaultResetDatabaseUseCase: ResetDatabaseUseCase {
    private let context: ModelContext

    init(modelContext: ModelContext) {
        self.context = modelContext
    }

    func execute() async {
        let container = context.container

        container.deleteAllData()
    }
}

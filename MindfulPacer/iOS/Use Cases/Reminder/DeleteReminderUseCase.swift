//
//  DeleteReminderUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import Foundation
import SwiftData

protocol DeleteReminderUseCase {
    func execute(reminder: Reminder)
}

// MARK: - Use Case Implementation

class DefaultDeleteReminderUseCase: DeleteReminderUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute(reminder: Reminder) {
        modelContext.delete(reminder)
        try? modelContext.save()
    }
}

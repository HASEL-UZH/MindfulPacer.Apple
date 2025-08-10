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
    private let watchUpdateService: WatchUpdateService

    init(modelContext: ModelContext, watchUpdateService: WatchUpdateService) {
        self.modelContext = modelContext
        self.watchUpdateService = watchUpdateService
    }

    func execute(reminder: Reminder) {
        modelContext.delete(reminder)
        watchUpdateService.notifyWatchOfReminderChange()
        try? modelContext.save()
    }
}

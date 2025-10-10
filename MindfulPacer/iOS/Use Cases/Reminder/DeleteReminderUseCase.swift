//
//  DeleteReminderUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import Foundation
import SwiftData

protocol DeleteReminderUseCase {
    @MainActor
    func execute(reminder: Reminder)
}

// MARK: - Use Case Implementation

@MainActor
class DefaultDeleteReminderUseCase: DeleteReminderUseCase {
    private let modelContext: ModelContext
    private let watchUpdateService: WatchUpdateService

    init(modelContext: ModelContext, watchUpdateService: WatchUpdateService) {
        self.modelContext = modelContext
        self.watchUpdateService = watchUpdateService
    }

    func execute(reminder: Reminder) {
        modelContext.delete(reminder)
        BackgroundRemindersStore.shared.remove(id: reminder.id)
        watchUpdateService.notifyWatchOfReminderChange()
        try? modelContext.save()
    }
}

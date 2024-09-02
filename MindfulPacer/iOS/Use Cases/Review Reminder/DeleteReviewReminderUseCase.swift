//
//  DeleteReviewReminderUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 02.09.2024.
//

import Foundation
import SwiftData

protocol DeleteReviewReminderUseCase {
    func execute(reviewReminder: ReviewReminder)
}

// MARK: - Use Case Implementation

class DefaultDeleteReviewReminderUseCase: DeleteReviewReminderUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(reviewReminder: ReviewReminder) {
        modelContext.delete(reviewReminder)
    }
}

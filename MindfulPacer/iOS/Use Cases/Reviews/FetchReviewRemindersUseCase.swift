//
//  FetchReviewRemindersUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Foundation
import SwiftData

protocol FetchReviewRemindersUseCase {
    func execute() -> [ReviewReminder]?
}

// MARK: - Use Case Implementation

class DefaultFetchReviewRemindersUseCase: FetchReviewRemindersUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute() -> [ReviewReminder]? {
        do {
            let descriptor = FetchDescriptor<ReviewReminder>()
            let reviewReminders = try modelContext.fetch(descriptor)
            return reviewReminders
        } catch {
            print("DEBUG: Could not fetch review reminders")
            return nil
        }
    }
}

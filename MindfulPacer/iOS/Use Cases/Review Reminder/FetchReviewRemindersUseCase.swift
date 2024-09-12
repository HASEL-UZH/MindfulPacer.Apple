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
            let descriptor = FetchDescriptor<ReviewReminder>(sortBy: [SortDescriptor(\.threshold, order: .reverse)])
            let reviewReminders = try modelContext.fetch(descriptor)

            // Group by measurementType
            let groupedReminders = Dictionary(grouping: reviewReminders) { $0.measurementType }

            // Define custom sort order for measurementType, with heartRate first
            let sortedKeys = groupedReminders.keys.sorted { lhs, rhs in
                if lhs == .heartRate {
                    return true
                } else if rhs == .heartRate {
                    return false
                } else {
                    return lhs.rawValue < rhs.rawValue
                }
            }

            // Flatten the grouped and sorted dictionary
            let groupedAndSortedReminders = sortedKeys.flatMap { key in
                groupedReminders[key]?.sorted(by: { $0.threshold > $1.threshold }) ?? []
            }

            return groupedAndSortedReminders
        } catch {
            print("DEBUG: Could not fetch review reminders: \(error.localizedDescription)")
            return nil
        }
    }
}

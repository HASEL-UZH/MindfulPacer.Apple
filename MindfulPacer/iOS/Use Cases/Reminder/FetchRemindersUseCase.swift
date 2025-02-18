//
//  FetchRemindersUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Foundation
import SwiftData

protocol FetchRemindersUseCase {
    func execute() -> [Reminder]?
}

// MARK: - Use Case Implementation

class DefaultFetchRemindersUseCase: FetchRemindersUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute() -> [Reminder]? {
        do {
            let descriptor = FetchDescriptor<Reminder>(sortBy: [SortDescriptor(\.threshold, order: .reverse)])
            let reminders = try modelContext.fetch(descriptor)

            // Group by measurementType
            let groupedReminders = Dictionary(grouping: reminders) { $0.measurementType }

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
            print("DEBUG: Could not fetch Reminders: \(error.localizedDescription)")
            return nil
        }
    }
}

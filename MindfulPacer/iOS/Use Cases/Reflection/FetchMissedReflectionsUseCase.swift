//
//  FetchMissedReflectionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 22.08.2025.
//

import Foundation
import SwiftData

protocol FetchMissedReflectionsUseCase {
    func execute() -> [Reflection]?
}

// MARK: - Use Case Implementation

class DefaultFetchMissedReflectionsUseCase: FetchMissedReflectionsUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute() -> [Reflection]? {
        do {
            let descriptor = FetchDescriptor<Reflection>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let reflections = try modelContext.fetch(descriptor)
            return reflections.filter { $0.isMissedReflection }
        } catch {
            print("DEBUG: Could not fetch missed reflections")
            return nil
        }
    }
}

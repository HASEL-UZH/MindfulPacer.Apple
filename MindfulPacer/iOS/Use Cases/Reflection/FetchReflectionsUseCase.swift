//
//  FetchReflectionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Foundation
import SwiftData

protocol FetchReflectionsUseCase {
    func execute() -> [Reflection]?
}

// MARK: - Use Case Implementation

class DefaultFetchReflectionsUseCase: FetchReflectionsUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute() -> [Reflection]? {
        do {
            let descriptor = FetchDescriptor<Reflection>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let reflections = try modelContext.fetch(descriptor)
            return reflections
        } catch {
            print("DEBUG: Could not fetch reflections")
            return nil
        }
    }
}

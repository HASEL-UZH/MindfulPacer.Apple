//
//  FetchReflectionsInPeriodUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 24.09.2024.
//

import Foundation
import SwiftData

// MARK: - FetchReflectionsInPeriodUseCase

protocol FetchReflectionsInPeriodUseCase {
    func execute(period: Period) -> [Reflection]
}

// MARK: - Use Case Implementation

class DefaultFetchReflectionsInPeriodUseCase: FetchReflectionsInPeriodUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(period: Period) -> [Reflection] {
        do {
            let descriptor = FetchDescriptor<Reflection>(sortBy: [SortDescriptor(\Reflection.date, order: .reverse)])
                        
            let reflections = try modelContext.fetch(descriptor)
            let filteredReflections = reflections.filter { reflection in
                (reflection.date >= period.startDate && reflection.date <= Date())
            }
            
            return filteredReflections
        } catch {
            print("DEBUG: Could not fetch reflections: \(error)")
            return []
        }
    }
}

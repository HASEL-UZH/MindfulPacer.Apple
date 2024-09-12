//
//  FetchReviewsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 26.08.2024.
//

import Foundation
import SwiftData

protocol FetchReviewsUseCase {
    func execute() -> [Review]?
}

// MARK: - Use Case Implementation

class DefaultFetchReviewsUseCase: FetchReviewsUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute() -> [Review]? {
        do {
            let descriptor = FetchDescriptor<Review>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            let reviews = try modelContext.fetch(descriptor)
            return reviews
        } catch {
            print("DEBUG: Could not fetch reviews")
            return nil
        }
    }
}

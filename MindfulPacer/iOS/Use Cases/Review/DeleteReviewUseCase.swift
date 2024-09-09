//
//  DeleteReviewUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import Foundation
import SwiftData

// FIXME: Not working, deletion does not persist
protocol DeleteReviewUseCase {
    func execute(review: Review)
}

// MARK: - Use Case Implementation

class DefaultDeleteReviewUseCase: DeleteReviewUseCase {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func execute(review: Review) {
        modelContext.delete(review)
        try! modelContext.save()
    }
}

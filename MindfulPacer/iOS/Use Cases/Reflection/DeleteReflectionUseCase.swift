//
//  DeleteReflectionUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 31.08.2024.
//

import Foundation
import SwiftData

protocol DeleteReflectionUseCase {
    func execute(reflection: Reflection)
}

// MARK: - Use Case Implementation

class DefaultDeleteReflectionUseCase: DeleteReflectionUseCase {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func execute(reflection: Reflection) {
        modelContext.delete(reflection)
        try? modelContext.save()
    }
}

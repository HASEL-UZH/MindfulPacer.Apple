//
//  MarkMissedReflectionAsActionedUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 12.01.2025.
//

import Foundation

// MARK: - MarkMissedReflectionAsActionedUseCase

protocol MarkMissedReflectionAsActionedUseCase {
    func execute(missedReflection: MissedReflection)
}

// MARK: - Use Case Implementation

class DefaultMarkMissedReflectionAsActionedUseCase: MarkMissedReflectionAsActionedUseCase {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func execute(missedReflection: MissedReflection) {
        var actionedReflections = userDefaults.stringArray(forKey: MissedReflection.actionedKey) ?? []
        if !actionedReflections.contains(missedReflection.id) {
            actionedReflections.append(missedReflection.id)
            userDefaults.set(actionedReflections, forKey: MissedReflection.actionedKey)
        }
    }
}

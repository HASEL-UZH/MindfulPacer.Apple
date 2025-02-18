//
//  FetchActionedMissedReflectionsUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 01.02.2025.
//

import Foundation

// MARK: - FetchActionedMissedReflectionsUseCase

protocol FetchActionedMissedReflectionsUseCase {
    func execute() -> [String]
}

// MARK: - Use Case Implementation

class DefaultFetchActionedMissedReflectionsUseCase: FetchActionedMissedReflectionsUseCase {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func execute() -> [String] {
        userDefaults.stringArray(forKey: MissedReflection.actionedKey) ?? []
    }
}

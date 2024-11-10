//
//  FetchModeOfUseUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 10.11.2024.
//

import Foundation

protocol FetchModeOfUseUseCase {
    func execute() -> ModeOfUse
}

// MARK: - Use Case Implementation

class DefaultFetchModeOfUseUseCase: FetchModeOfUseUseCase {
    init() {}
    
    func execute() -> ModeOfUse {
        let storedModeOfUse = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.modeOfUse)
        return ModeOfUse(rawValue: storedModeOfUse ?? ModeOfUse.essentials.rawValue) ?? .essentials
    }
}

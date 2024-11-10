//
//  SetThemeUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 15.10.2024.
//

import Foundation

protocol SetThemeUseCase {
    func execute(theme: Theme)
}

// MARK: - Use Case Implementation

class DefaultSetThemeUseCase: SetThemeUseCase {
    init() {}

    func execute(theme: Theme) {
        UserDefaults.standard.setValue(theme.rawValue, forKey: Constants.UserDefaultsKeys.theme)
    }
}

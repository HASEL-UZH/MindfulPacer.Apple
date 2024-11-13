//
//  FetchThemeUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 15.10.2024.
//

import Foundation

protocol FetchThemeUseCase {
    func execute() -> Theme
}

// MARK: - Use Case Implementation

class DefaultFetchThemeUseCase: FetchThemeUseCase {
    init() {}
    
    func execute() -> Theme {
        let storedTheme = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.theme)
        return Theme(rawValue: storedTheme ?? Theme.system.rawValue) ?? .system
    }
}

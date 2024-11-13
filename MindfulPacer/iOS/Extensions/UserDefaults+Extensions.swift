//
//  UserDefaults+Extensions.swift
//  iOS
//
//  Created by Grigor Dochev on 10.11.2024.
//

import Foundation

// MARK: - Extension for UserDefaults Publisher

extension UserDefaults {
    @objc dynamic var selectedTheme: String? {
        return string(forKey: Constants.UserDefaultsKeys.theme)
    }
}

extension UserDefaults {
    @objc dynamic var modeOfUse: String? {
        return string(forKey: Constants.UserDefaultsKeys.modeOfUse)
    }
}

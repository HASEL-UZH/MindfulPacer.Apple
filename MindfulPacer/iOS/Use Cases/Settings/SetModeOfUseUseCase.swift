//
//  SetModeOfUseUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 10.11.2024.
//

import Foundation

protocol SetModeOfUseUseCase {
    func execute(modeOfUse: ModeOfUse)
}

// MARK: - Use Case Implementation

class DefaultSetModeOfUseUseCase: SetModeOfUseUseCase {
    init() {}

    func execute(modeOfUse: ModeOfUse) {
        UserDefaults.standard.setValue(modeOfUse.rawValue, forKey: Constants.UserDefaultsKeys.modeOfUse)
    }
}

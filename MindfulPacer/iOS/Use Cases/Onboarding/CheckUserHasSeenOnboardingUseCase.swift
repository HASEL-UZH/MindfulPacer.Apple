//
//  CheckUserHasSeenOnboardingUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 11.09.2024.
//

import Foundation
import SwiftUI

enum OnboardingStatus {
    static let key = "userHasSeenOnboarding"
    static func isCompleted(defaults: UserDefaults = DefaultsStore.shared) -> Bool {
        defaults.bool(forKey: key)
    }
}

protocol CheckUserHasSeenOnboardingUseCase {
    func execute() -> Bool
}
 
// MARK: - Use Case Implementation

class DefaultCheckUserHasSeenOnboardingUseCase: CheckUserHasSeenOnboardingUseCase {
    @AppStorage("userHasSeenOnboarding") var userHasSeenOnboarding: Bool = false

    func execute() -> Bool {
        return userHasSeenOnboarding
    }
}

//
//  CheckUserHasSeenOnboardingUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 11.09.2024.
//

import Foundation
import SwiftUI

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

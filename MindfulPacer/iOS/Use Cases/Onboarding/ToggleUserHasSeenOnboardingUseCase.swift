//
//  ToggleUserHasSeenOnboardingUseCase.swift
//  iOS
//
//  Created by Grigor Dochev on 11.09.2024.
//

import Foundation
import SwiftUI

protocol ToggleUserHasSeenOnboardingUseCase {
    func execute()
}

// MARK: - Use Case Implementation

class DefaultToggleUserHasSeenOnboardingUseCase: ToggleUserHasSeenOnboardingUseCase {
    @AppStorage("userHasSeenOnboarding") var userHasSeenOnboarding: Bool = false
    
    func execute() {
        userHasSeenOnboarding = true
    }
}

//
//  RootViewState.swift
//  iOS
//
//  Created by Grigor Dochev on 05.07.2024.
//

import Foundation

struct RootViewState {
    var hasSeenOnboarding: Bool
}

// MARK: - Initial View State

extension RootViewState {
    static let initial = RootViewState(
        hasSeenOnboarding: false
    )
}

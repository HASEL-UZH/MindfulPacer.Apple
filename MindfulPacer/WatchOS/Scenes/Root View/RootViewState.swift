//
//  RootViewState.swift
//  WatchOS
//
//  Created by Grigor Dochev on 16.07.2024.
//

import Foundation

struct RootViewState {
    var hasSeenOnboarding: Bool
    var currentHeartRate: Double
}

// MARK: - Initial View State

extension RootViewState {
    static let initial = RootViewState(
        hasSeenOnboarding: false,
        currentHeartRate: 0.0
    )
}

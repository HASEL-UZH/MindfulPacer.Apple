//
//  View+Modifiers.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 16.07.2024.
//

import SwiftUI

// MARK: - On View First Appear

extension View {
    func onViewFirstAppear(perform action: @escaping () -> Void) -> some View {
        modifier(OnViewFirstAppearModifier(action: action))
    }
}

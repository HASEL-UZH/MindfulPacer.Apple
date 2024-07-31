//
//  OnViewFirstAppearModifier.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 16.07.2024.
//

import SwiftUI

struct OnViewFirstAppearModifier: ViewModifier {
    @State private var isFirstAppear = true
    let action: () -> Void

    func body(content: Content) -> some View {
        content.onAppear {
            if isFirstAppear {
                action()
                isFirstAppear = false
            }
        }
    }
}

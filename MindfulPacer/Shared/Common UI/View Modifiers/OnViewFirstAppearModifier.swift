//
//  OnViewFirstAppearModifier.swift
//  MindfulPacer
//
//  Created by Grigor Dochev on 16.07.2024.
//

import SwiftUI

/// A view modifier that performs an action when a view appears for the first time.
///
/// The `OnViewFirstAppearModifier` ensures that the provided action is executed only the first time the view appears, preventing repeated execution on subsequent appearances.
///
/// - Important: This modifier should be used when you need to execute code only on the initial appearance of a view, such as loading data or triggering an animation.
///
/// Usage example:
/// ```swift
/// Text("Hello, World!")
///     .modifier(OnViewFirstAppearModifier {
///         print("View appeared for the first time")
///     })
/// ```
///
/// - Parameters:
///   - action: A closure to execute when the view appears for the first time.
struct OnViewFirstAppearModifier: ViewModifier {
    @State private var isFirstAppear = true
    let action: () -> Void

    /// Applies the modifier to the content and executes the action on the first appearance.
    ///
    /// - Parameter content: The content view that the modifier is applied to.
    /// - Returns: A modified view that triggers the action on the first appearance.
    func body(content: Content) -> some View {
        content.onAppear {
            if isFirstAppear {
                action()
                isFirstAppear = false
            }
        }
    }
}

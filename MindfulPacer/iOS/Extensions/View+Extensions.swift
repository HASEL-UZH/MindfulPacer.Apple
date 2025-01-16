//
//  View+Extensions.swift
//  iOS
//
//  Created by Grigor Dochev on 15.08.2024.
//

import SwiftUI

extension View {
    
    // MARK: - Keyboard
    
    #if canImport(UIKit)
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    #endif
    
    // MARK: - Toast
    
    func toastStyle(_ style: ToastStyle) -> some View {
        self.modifier(ToastStyleModifier(style: style))
    }
    
    public func toast<Item: Identifiable, Content: View>(
        item: Binding<Item?>,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        self.modifier(ToastItemModifier(item: item, content: content))
    }
}

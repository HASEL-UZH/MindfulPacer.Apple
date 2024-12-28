//
//  Toast.swift
//  iOS
//
//  Created by Grigor Dochev on 20.12.2024.
//

import SwiftUI
import UIKit

// MARK: - ToastItemModifier

struct ToastItemModifier<Item: Identifiable, ToastContent: View>: ViewModifier {
    @Binding var item: Item?
    let content: (Item) -> ToastContent
    
    @State private var dragOffset = CGSize.zero
    @State private var workItem: DispatchWorkItem?
    
    private let autoDismissDelay: TimeInterval = 3.0
    private let dismissDragThreshold: CGFloat = 50.0
    
    func body(content view: Content) -> some View {
        ZStack {
            view
            if let theItem = item {
                VStack {
                    Spacer()
                    self.content(theItem)
                }
                .padding(.bottom)
                .offset(y: dragOffset.height)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .gesture(dragGesture)
                .onAppear {
                    scheduleAutoDismiss()
                }
            }
        }
        .animation(.spring(), value: item?.id)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if value.translation.height > 0 {
                    dragOffset = value.translation
                }
            }
            .onEnded { value in
                if value.translation.height > dismissDragThreshold {
                    dismissToast()
                } else {
                    withAnimation {
                        dragOffset = .zero
                    }
                }
            }
    }
    
    private func scheduleAutoDismiss() {
        workItem?.cancel()
        let newItem = DispatchWorkItem {
            dismissToast()
        }
        workItem = newItem
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay, execute: newItem)
    }
    
    private func dismissToast() {
        withAnimation {
            item = nil
        }
        resetState()
    }
    
    private func resetState() {
        dragOffset = .zero
        workItem?.cancel()
        workItem = nil
    }
}

// MARK: - Toast Style

enum ToastStyle {
    case success
    case failure
    case info
    case custom(icon: String, color: Color, feedback: UINotificationFeedbackGenerator.FeedbackType?)
}

struct ToastStyleConfiguration {
    let icon: String?
    let color: Color
    let feedback: UINotificationFeedbackGenerator.FeedbackType?
}

// MARK: - ToastStyle + Extensions

extension ToastStyle {
    var configuration: ToastStyleConfiguration {
        switch self {
        case .success:
            return .init(icon: "checkmark.circle", color: .green, feedback: .success)
        case .failure:
            return .init(icon: "xmark.circle", color: .red, feedback: .error)
        case .info:
            return .init(icon: "info.circle", color: .blue, feedback: .success)
        case let .custom(icon, color, feedback):
            return .init(icon: icon, color: color, feedback: feedback)
        }
    }
}

// MARK: - Environment Keys for Toast Style

private struct ToastIconNameKey: EnvironmentKey {
    static let defaultValue: String? = nil
}

private struct ToastColorKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

private struct ToastFeedbackKey: EnvironmentKey {
    static let defaultValue: UINotificationFeedbackGenerator.FeedbackType? = nil
}

extension EnvironmentValues {
    var toastIconName: String? {
        get { self[ToastIconNameKey.self] }
        set { self[ToastIconNameKey.self] = newValue }
    }
    
    var toastColor: Color {
        get { self[ToastColorKey.self] }
        set { self[ToastColorKey.self] = newValue }
    }
    
    var toastFeedback: UINotificationFeedbackGenerator.FeedbackType? {
        get { self[ToastFeedbackKey.self] }
        set { self[ToastFeedbackKey.self] = newValue }
    }
}

// MARK: - ToastStyleModifier

struct ToastStyleModifier: ViewModifier {
    let style: ToastStyle
    
    func body(content: Content) -> some View {
        let config = style.configuration
        content
            .environment(\.toastIconName, config.icon)
            .environment(\.toastColor, config.color)
            .environment(\.toastFeedback, config.feedback)
            .onAppear {
                if let feedbackType = config.feedback {
                    let generator = UINotificationFeedbackGenerator()
                    generator.prepare()
                    generator.notificationOccurred(feedbackType)
                }
            }
    }
}

// MARK: - Toast

struct Toast: View {
    let title: String
    let message: String
    
    @Environment(\.toastIconName) private var iconName
    @Environment(\.toastColor) private var color
    
    var body: some View {
        HStack(spacing: 8) {
            if let iconName = iconName {
                Icon(name: iconName, color: .white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.footnote)
            }
            .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .foregroundColor(color)
                .shadow(color: Color.black.opacity(0.1), radius: 0.1)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        Toast(
            title: "Success",
            message: "Your data was saved."
        )
        .toastStyle(.success)
        
        Toast(
            title: "Failure",
            message: "Couldn't save your data."
        )
        .toastStyle(.failure)
        
        Toast(
            title: "Info",
            message: "Saved data can be seen in Home view."
        )
        .toastStyle(.info)
        
        Toast(
            title: "Custom",
            message: "Custom message"
        )
        .toastStyle(.custom(icon: "bubble.fill", color: .gray, feedback: .success))
    }
}

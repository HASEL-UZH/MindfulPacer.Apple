//
//  Toast.swift
//  iOS
//
//  Created by Grigor Dochev on 20.12.2024.
//

import SwiftUI

// MARK: - ToastItemModifier

struct ToastItemModifier<Item: Identifiable, ToastContent: View>: ViewModifier {
    @Binding var item: Item?
    let content: (Item) -> ToastContent
    
    @State private var dragOffset = CGSize.zero
    @State private var workItem: DispatchWorkItem?
    
    private let autoDismissDelay: TimeInterval = 2.0
    private let dismissDragThreshold: CGFloat = 50.0
    
    func body(content view: Content) -> some View {
        ZStack {
            view
            if let item = item {
                VStack {
                    Spacer()
                    self.content(item)
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
        .onChange(of: item?.id) { _, newValue in
            if newValue == nil {
                resetState()
            }
        }
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
        workItem?.cancel()
        workItem = nil
    }
    
    private func resetState() {
        dragOffset = .zero
        workItem?.cancel()
        workItem = nil
    }
}

// MARK: - Toast

struct Toast: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Icon(name: icon, color: .white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Capsule()
                .foregroundColor(color)
                .shadow(color: Color.black.opacity(0.1), radius: 0.1)
        }
        .foregroundColor(.white)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    Toast(title: "Success!", message: "This is a success message.", icon: "checkmark", color: .green)
}

//enum HomeToast: Identifiable {
//    case success
//    case failure
//
//    var id: Int {
//        hashValue
//    }
//}
//
//struct TestHomeView: View {
//    @State private var toastItem: HomeToast?
//
//    var body: some View {
//        NavigationStack {
//            VStack(spacing: 20) {
//                Button("Show Toast (Item)") {
//                    toastItem = .failure
//                }
//            }
//            .navigationTitle("Home")
//            .toast(item: $toastItem) { toast in
//                toastContent(for: toast)
//            }
//        }
//    }
//
//    private func toastContent(for toast: HomeToast) -> Toast {
//        switch toast {
//        case .success:
//            Toast(
//                title: "Success",
//                message: "You created a review",
//                icon: "checkmark.circle.fill",
//                color: .green
//            )
//        case .failure:
//            Toast(
//                title: "Failure",
//                message: "Couldn't save review",
//                icon: "xmark.circle.fill",
//                color: .red
//            )
//        }
//    }
//}
